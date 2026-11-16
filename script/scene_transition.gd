extends CanvasLayer
## Persistent fade layer used when moving between room scenes.

var _transitioning: bool = false
var _overlay: ColorRect

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func change_scene(scene_path: String, spawn_id: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	GameState.pending_spawn_id = spawn_id
	_overlay.visible = true

	var fade_out := create_tween()
	fade_out.tween_property(_overlay, "color:a", 1.0, 0.25)
	await fade_out.finished

	var result: Error = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Could not open room scene: %s" % scene_path)
		GameState.pending_spawn_id = ""
		await _fade_in()
		_transitioning = false
		return

	await get_tree().process_frame
	await _fade_in()
	_transitioning = false

func _fade_in() -> void:
	var fade_in := create_tween()
	fade_in.tween_property(_overlay, "color:a", 0.0, 0.25)
	await fade_in.finished
