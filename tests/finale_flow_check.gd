extends SceneTree
var failures := 0
var state: Node
var player: CharacterBody2D
var finale: Node
var ui: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func refs() -> void:
	player = current_scene.get_node("Raka")
	finale = get_first_node_in_group("finale")
	ui = get_first_node_in_group("gameplay_ui")
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func finish_dialogue() -> void:
	for i in range(12):
		if ui._mode != "dialogue": return
		key(KEY_E)
func click_button(index: int) -> void:
	await process_frame
	await process_frame
	var button: Button = ui._finale_screen._actions.get_child(index)
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform() * (button.size * 0.5)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func use_door(path: String) -> void:
	var door: Area2D = current_scene.get_node(path)
	player.global_position += door.global_position - player.body_shape.global_position
	await create_timer(0.08).timeout
	key(KEY_E)
	await create_timer(0.7).timeout
	refs()
func walk_to(target: Node2D) -> bool:
	var graph: AStar2D = finale.ardi.navigation
	var feet: Vector2 = player.body_shape.global_position
	var start := graph.get_closest_point(feet)
	var best := PackedVector2Array()
	for id in graph.get_point_ids():
		if graph.get_point_position(id).distance_to(target.global_position) > 100: continue
		var path := graph.get_point_path(start,id)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()): best = path
	if best.is_empty(): return false
	player.set_physics_process(false)
	var index := 0
	for tick in range(2400):
		if index == best.size():
			player.velocity = Vector2.ZERO
			return true
		await physics_frame
		feet = player.body_shape.global_position
		if feet.distance_to(best[index]) < 8:
			index += 1
			continue
		player.velocity = feet.direction_to(best[index]) * player.speed
		player.move_and_slide()
	return false
func run() -> void:
	state = root.get_node("GameState")
	state.reset_run()
	for id in ["C1","C2","C3","C4","C5","C6"]: state.add_clue(id,id,"Saved evidence")
	state.loop_count = 1
	state.deduction_step = 3
	state.seen_story_events = PackedStringArray(["enter_studio","enter_gudang","return_lab"])
	change_scene_to_file("res://studio_desain.tscn")
	await create_timer(0.3).timeout
	refs()
	finish_dialogue()
	await create_timer(0.15).timeout
	check(state.finale_phase == "chase" and finale._initialized, "Studio starts pursuit")
	key(KEY_I)
	check(ui._mode == "play", "Inventory cannot pause away pursuit")
	key(KEY_ESCAPE)
	var before: Vector2 = finale.ardi.global_position
	await create_timer(0.25).timeout
	check(paused and finale.ardi.global_position == before, "Pause freezes Ardi")
	key(KEY_ESCAPE)
	finale.ardi.global_position = player.body_shape.global_position
	await create_timer(0.1).timeout
	check(state.finale_phase == "caught" and ui._mode == "jumpscare", "Proximity catch starts video before Game Over")
	check(ui._jumpscare.video.stream is VideoStreamTheora and ui._jumpscare.video.is_playing(), "Native Theora stream is playing")
	var frozen := player.global_position
	Input.action_press("move_right")
	key(KEY_ESCAPE)
	key(KEY_I)
	finale.caught()
	await create_timer(0.9).timeout
	Input.action_release("move_right")
	check(player.global_position == frozen and ui._mode == "jumpscare" and not paused, "Jumpscare locks movement and cannot be dismissed or retriggered")
	check(ui._jumpscare.video.stream_position > 0.5, "Video decoding advances")
	await create_timer(2.3).timeout
	check(ui._mode == "finale" and ui._finale_mode == "caught" and not ui._jumpscare.used_fallback, "Video finishes naturally then opens Game Over")
	check(ui._finale_screen._actions.get_child_count() == 2 and ui._finale_screen._actions.get_child(0).text == "COBA LAGI", "Game Over has retry/menu, no ending choices")
	var saved: Vector2 = state.checkpoint.position
	await click_button(0)
	await create_timer(0.8).timeout
	refs()
	check(state.current_area == "studio_desain" and player.position.is_equal_approx(saved), "COBA LAGI restores Studio checkpoint position")
	check(state.clues.size() == 6 and state.deduction_step == 3 and state.loop_count == 1, "Retry keeps checkpoint investigation")
	check(not player.is_hidden and state.finale_phase == "briefing", "Retry resets hidden state and plays briefing")
	finish_dialogue()
	# Test missing stream fallback, then real MENU UTAMA button.
	ui._jumpscare.stream_path = "res://missing-test-video.ogv"
	finale.caught()
	await create_timer(2.0).timeout
	check(ui._mode == "finale" and ui._jumpscare.used_fallback, "Missing video has finite illustration fallback")
	await click_button(1)
	await create_timer(0.7).timeout
	check(current_scene.scene_file_path == "res://main_menu.tscn", "Game Over MENU UTAMA works")
	# Resume checkpoint to exercise both finale buttons and room transitions.
	for choice in ["wait", "leave"]:
		state.restore_chase_checkpoint()
		change_scene_to_file(str(state.checkpoint.scene))
		await create_timer(0.3).timeout
		refs()
		finish_dialogue()
		finale.set_physics_process(false)
		await use_door("PintuKembali")
		finale.set_physics_process(false)
		await use_door("PintuKembali")
		check(state.current_area == "labkom" and state.finale_phase == "chase", "Entering LABKOM does not complete pursuit")
		finale.set_physics_process(false)
		finale._arrival_delay = 0
		finale.ardi.show()
		finale.ardi.state = "CHASE"
		var loop_before: int = state.loop_count
		await use_door("Object/PintuKeluarPortal")
		check(state.loop_count == loop_before + 1 and state.finale_phase == "chase", "Exit still loops before Ardi loses the trail")
		finale.set_physics_process(false)
		finale._arrival_delay = 0
		finale.ardi.show()
		finale.ardi.state = "PATROL"
		var door: Area2D = current_scene.get_node("Object/PintuKeluarPortal")
		for id in finale.ardi.navigation.get_point_ids():
			var point: Vector2 = finale.ardi.navigation.get_point_position(id)
			if point.distance_to(door.global_position) > 1000:
				finale.ardi.global_position = point
				break
		# Walk from the opposite entrance using real move_and_slide/collision.
		player.global_position += current_scene.get_node("Spawns/DariGudang").global_position - player.body_shape.global_position
		check(await walk_to(door), "Final exit reachable on foot with actual LABKOM collision")
		await create_timer(0.08).timeout
		key(KEY_E)
		check(state.finale_phase == "choice" and ui._finale_mode == "choice", "Exit after losing trail opens ending choices")
		await click_button(0 if choice == "wait" else 1)
		check(state.finale_phase == "ending" and state.ending_id == choice, "Ending button selects " + choice)
		check(ui._finale_screen._title.text == ("Akhirnya Pulang" if choice == "wait" else "Pulang"), "Ending title follows GDD")
		var final_phase: String = state.finale_phase
		finale.caught()
		check(state.finale_phase == final_phase, "Late catch cannot overwrite ending")
	await click_button(0)
	await create_timer(0.8).timeout
	refs()
	check(state.clues.is_empty() and state.finale_phase == "investigation" and ui._mode == "dialogue", "Restart clears pursuit and replays opening")
	print("FINALE_FLOW_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
