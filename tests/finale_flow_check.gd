extends SceneTree
var failures := 0
var state: Node
var player: CharacterBody2D
var finale: Node
var ui: Node

func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = ui._screen.get_global_transform() * point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func refs() -> void:
	player = current_scene.get_node("Raka")
	finale = get_first_node_in_group("finale")
	ui = get_first_node_in_group("gameplay_ui")
func finish_dialogue() -> void:
	for i in range(12):
		if ui._mode != "dialogue": return
		key(KEY_E)

func interaction_route(target: Node2D) -> PackedVector2Array:
	var graph: AStar2D = finale.ardi.navigation
	var feet: Vector2 = player.get_node("CollisionShape2D").global_position
	var original := player.global_position
	var start := graph.get_closest_point(feet)
	var best := PackedVector2Array()
	for id in graph.get_point_ids():
		var point := graph.get_point_position(id)
		if point.distance_to(target.global_position) > 165: continue
		player.global_position = point - player.get_node("CollisionShape2D").position
		if player._find_nearest_interactable() != target: continue
		var path := graph.get_point_path(start,id)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	player.global_position = original
	return best

func walk_route(path: PackedVector2Array) -> bool:
	player.set_physics_process(false)
	var index := 0
	for tick in range(2400):
		if state.finale_phase == "caught": return false
		if index >= path.size():
			player.velocity = Vector2.ZERO
			return true
		await physics_frame
		var feet: Vector2 = player.get_node("CollisionShape2D").global_position
		if feet.distance_to(path[index]) < 9:
			index += 1
			continue
		player.velocity = feet.direction_to(path[index]) * player.speed
		player.move_and_slide()
	return false

func _run() -> void:
	state = root.get_node("GameState")
	state.reset_run()
	for i in range(1,7):
		state.add_clue("C%d" % i,"Clue %d" % i,"Saved body")
	state.loop_count = 1
	state.pending_spawn_id = "DariStudio"
	change_scene_to_file("res://lab_komputer.tscn")
	await create_timer(1.0).timeout
	refs()
	check(finale != null and finale._initialized, "Ardi navigation and reachable spawn prepared")
	check(state.finale_phase == "briefing" and not state.checkpoint.is_empty(), "Checkpoint precedes chase")
	finish_dialogue()
	check(state.finale_phase == "chase", "Closing briefing starts chase")
	var distance_before: float = finale.ardi.global_position.distance_to(player.get_node("CollisionShape2D").global_position)
	await create_timer(1.0).timeout
	var distance_after: float = finale.ardi.global_position.distance_to(player.get_node("CollisionShape2D").global_position)
	check(distance_after < distance_before, "Ardi actively approaches Raka")
	key(KEY_I)
	check(ui._mode == "play", "Inventory cannot hide the chase")
	key(KEY_ESCAPE)
	var paused_position: Vector2 = finale.ardi.global_position
	await create_timer(0.25).timeout
	check(paused and finale.ardi.global_position.is_equal_approx(paused_position), "Pause freezes Ardi")
	key(KEY_ESCAPE)
	# Exercise real proximity catch, rather than directly calling the failure handler.
	finale.ardi.global_position = player.get_node("CollisionShape2D").global_position
	await physics_frame
	await physics_frame
	check(state.finale_phase == "caught" and ui._mode == "finale", "Proximity catch shows Game Over")
	key(KEY_ESCAPE)
	key(KEY_I)
	check(ui._mode == "finale", "Caught screen cannot be bypassed")
	click(Vector2(1180,698))
	await create_timer(1.0).timeout
	refs()
	check(state.clues.size() == 6 and state.loop_count == 1, "Retry preserves saved clue progress")
	check(player.position.is_equal_approx(state.checkpoint.position), "Retry restores pre-chase position")
	check(not player.is_hidden and state.finale_phase == "briefing", "Retry returns to briefing with visible Raka")
	finish_dialogue()
	var wardrobe: Node2D = current_scene.get_node("Object/LemariInteractable")
	var route := interaction_route(wardrobe)
	check(not route.is_empty(), "Wardrobe interaction point reachable through actual room physics")
	if route.is_empty():
		quit(1)
		return
	check(await walk_route(route), "Raka reaches wardrobe on foot while Ardi chases")
	if state.finale_phase == "caught":
		quit(1)
		return
	key(KEY_E)
	check(player.is_hidden, "E near wardrobe hides Raka")
	await create_timer(2.0).timeout
	key(KEY_ESCAPE)
	var hidden_before: float = finale._hidden_time
	await create_timer(0.25).timeout
	check(is_equal_approx(finale._hidden_time,hidden_before), "Pause does not advance hiding timer")
	key(KEY_ESCAPE)
	await create_timer(3.2).timeout
	check(state.finale_phase == "escape" and not finale.ardi.visible, "Five seconds hiding clears threat")
	check(state.get_objective().contains("pintu keluar utama"), "Next objective explicitly names final exit")
	key(KEY_E)
	check(not player.is_hidden, "E leaves wardrobe")
	var door: Node2D = current_scene.get_node("Object/PintuKeluarPortal")
	check(await walk_route(interaction_route(door)), "Final door reachable on foot")
	key(KEY_E)
	check(state.finale_phase == "choice" and ui._mode == "finale", "E at door opens choice")
	await process_frame
	await process_frame
	click(Vector2(1180,795))
	check(state.finale_phase == "ending" and state.ending_id == "leave", "Pulang sendirian selects bad ending")
	check(ui._finale_screen._title.text == "Pulang", "Bad ending title matches GDD")
	await process_frame
	await process_frame
	click(Vector2(1180,795))
	await create_timer(0.8).timeout
	check(current_scene.scene_file_path == "res://main_menu.tscn", "Ending returns to main menu")
	if not current_scene.has_method("_start_game"):
		quit(1)
		return
	current_scene._start_game()
	await create_timer(0.8).timeout
	check(state.clues.is_empty() and state.finale_phase == "investigation", "New game resets final phase and clues")
	print("FINALE_FLOW_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
