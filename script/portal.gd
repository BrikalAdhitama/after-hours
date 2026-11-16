extends Node2D
## Reusable E interaction for area doors and the LABKOM loop exit.

@export var target_name: String = "Pintu"
@export var destination_scene: String = ""
@export var destination_spawn: String = ""
@export var required_clues: PackedStringArray = []
@export var is_loop_exit: bool = false

func _ready() -> void:
	add_to_group("interactables")

func get_prompt() -> String:
	return "[E] Gunakan " + target_name

func interact(_player: Node) -> void:
	if SceneTransition._transitioning:
		return
	var ui: Node = get_tree().get_first_node_in_group("gameplay_ui")
	if ui != null and (bool(ui.get("inventory_open")) or bool(ui.get("pause_open"))):
		return
	if GameState.finale_phase in ["briefing", "chase"]:
		if ui != null:
			ui.call("show_message", "Ardi mendekat", "Cari lemari dan tekan E untuk bersembunyi.")
		return
	if GameState.finale_phase == "escape":
		if is_loop_exit:
			GameState.set_finale_phase("choice")
			if ui != null: ui.call("show_finale", "choice")
		elif ui != null:
			ui.call("show_message", "Tujuan terakhir", "Gunakan pintu keluar utama LABKOM, bukan pintu antar-area.")
		return
	if is_loop_exit:
		if not GameState.has_clue("C1"):
			if ui != null:
				ui.call("show_message", "Raka", "Periksa hasil training di laptop dulu sebelum pulang.")
			return
		GameState.record_loop()
		SceneTransition.change_scene("res://lab_komputer.tscn", "LoopReturn")
		return

	if destination_scene == "res://gudang.tscn" and GameState.loop_count == 0:
		if ui != null:
			ui.call("show_message", "Raka", "Periksa laptop, lalu coba pintu keluar utama terlebih dahulu.")
		return

	var missing := GameState.get_missing_clues(required_clues)
	if not missing.is_empty():
		var clue_names := PackedStringArray()
		for clue_id in missing:
			clue_names.append(GameState.get_clue_name(clue_id))
		if ui != null:
			ui.call("show_message", "Jalur belum terbuka", "Periksa dulu: " + ", ".join(clue_names))
		return

	if destination_scene.is_empty():
		push_warning("Portal '%s' has no destination scene." % target_name)
		return
	SceneTransition.change_scene(destination_scene, destination_spawn)
