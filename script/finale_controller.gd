extends Node
## First playable chase: reach the existing wardrobe, hide 5 seconds, then choose at the exit.
const Ardi = preload("res://script/ardi_chase.gd")
const HIDE_SECONDS := 5.0
var ardi: CharacterBody2D
var player: CharacterBody2D
var ui: Node
var _hidden_time := 0.0
var _initialized := false

func _ready() -> void:
	player = get_parent().get_node("Raka")
	ui = get_tree().get_first_node_in_group("gameplay_ui")
	add_to_group("finale")
	if GameState.finale_phase == "investigation":
		GameState.set_finale_phase("briefing")
	if GameState.checkpoint.is_empty():
		GameState.save_chase_checkpoint(player.position)
	ui.connect("dialogue_finished", _after_dialogue)
	call_deferred("_prepare")

func _prepare() -> void:
	await get_tree().physics_frame
	if GameState.finale_phase not in ["briefing", "chase"]:
		return
	ardi = Ardi.new()
	ardi.name = "Ardi"
	get_parent().add_child(ardi)
	ardi.build_navigation(get_parent(),player)
	var target := player.get_node("CollisionShape2D") as CollisionShape2D
	var wardrobe := get_parent().get_node("Object/LemariInteractable") as Node2D
	_initialized = ardi.select_spawn(target.global_position,wardrobe.global_position)
	ardi.visible = _initialized
	if not _initialized:
		push_error("No reachable Ardi spawn in LABKOM.")
	if ui.get("_mode") == "play":
		_after_dialogue()

func _after_dialogue() -> void:
	if GameState.finale_phase == "briefing" and _initialized:
		GameState.set_finale_phase("chase")

func _physics_process(delta: float) -> void:
	if not _initialized or GameState.finale_phase != "chase":
		return
	if SceneTransition._transitioning or ui.get("_mode") != "play":
		return
	var feet: Vector2 = player.get_node("CollisionShape2D").global_position
	var hidden := bool(player.get("is_hidden"))
	ardi.pursue(delta,feet,hidden)
	if hidden:
		_hidden_time += delta
		var remaining := maxi(0,ceili(HIDE_SECONDS - _hidden_time))
		if GameState.hidden_seconds != remaining:
			GameState.hidden_seconds = remaining
			GameState.progress_changed.emit()
		if _hidden_time >= HIDE_SECONDS:
			complete_chase()
	else:
		_hidden_time = 0
		if ardi.can_catch(feet):
			caught()

func complete_chase() -> void:
	if GameState.finale_phase != "chase": return
	ardi.hide()
	ardi.velocity = Vector2.ZERO
	GameState.set_finale_phase("escape")
	ui.call("show_message","Suasana kembali tenang","Tekan E untuk keluar dari lemari, lalu menuju pintu keluar utama.")

func caught() -> void:
	if GameState.finale_phase != "chase": return
	ardi.velocity = Vector2.ZERO
	GameState.set_finale_phase("caught")
	ui.call("show_finale","caught")
