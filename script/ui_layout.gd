extends Control
## All artwork and hit targets share a fitted 1920 x 1080 coordinate space.
const DESIGN_SIZE := Vector2(1920, 1080)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var available := get_viewport_rect().size
	var factor := minf(available.x / DESIGN_SIZE.x, available.y / DESIGN_SIZE.y)
	size = DESIGN_SIZE
	scale = Vector2.ONE * factor
	position = (available - DESIGN_SIZE * factor) * 0.5
