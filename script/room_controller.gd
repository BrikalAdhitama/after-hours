extends Node2D
## Spawn positions and walkable floor vertices are in this room's coordinates.
@export var area_id: String = "labkom"
const FLOORS := {
	"labkom": [Vector2(-1376,94),Vector2(-177,-597),Vector2(1434,331),Vector2(189,1070)],
	"gudang": [Vector2(-863.75,234.5),Vector2(336.25,-463),Vector2(863.75,-160.5),Vector2(-336.25,537)],
	"studio_desain": [Vector2(-1405.5,21.5),Vector2(-205.5,-668.5),Vector2(1404.5,256.5),Vector2(194.5,953.5)],
}
func get_walkable_floor() -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in FLOORS[area_id]: polygon.append(to_global(point))
	return polygon

func _ready() -> void:
	var story_event := GameState.enter_area(area_id)
	var spawn_id := GameState.pending_spawn_id
	if not spawn_id.is_empty():
		var marker := get_node_or_null("Spawns/" + spawn_id) as Marker2D
		if marker != null:
			$Raka.global_position += marker.global_position - $Raka/CollisionShape2D.global_position
		GameState.pending_spawn_id = ""
	var ui: Node = get_tree().get_first_node_in_group("gameplay_ui")
	if GameState.restoring_checkpoint:
		$Raka.position = GameState.checkpoint["position"]
		GameState.restoring_checkpoint = false
		ui.show_dialogue(preload("res://script/story_data.gd").event_lines("retry_chase"))
	elif GameState.finale_phase == "investigation":
		ui.play_story_event(story_event)
	elif GameState.finale_phase == "chase" and spawn_id == "LoopReturn":
		ui.show_message("Pintu kembali berulang", "Ardi belum kehilangan jejak. Putuskan pandangannya, tunggu sampai ia berpatroli, lalu coba pintu keluar tanpa terlihat lagi.")
	var finale := Node.new()
	finale.set_script(preload("res://script/finale_controller.gd"))
	finale.name = "Finale"
	add_child(finale)
