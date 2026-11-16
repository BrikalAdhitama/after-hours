extends Control

const HOME_PAGE: Texture2D = preload("res://assets/ui/HOME PAGE.png")
const Layout = preload("res://script/ui_layout.gd")
var _stage: Control
var _starting := false

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_stage = Layout.new()
	add_child(_stage)
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = HOME_PAGE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(background)

	# The labels are part of the team's finished artwork; invisible native buttons
	# add click and keyboard-focus behavior without drawing a duplicate label.
	_add_hit_target(Rect2(0.20, 0.60, 0.15, 0.06), _start_game, "Mulai game")
	_add_hit_target(Rect2(0.20, 0.67, 0.15, 0.06), _quit_game, "Keluar dari game")

func _add_hit_target(rect: Rect2, callback: Callable, hint: String) -> void:
	var button := Button.new()
	button.flat = true
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.text = ""
	button.tooltip_text = hint
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.anchor_left = rect.position.x
	button.anchor_top = rect.position.y
	button.anchor_right = rect.position.x + rect.size.x
	button.anchor_bottom = rect.position.y + rect.size.y
	button.pressed.connect(callback)
	_stage.add_child(button)

func _start_game() -> void:
	if _starting:
		return
	_starting = true
	GameState.reset_run()
	SceneTransition.change_scene("res://lab_komputer.tscn", "")

func _quit_game() -> void:
	get_tree().quit()
