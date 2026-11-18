extends SceneTree
var failures := 0
var state: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func settle() -> void:
	await process_frame
	await physics_frame
	await physics_frame
func finish_dialogue() -> void:
	var ui := get_first_node_in_group("gameplay_ui")
	for i in range(12):
		if ui._mode != "dialogue": break
		ui.advance_dialogue()
	await create_timer(0.15).timeout
func run() -> void:
	state = root.get_node("GameState")
	state.reset_run()
	state.seen_story_events = PackedStringArray(["opening","enter_gudang","enter_studio","return_lab"])
	change_scene_to_file("res://studio_desain.tscn")
	await settle()
	await create_timer(0.1).timeout
	check(state.finale_phase == "investigation" and not is_instance_valid(current_scene.get_node("Finale").ardi), "Early Studio visit does not start chase")
	check(not state.clue_block_reason("C6").is_empty(), "Evidence gates deduction, not doors")
	for id in ["C1","C2","C3","C4","C5","C6"]: state.add_clue(id,id,"test")
	state.loop_count = 1
	state.deduction_step = 3
	await create_timer(0.15).timeout
	check(state.finale_phase == "briefing", "C6 triggers Studio briefing without room reload")
	await finish_dialogue()
	check(state.finale_phase == "chase", "Chase starts after dialogue")
	check(state.checkpoint.get("area") == "studio_desain" and state.checkpoint.clues.size() == 6, "Checkpoint stores Studio and all clues")
	for expected in ["studio_desain","gudang","labkom"]:
		var finale: Node = current_scene.get_node("Finale")
		var player: CharacterBody2D = current_scene.get_node("Raka")
		var ghost: CharacterBody2D = finale.ardi
		player.set_physics_process(false)
		finale.set_physics_process(false)
		check(finale._initialized and ghost.navigation.get_point_count() > 50, "Physics navigation exists in " + expected)
		# Hide without moving the player: it must remain active and keep its last seen position.
		player.enter_hide()
		var remembered: Vector2 = ghost.last_seen_position
		var before := ghost.global_position
		ghost.state = "CHASE"
		for i in range(100):
			await physics_frame
			ghost.pursue(0.1,Vector2(99999,99999),true)
		check(ghost.state == "PATROL" and ghost.visible, "Hidden Raka leads to active patrol in " + expected)
		check(ghost.last_seen_position == remembered, "No hidden position tracking in " + expected)
		check(ghost.global_position.distance_to(before) > 30, "Ardi continues moving in " + expected)
		check(state.finale_phase == "chase", "Hiding alone does not complete chase in " + expected)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = ghost._shape
		query.transform = ghost.global_transform
		query.collision_mask = 1
		query.exclude = [ghost.get_rid(),player.get_rid()]
		check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(), "Ghost stays outside solid furniture in " + expected)
		var patrol_position := ghost.global_position
		ghost.global_position = player.body_shape.global_position
		finale._physics_process(0.016)
		check(state.finale_phase == "chase" and player.is_hidden, "Passing a hidden Raka cannot trigger catch in " + expected)
		ghost.global_position = patrol_position
		player.exit_hide()
		player.global_position += ghost.global_position + Vector2(35,0) - player.body_shape.global_position
		ghost.pursue(0.016,player.body_shape.global_position,false)
		check(ghost.state == "CHASE", "Ardi reacquires visible Raka in " + expected)
		if expected == "labkom": break
		var door: Area2D = current_scene.get_node("PintuKembali")
		player.global_position += door.global_position - player.body_shape.global_position
		await create_timer(0.08).timeout
		door.interact(player)
		await create_timer(0.7).timeout
		check(state.finale_phase == "chase", "Room exit preserves pursuit")
		var next: Node = current_scene.get_node("Finale")
		check(next._initialized and next._arrival_delay > 0, "Ardi follows through destination door with travel delay")
		next.set_physics_process(false)
		next._arrival_delay = 0
		next.ardi.show()
	check(state.current_area == "labkom", "Pursuit reaches LABKOM from Studio via Gudang")
	print("CHASE_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
