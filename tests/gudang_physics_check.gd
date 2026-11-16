extends SceneTree
var failures := 0
var FLOOR := PackedVector2Array([Vector2(-863.75,234.5),Vector2(336.25,-463),Vector2(863.75,-160.5),Vector2(-336.25,537)])
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func _run() -> void:
	var studio := "--studio" in OS.get_cmdline_user_args()
	var props := ["RakDusKiri","RakDusBelakang","RakKanan","KursiTersimpan","KursiTunggal"]
	var targets := ["Spawns/DariLabkom","Spawns/DariStudio","ClueRekaman","ClueCatatan","PintuKembali","PintuStudio"]
	var grid_x := range(-864, 865, 24)
	var grid_y := range(-456, 553, 24)
	var start := Vector2i(-240,144)
	if studio:
		FLOOR = PackedVector2Array([Vector2(-1405.5,21.5),Vector2(-205.5,-668.5),Vector2(1404.5,256.5),Vector2(194.5,953.5)])
		props = ["Props/MejaStudio1","Props/MejaStudio2","Props/MejaStudio3","Props/MejaStudio4","Props/MejaPanjang","Props/MejaDosen","Props/Lemari","Props/Loker","Props/IFP","Props/Rak","Props/Dispenser"]
		targets = ["Spawns/DariGudang","ClueDokumentasi","PintuKembali"]
		grid_x = range(-1416,1417,24)
		grid_y = range(-672,961,24)
		start = Vector2i(0,192)
	root.get_node("GameState").seen_story_events.append("enter_studio" if studio else "enter_gudang")
	change_scene_to_file("res://studio_desain.tscn" if studio else "res://gudang.tscn")
	await process_frame
	await physics_frame
	await physics_frame
	var room := current_scene
	var player: CharacterBody2D = room.get_node("Raka")
	player.set_physics_process(false)
	var space := root.world_2d.direct_space_state
	var shape: Shape2D = player.get_node("CollisionShape2D").shape
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.exclude = [player.get_rid()]
	query.collision_mask = player.collision_mask
	for path in targets:
		query.transform = Transform2D(0.0, room.get_node(path).global_position)
		check(space.intersect_shape(query).is_empty(), path + " has clearance for Raka")
	for prop in props:
		var node: Node2D = room.get_node(prop)
		query.transform = Transform2D(0.0, node.global_position)
		var hits := space.intersect_shape(query)
		check(not hits.is_empty(), prop + " footprint physically blocks player")
		var polygon: CollisionPolygon2D = node.get_node("Body/Footprint")
		var inside := true
		for point in polygon.polygon:
			inside = inside and Geometry2D.is_point_in_polygon(polygon.to_global(point), FLOOR)
		check(inside, prop + " footprint sits inside painted floor")
		var approach := node.global_position + Vector2(0,160)
		check(player.test_move(Transform2D(0.0,approach),Vector2(0,-160)), prop + " stops movement from front")
	for i in range(4):
		var middle := (FLOOR[i] + FLOOR[(i+1)%4]) * 0.5
		var edge := FLOOR[(i+1)%4] - FLOOR[i]
		var outward := Vector2(edge.y,-edge.x).normalized()
		var inside := middle - outward * 70.0
		check(player.test_move(Transform2D(0.0,inside),outward*150), "Floor edge " + str(i+1) + " blocks crossing")
	# Flood-fill with the actual player capsule and swept physics movement.
	var free := {}
	for x in grid_x:
		for y in grid_y:
			var point := Vector2(x,y)
			if not Geometry2D.is_point_in_polygon(point, FLOOR): continue
			query.transform = Transform2D(0.0, point)
			if space.intersect_shape(query).is_empty(): free[Vector2i(x,y)] = true
	check(free.has(start), "Central aisle has clearance")
	var queue: Array[Vector2i] = [start]
	var visited := {start: true}
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for direction in [Vector2i(24,0),Vector2i(-24,0),Vector2i(0,24),Vector2i(0,-24)]:
			var next: Vector2i = cell + direction
			if not free.has(next) or visited.has(next): continue
			if player.test_move(Transform2D(0.0,Vector2(cell)), Vector2(direction)): continue
			visited[next] = true
			queue.append(next)
	for path in targets:
		var point: Vector2 = room.get_node(path).global_position
		var reachable := false
		for cell in visited:
			if Vector2(cell).distance_to(point) <= 36 and not player.test_move(Transform2D(0.0,Vector2(cell)),point-Vector2(cell)):
				reachable = true
				break
		check(reachable, path + " reachable through central aisle")
	print(("STUDIO" if studio else "GUDANG") + "_PHYSICS_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
