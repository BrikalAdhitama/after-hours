extends CharacterBody2D
## Navigation is sampled from the existing room's actual physics, without editing it.
const BACK = preload("res://assets/character/ARDI BELAKANG.png")
const RIGHT = preload("res://assets/character/ARDI KANAN DEPAN.png")
const LEFT = preload("res://assets/character/ARDI KIRI DEPAN.png")
const STEP := 40
@export var chase_speed := 135.0
var navigation := AStar2D.new()
var player: CharacterBody2D
var _sprite: Sprite2D
var _shape: CapsuleShape2D
var _path := PackedVector2Array()
var _repath := 0.0
var _last_target := Vector2.ZERO
var _space: PhysicsDirectSpaceState2D

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	_shape = CapsuleShape2D.new()
	_shape.radius = 11
	_shape.height = 42
	var collision := CollisionShape2D.new()
	collision.shape = _shape
	add_child(collision)
	_sprite = Sprite2D.new()
	_sprite.texture = LEFT
	_sprite.scale = Vector2(0.4, 0.4)
	_sprite.position = Vector2(0, -85)
	add_child(_sprite)
	set_physics_process(false)

func build_navigation(room: Node2D, target: CharacterBody2D) -> void:
	player = target
	_space = get_world_2d().direct_space_state
	var polygon := PackedVector2Array()
	for point in [Vector2(-1376,94),Vector2(-177,-597),Vector2(1434,331),Vector2(189,1070)]:
		polygon.append(room.to_global(point))
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.collision_mask = 1
	query.exclude = [get_rid(), player.get_rid()]
	query.margin = 3.0
	var cells := {}
	for x in range(-1400,1441,STEP):
		for y in range(-600,1121,STEP):
			var point := room.to_global(Vector2(x,y))
			if not Geometry2D.is_point_in_polygon(point, polygon): continue
			query.transform = Transform2D(0,point)
			if not _space.intersect_shape(query).is_empty(): continue
			var id := navigation.get_available_point_id()
			navigation.add_point(id,point)
			cells[Vector2i(x,y)] = id
	for cell: Vector2i in cells:
		for step in [Vector2i(STEP,0),Vector2i(0,STEP),Vector2i(STEP,STEP),Vector2i(-STEP,STEP)]:
			var neighbor: Vector2i = cell + step
			if not cells.has(neighbor): continue
			var from: Vector2 = navigation.get_point_position(cells[cell])
			var to: Vector2 = navigation.get_point_position(cells[neighbor])
			query.transform = Transform2D(0,from)
			query.motion = to - from
			var safe := _space.cast_motion(query)
			if safe[0] >= 0.999:
				navigation.connect_points(cells[cell],cells[neighbor])
			query.motion = Vector2.ZERO

func select_spawn(near_player: Vector2, hiding_place: Vector2) -> bool:
	var start := navigation.get_closest_point(near_player)
	if start < 0: return false
	var best := -INF
	var selected := -1
	for id in navigation.get_point_ids():
		var point := navigation.get_point_position(id)
		var distance := point.distance_to(near_player)
		if distance < 500 or distance > 1000: continue
		var route := navigation.get_id_path(id,start)
		if route.is_empty(): continue
		var score := point.distance_to(hiding_place) - absf(distance - 650) * 2
		if score > best:
			best = score
			selected = id
	if selected < 0: return false
	global_position = navigation.get_point_position(selected)
	_last_target = near_player
	return true

func pursue(delta: float, target_position: Vector2, hidden: bool) -> void:
	_repath -= delta
	if not hidden:
		_last_target = target_position
	if _repath <= 0:
		_repath = 0.4
		var from := navigation.get_closest_point(global_position)
		var to := navigation.get_closest_point(_last_target)
		_path = navigation.get_point_path(from,to) if from >= 0 and to >= 0 else PackedVector2Array()
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 8:
		_path.remove_at(0)
	var direction := Vector2.ZERO
	if not _path.is_empty():
		direction = global_position.direction_to(_path[0])
		velocity = direction * minf(chase_speed, global_position.distance_to(_path[0]) / maxf(delta,0.001))
	else:
		velocity = Vector2.ZERO
	if direction.length_squared() > 0:
		_sprite.texture = BACK if direction.y < -0.1 else (RIGHT if direction.x >= 0 else LEFT)
	move_and_slide()

func can_catch(target_position: Vector2) -> bool:
	if global_position.distance_to(target_position) > 36:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position,target_position,1,[get_rid(),player.get_rid()])
	return _space.intersect_ray(ray).is_empty()
