extends Node2D
## Simple interaction marker that can be placed beside any scene object.

@export var target_name: String = "Objek"
@export var interaction_type: String = "inspect"
@export_multiline var description: String = "Belum ada informasi tambahan."
@export var clue_id: String = ""
@export var clue_title: String = ""
@export_multiline var clue_text: String = ""

func _ready() -> void:
	add_to_group("interactables")

func get_prompt(player_is_hidden: bool = false) -> String:
	if interaction_type == "hide":
		return "[E] Keluar dari lemari" if player_is_hidden else "[E] Bersembunyi di lemari"
	if interaction_type == "clue":
		return "[E] Periksa " + target_name
	return "[E] Interaksi dengan " + target_name

func interact(player: Node) -> void:
	match interaction_type:
		"clue":
			var ui: Node = get_tree().get_first_node_in_group("gameplay_ui")
			if ui != null:
				ui.call("add_clue", clue_id, clue_title, clue_text)
		"hide":
			if player.has_method("enter_hide"):
				player.enter_hide()
		_:
			var ui: Node = get_tree().get_first_node_in_group("gameplay_ui")
			if ui != null:
				ui.call("show_message", target_name, description)
