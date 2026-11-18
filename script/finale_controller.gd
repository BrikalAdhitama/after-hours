extends Node
## A single pursuit begins in Studio and persists through every room transition.
const Ardi = preload("res://script/ardi_chase.gd")
var ardi: CharacterBody2D
var player: CharacterBody2D
var ui: Node
var _initialized := false
var _preparing := false
var _arrival_delay := 0.0

func _ready() -> void:
	player = get_parent().get_node("Raka")
	ui = get_tree().get_first_node_in_group("gameplay_ui")
	add_to_group("finale")
	ui.connect("dialogue_finished", _after_dialogue)
	if GameState.finale_phase in ["briefing", "chase"]: call_deferred("_prepare")

func _prepare() -> void:
	if _preparing or _initialized: return
	_preparing = true
	await get_tree().physics_frame
	ardi = Ardi.new()
	ardi.name = "Ardi"
	get_parent().add_child(ardi)
	ardi.build_navigation(get_parent(), player)
	var feet: Vector2 = player.get_node("CollisionShape2D").global_position
	if not GameState.pursuit_transfer.is_empty():
		var transfer := GameState.pursuit_transfer.duplicate()
		GameState.pursuit_transfer.clear()
		_initialized = ardi.spawn_at_entry(feet, str(transfer.get("state", "SEARCH")))
		_arrival_delay = float(transfer.get("delay", 2.5))
	else:
		_initialized = ardi.select_spawn(feet, feet)
	ardi.visible = _initialized and _arrival_delay <= 0
	if not _initialized:
		push_error("No reachable Ardi spawn in " + GameState.current_area)
	_preparing = false
	if ui.get("_mode") == "play": _after_dialogue()

func _after_dialogue() -> void:
	if GameState.finale_phase == "briefing" and _initialized:
		GameState.set_finale_phase("chase")

func _physics_process(delta: float) -> void:
	if SceneTransition._transitioning or ui.get("_mode") != "play": return
	if GameState.can_start_chase():
		GameState.save_chase_checkpoint(player.position)
		GameState.set_finale_phase("briefing")
		ui.show_dialogue(preload("res://script/story_data.gd").event_lines("studio_chase"))
		_prepare()
		return
	if not _initialized or GameState.finale_phase != "chase": return
	if _arrival_delay > 0:
		_arrival_delay -= delta
		if _arrival_delay <= 0: ardi.show()
		_set_status("Langkah Ardi mendekat dari pintu. Bergerak menjauh dari pintu masuk.")
		return
	var feet: Vector2 = player.get_node("CollisionShape2D").global_position
	var hidden := bool(player.get("is_hidden"))
	ardi.pursue(delta, feet, hidden)
	match ardi.state:
		"CHASE": _set_status("Ardi melihatmu! Putuskan pandangan di balik furnitur atau masuk lemari [E].")
		"SEARCH": _set_status("Ardi mencari posisi terakhir yang dilihatnya. Ia masih bergerak.")
		_: _set_status("Ardi kehilangan jejak dan berpatroli. Capai pintu keluar utama LABKOM tanpa terlihat lagi.")
	if not hidden and ardi.can_catch(feet): caught()

func _set_status(text: String) -> void:
	if GameState.pursuit_status != text:
		GameState.pursuit_status = text
		GameState.progress_changed.emit()

func prepare_transfer(door_position: Vector2) -> void:
	if GameState.finale_phase != "chase" or not _initialized: return
	# Travel time depends on the old room; no knowledge of Raka's new position.
	var distance := ardi.global_position.distance_to(door_position)
	GameState.pursuit_transfer = {
		"delay": maxf(_arrival_delay, clampf(distance / ardi.chase_speed, 2.5, 7.0)),
		"state": "PATROL" if ardi.state == "PATROL" else "SEARCH",
	}

func try_escape() -> bool:
	if GameState.finale_phase != "chase" or GameState.current_area != "labkom" or not _initialized or _arrival_delay > 0: return false
	var feet: Vector2 = player.get_node("CollisionShape2D").global_position
	if ardi.state != "PATROL" or ardi.can_see(feet):
		ui.show_message("Pintu masih berulang", "Ardi belum kehilangan jejak. Berlindung di balik furnitur atau gunakan lemari, lalu coba keluar tanpa terlihat.")
		return false
	ardi.velocity = Vector2.ZERO
	GameState.set_finale_phase("escape")
	return true

func caught() -> void:
	if GameState.finale_phase != "chase": return
	ardi.velocity = Vector2.ZERO
	GameState.set_finale_phase("caught")
	ui.show_jumpscare()
