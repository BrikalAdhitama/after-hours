extends Area2D
## Only a fresh E press activates a door; overlap never teleports the player.
@export var target_name: String = "Pintu"
@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn: String = ""
@export var is_loop_exit := false

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 160.0
	shape.shape = circle
	add_child(shape)

func is_in_range(player: Node2D) -> bool:
	return overlaps_body(player)

func get_prompt() -> String:
	return "[E] Gunakan " + target_name

func interact(player: Node) -> void:
	if SceneTransition._transitioning or not overlaps_body(player): return
	var ui: Node = get_tree().get_first_node_in_group("gameplay_ui")
	if ui != null and (bool(ui.get("inventory_open")) or bool(ui.get("pause_open"))): return
	var finale: Node = get_tree().get_first_node_in_group("finale")
	if is_loop_exit:
		if GameState.finale_phase == "chase" and finale != null:
			if finale.try_escape():
				GameState.set_finale_phase("choice")
				ui.show_finale("choice")
				return
		if GameState.finale_phase == "escape":
			GameState.set_finale_phase("choice")
			ui.show_finale("choice")
			return
		GameState.record_loop()
		if finale != null: finale.prepare_transfer(global_position)
		SceneTransition.change_scene("res://lab_komputer.tscn", "LoopReturn")
		return
	if destination_scene.is_empty():
		push_warning("Portal has no destination: " + name)
		return
	if finale != null: finale.prepare_transfer(global_position)
	SceneTransition.change_scene(destination_scene, destination_spawn)
