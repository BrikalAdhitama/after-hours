
extends CharacterBody2D

@export var speed: float = 180.0
@export var interaction_range: float = 180.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var is_hidden: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _process(_delta: float) -> void:
	var ui: Node = _get_gameplay_ui()
	if ui == null:
		return
	if is_hidden:
		ui.call("set_interaction_prompt", "[E] Keluar dari lemari")
	elif bool(ui.get("inventory_open")):
		ui.call("set_interaction_prompt", "")
	else:
		var target = _find_nearest_interactable()
		ui.call("set_interaction_prompt", str(target.call("get_prompt")) if target != null else "")

func _physics_process(_delta: float) -> void:
	var ui: Node = _get_gameplay_ui()
	if is_hidden or (ui != null and bool(ui.get("inventory_open"))):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	# Gerakan isometrik
	var direction := Vector2(
		input_dir.x - input_dir.y,
		(input_dir.x + input_dir.y) * 0.5
	).normalized()

	velocity = direction * speed

	if input_dir != Vector2.ZERO:
		_update_facing(direction)

	# Bergerak dengan collision
	move_and_slide()

func _update_facing(screen_direction: Vector2) -> void:
	# Choose the sprite from the transformed isometric direction, not the raw key axes.
	# Pure horizontal screen movement has no matching side-facing sprite, so keep the
	# last visible direction until a suitable side sprite is available.
	if absf(screen_direction.y) < 0.1:
		return

	if screen_direction.y > 0.0:
		# The front-facing artwork is mirrored from the viewer's perspective.
		sprite.animation = "down_left" if screen_direction.x >= 0.0 else "down_right"
	else:
		sprite.animation = "up_right" if screen_direction.x >= 0.0 else "up_left"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var keycode: int = event.physical_keycode
	if keycode == KEY_NONE:
		keycode = event.keycode

	var ui: Node = _get_gameplay_ui()
	if keycode == KEY_I:
		if ui != null:
			ui.call("toggle_inventory")
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_ESCAPE and ui != null:
		ui.call("handle_escape")
		get_viewport().set_input_as_handled()
		return

	if keycode != KEY_E or (ui != null and bool(ui.get("inventory_open"))):
		return

	if is_hidden:
		exit_hide()
		get_viewport().set_input_as_handled()
		return

	var target = _find_nearest_interactable()
	if target != null:
		target.call("interact", self)
		get_viewport().set_input_as_handled()
	elif ui != null:
		ui.call("show_message", "Belum ada objek untuk diperiksa", "Dekati objek sampai prompt [E] muncul.")
		get_viewport().set_input_as_handled()

func enter_hide() -> void:
	if is_hidden:
		return
	is_hidden = true
	sprite.visible = false
	velocity = Vector2.ZERO
	var ui: Node = _get_gameplay_ui()
	if ui != null:
		ui.call("show_message", "Lemari", "Raka bersembunyi. Tekan E untuk keluar.")

func exit_hide() -> void:
	if not is_hidden:
		return
	is_hidden = false
	sprite.visible = true
	var ui: Node = _get_gameplay_ui()
	if ui != null:
		ui.call("show_message", "Lemari", "Raka keluar dari lemari.")

func _find_nearest_interactable() -> Node2D:
	var interaction_origin := body_shape.global_position
	var nearest: Node2D
	var nearest_distance := interaction_range
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		var distance: float = interaction_origin.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

func _get_gameplay_ui() -> Node:
	return get_tree().get_first_node_in_group("gameplay_ui")
