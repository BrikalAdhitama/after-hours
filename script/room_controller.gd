extends Node2D
## Applies the spawn marker selected by the last door interaction.

@export var area_id: String = "labkom"

func _ready() -> void:
	var story_event := GameState.enter_area(area_id)
	var spawn_id := GameState.pending_spawn_id
	if not spawn_id.is_empty():
		var marker := get_node_or_null("Spawns/" + spawn_id) as Marker2D
		var player := get_node_or_null("Raka") as CharacterBody2D
		if marker != null and player != null:
			player.position = marker.position
		GameState.pending_spawn_id = ""
	var ui := get_tree().get_first_node_in_group("gameplay_ui")
	if ui != null:
		if GameState.restoring_checkpoint:
			$Raka.position = GameState.checkpoint["position"]
			GameState.restoring_checkpoint = false
			ui.call("show_dialogue", preload("res://script/story_data.gd").event_lines("retry_chase"))
		else:
			ui.call("play_story_event", story_event)
	if area_id == "labkom" and GameState.investigation_complete:
		var finale := Node.new()
		finale.set_script(preload("res://script/finale_controller.gd"))
		finale.name = "Finale"
		add_child(finale)
