extends SceneTree
var failures := 0
var state: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func settle() -> void:
	await process_frame
	await physics_frame
	await physics_frame
func run() -> void:
	state = root.get_node("GameState")
	for scene in ["lab_komputer", "gudang", "studio_desain"]:
		state.reset_run()
		state.seen_story_events = PackedStringArray(["opening", "enter_gudang", "enter_studio"])
		change_scene_to_file("res://" + scene + ".tscn")
		await settle()
		var room: Node2D = current_scene
		var player: CharacterBody2D = room.get_node("Raka")
		player.set_physics_process(false)
		var collision: CollisionShape2D = player.get_node("CollisionShape2D")
		var offset := collision.global_position - player.global_position
		var floor_points: Array
		match scene:
			"lab_komputer": floor_points = [Vector2(-1376,94),Vector2(-177,-597),Vector2(1434,331),Vector2(189,1070)]
			"gudang": floor_points = [Vector2(-863.75,234.5),Vector2(336.25,-463),Vector2(863.75,-160.5),Vector2(-336.25,537)]
			_: floor_points = [Vector2(-1405.5,21.5),Vector2(-205.5,-668.5),Vector2(1404.5,256.5),Vector2(194.5,953.5)]
		var polygon := PackedVector2Array()
		for p in floor_points: polygon.append(room.to_global(p))
		var space := root.world_2d.direct_space_state
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = collision.shape
		query.exclude = [player.get_rid()]
		query.collision_mask = 1
		var nav := AStar2D.new()
		var cells := {}
		for x in range(-1440,1441,24):
			for y in range(-696,1105,24):
				var point := room.to_global(Vector2(x,y))
				if not Geometry2D.is_point_in_polygon(point,polygon): continue
				query.transform = Transform2D(0,point)
				if not space.intersect_shape(query).is_empty(): continue
				var id := nav.get_available_point_id()
				nav.add_point(id,point)
				cells[Vector2i(x,y)] = id
		for cell: Vector2i in cells:
			for d in [Vector2i(24,0),Vector2i(0,24)]:
				if not cells.has(cell+d): continue
				var start: Vector2 = nav.get_point_position(cells[cell])
				if not player.test_move(Transform2D(0,start-offset),Vector2(d)):
					nav.connect_points(cells[cell],cells[cell+d])
		var start_id := nav.get_closest_point(collision.global_position)
		query.transform = collision.global_transform
		check(space.intersect_shape(query).is_empty(), scene + " default spawn clear")
		for marker: Node2D in room.get_node("Spawns").get_children():
			query.transform = Transform2D(0,marker.global_position)
			check(space.intersect_shape(query).is_empty(), scene + " spawn " + marker.name + " clear")
			check(not nav.get_id_path(start_id,nav.get_closest_point(marker.global_position)).is_empty(), scene + " spawn reachable " + marker.name)
		for target: Node2D in get_nodes_in_group("interactables"):
			var reachable := false
			for id in nav.get_point_ids():
				if nav.get_point_position(id).distance_to(target.global_position) < 150 and not nav.get_id_path(start_id,id).is_empty():
					reachable = true
					break
			check(reachable, scene + " interaction reachable " + target.name)
			if target.get("interaction_type") == "hide":
				player.global_position += target.global_position - collision.global_position
				await create_timer(0.08).timeout
				var event := InputEventKey.new()
				event.physical_keycode = KEY_E
				event.pressed = true
				player._input(event)
				check(player.is_hidden and not player.sprite.visible and player.hiding_spot == target, scene + " E hides at " + target.name)
				var before := player.global_position
				player._physics_process(0.1)
				check(player.global_position.is_equal_approx(before), "Hidden player cannot move")
				event.echo = true
				player._input(event)
				check(player.is_hidden, "Held E cannot immediately exit")
				event.echo = false
				player._input(event)
				check(not player.is_hidden and player.sprite.visible and player._feet_clear(collision.global_position), "E exits safely " + target.name)
			if target.get_script().resource_path.ends_with("portal.gd"):
				check(target is Area2D, "Door uses Area2D " + target.name)
		for i in range(4):
			var middle := (polygon[i]+polygon[(i+1)%4])*0.5
			var edge := polygon[(i+1)%4]-polygon[i]
			var out := Vector2(edge.y,-edge.x).normalized()
			check(player.test_move(Transform2D(0,middle-out*70-offset),out*150),scene+" boundary blocks "+str(i))
	# Exercise reciprocal doors with NO clues or loop prerequisites.
	state.reset_run()
	state.seen_story_events = PackedStringArray(["opening", "enter_gudang", "enter_studio"])
	change_scene_to_file("res://lab_komputer.tscn")
	await settle()
	for hop in [["Object/PintuGudangPortal","gudang"],["PintuStudio","studio_desain"],["PintuKembali","gudang"],["PintuKembali","labkom"]]:
		var player: CharacterBody2D = current_scene.get_node("Raka")
		var door: Area2D = current_scene.get_node(hop[0])
		player.global_position += door.global_position - player.get_node("CollisionShape2D").global_position
		await settle()
		await create_timer(0.08).timeout
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.pressed = true
		print("DOOR_TEST ", door.name, " overlap=",door.overlaps_body(player), " nearest=",player._find_nearest_interactable()," ui=",get_first_node_in_group("gameplay_ui")._mode)
		player._input(event)
		await create_timer(0.7).timeout
		check(state.current_area == hop[1], "E traverses freely to " + hop[1])
		await create_timer(0.1).timeout
		check(not root.get_node("SceneTransition")._transitioning, "No automatic repeat teleport")
	var player: CharacterBody2D = current_scene.get_node("Raka")
	var main_exit: Area2D = current_scene.get_node("Object/PintuKeluarPortal")
	player.global_position += main_exit.global_position - player.body_shape.global_position
	await create_timer(0.08).timeout
	main_exit.interact(player)
	await create_timer(0.7).timeout
	check(state.loop_count == 1 and not state.has_clue("C1"), "Main exit accessible before laptop, preserving loop")
	check(state.get_objective().contains("laptop"), "Early loop still guides player to laptop")
	check(not state.clue_block_reason("C3").is_empty(), "Early loop does not bypass initial clue event")
	print("ACCESS_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
