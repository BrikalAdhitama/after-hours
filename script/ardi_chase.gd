extends CharacterBody2D
## Navigation is sampled from the existing room's actual physics, without editing it.
const BACK = preload("res://assets/character/ARDI BELAKANG.png")
const RIGHT = preload("res://assets/character/ARDI KANAN DEPAN.png")
const LEFT = preload("res://assets/character/ARDI KIRI DEPAN.png")
const STEP := 40
@export var chase_speed := 155.0
var navigation := AStar2D.new()
var player: CharacterBody2D
var _sprite: Sprite2D
var _shape: CapsuleShape2D
var _path := PackedVector2Array()
var _repath := 0.0
var _last_target := Vector2.ZERO
var _space: PhysicsDirectSpaceState2D
var state := "SEARCH"
var last_seen_position := Vector2.ZERO
var _search_time := 0.0
var _patrol_index := 0
const SEARCH_SECONDS := 9.0

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
	navigation.clear()
	var polygon: PackedVector2Array = room.get_walkable_floor()
	var bounds := Rect2(polygon[0],Vector2.ZERO)
	for point in polygon: bounds = bounds.expand(point)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.collision_mask = 1
	query.exclude = [get_rid(), player.get_rid()]
	query.margin = 3.0
	var cells := {}
	for x in range(floori(bounds.position.x / STEP) * STEP, ceili(bounds.end.x), STEP):
		for y in range(floori(bounds.position.y / STEP) * STEP, ceili(bounds.end.y), STEP):
			var point := Vector2(x,y)
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
	last_seen_position = near_player
	state = "SEARCH"
	return true

func spawn_at_entry(entry: Vector2, previous_state: String) -> bool:
	var id := navigation.get_closest_point(entry)
	if id < 0: return false
	global_position = navigation.get_point_position(id)
	last_seen_position = entry
	_last_target = entry
	state = "PATROL" if previous_state == "PATROL" else "SEARCH"
	return true

func pursue(delta: float, target_position: Vector2, hidden: bool) -> void:
	_repath -= delta
	# Only sight updates the last known position; hiding never feeds a new target.
	if not hidden and can_see(target_position):
		state = "CHASE"
		_search_time = 0.0
		last_seen_position = target_position
		_last_target = target_position
	elif state == "CHASE":
		state = "SEARCH"
		_search_time = 0.0
		_last_target = last_seen_position
		_repath = 0
	if state == "SEARCH":
		_search_time += delta
		if _search_time >= SEARCH_SECONDS:
			state = "PATROL"
			_choose_patrol_target()
		elif global_position.distance_to(_last_target) < 35:
			_choose_patrol_target()
	elif state == "PATROL" and (global_position.distance_to(_last_target) < 35 or _path.is_empty()):
		_choose_patrol_target()
	if _repath <= 0:
		_repath = 0.4
		var from := navigation.get_closest_point(global_position)
		var to := navigation.get_closest_point(_last_target)
		_path = navigation.get_point_path(from,to) if from >= 0 and to >= 0 else PackedVector2Array()
		# A repath must not pull the moving body back toward its previous grid cell.
		if _path.size() > 1:
			var sweep := PhysicsShapeQueryParameters2D.new()
			sweep.shape = _shape
			sweep.transform = global_transform
			sweep.motion = _path[1] - global_position
			sweep.collision_mask = 1
			sweep.exclude = [get_rid(), player.get_rid()]
			if _space.cast_motion(sweep)[0] >= 0.999: _path.remove_at(0)
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 8:
		_path.remove_at(0)
	var direction := Vector2.ZERO
	if not _path.is_empty():
		direction = global_position.direction_to(_path[0])
		var speed := chase_speed if state == "CHASE" else (125.0 if state == "SEARCH" else 85.0)
		velocity = direction * minf(speed, global_position.distance_to(_path[0]) / maxf(delta,0.001))
	else:
		velocity = Vector2.ZERO
	if direction.length_squared() > 0:
		_sprite.texture = BACK if direction.y < -0.1 else (RIGHT if direction.x >= 0 else LEFT)
	move_and_slide()

func _choose_patrol_target() -> void:
	var ids := navigation.get_point_ids()
	if ids.is_empty():
		state = "IDLE"
		return
	var from := navigation.get_closest_point(global_position)
	_patrol_index = (_patrol_index + 37) % ids.size()
	for i in range(ids.size()):
		var id := ids[(_patrol_index + i) % ids.size()]
		var point := navigation.get_point_position(id)
		var distance := point.distance_to(global_position)
		if distance < 170 or distance > 550: continue
		if navigation.get_id_path(from,id).is_empty(): continue
		_last_target = point
		_repath = 0
		return

func can_catch(target_position: Vector2) -> bool:
	if global_position.distance_to(target_position) > 36:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position,target_position,1,[get_rid(),player.get_rid()])
	return _space.intersect_ray(ray).is_empty()

func can_see(target_position: Vector2) -> bool:
	if global_position.distance_to(target_position) > 360.0:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position,target_position,1,[get_rid(),player.get_rid()])
	return _space.intersect_ray(ray).is_empty()
