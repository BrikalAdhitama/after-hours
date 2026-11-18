extends SceneTree
# Run with: Godot --headless --path <project> --script res://tests/story_flow_check.gd
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func ui() -> Node:
	return get_first_node_in_group("gameplay_ui")

func settle() -> void:
	await create_timer(0.8).timeout

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func click(stage: Control, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = stage.get_global_transform() * point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func finish_dialogue() -> void:
	for i in range(12):
		if ui()._mode != "dialogue":
			return
		press(KEY_E)
	check(false, "Dialogue ends within twelve pages")

func interact(path: String) -> void:
	var player := current_scene.get_node("Raka")
	var target := current_scene.get_node(path) as Node2D
	player.global_position += target.global_position - player.get_node("CollisionShape2D").global_position
	await create_timer(0.08).timeout
	press(KEY_E)

func count_nodes(node: Node) -> int:
	var result := 1
	for child in node.get_children():
		result += count_nodes(child)
	return result

func _run() -> void:
	var state := root.get_node("GameState")
	change_scene_to_file("res://main_menu.tscn")
	await process_frame
	await process_frame
	click(current_scene._stage, Vector2(510, 670))
	await settle()
	check(current_scene.scene_file_path == "res://lab_komputer.tscn", "Start enters LABKOM")
	if ui() == null:
		quit(1)
		return
	check(ui()._mode == "dialogue" and ui()._dialogue_speaker.text == "Raka", "Opening monologue shown")
	check(ui()._dialogue_body.text.begins_with("Akhirnya selesai"), "Approved opening text")
	check(ui()._dialogue_portrait.visible and ui()._dialogue_portrait.texture.atlas.resource_path.ends_with("IMG_3827.PNG"), "Neutral Raka portrait appears in opening")
	check(state.get_objective().contains("training"), "Initial objective: training")
	var player := current_scene.get_node("Raka")
	var before: Vector2 = player.position
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	check(player.position.is_equal_approx(before), "Movement blocked during dialogue")
	press(KEY_I)
	check(ui()._mode == "dialogue", "Inventory cannot discard dialogue")
	press(KEY_ESCAPE)
	check(paused and ui().pause_open, "Esc pauses dialogue")
	click(ui()._screen, Vector2(1320, 435))
	check(not paused and ui()._mode == "dialogue", "Continue resumes same dialogue")
	finish_dialogue()
	check(ui()._mode == "play" and ui()._objective_label.visible, "Opening returns to gameplay with objective")
	var node_count := count_nodes(ui())
	for i in range(8):
		press(KEY_ESCAPE)
		press(KEY_ESCAPE)
	check(count_nodes(ui()) == node_count, "No pause UI accumulation")
	await interact("Object/LokerInteractable")
	check(not state.has_clue("C3") and ui()._message_panel.visible, "Early clue explains next action")
	await interact("Object/LaptopInteractable")
	check(ui()._mode == "dialogue" and ui()._dialogue_body.text.contains("Tidak ada orang"), "CCTV discrepancy presented")
	check(ui()._dialogue_portrait.visible and ui()._dialogue_portrait.texture.atlas.resource_path.ends_with("IMG_3830.PNG"), "Surprised Raka visible while inspecting laptop output")
	check(ui()._dialogue_art.visible and ui()._dialogue_art.texture.resource_path.ends_with("LAPTOP.png"), "Updated laptop artwork appears alongside portrait")
	press(KEY_E)
	check(ui()._dialogue_speaker.text == "Raka" and ui()._dialogue_portrait.visible, "Laptop reaction also keeps Raka portrait")
	check(state.has_clue("C1") and state.get_objective().contains("keluar utama"), "C1 saved; objective advances")
	finish_dialogue()
	check(ui()._mode == "evidence" and ui()._evidence_background.texture.resource_path.ends_with("LAPTOP.png"), "Finishing C1 opens interactive laptop attachments")
	click(ui()._evidence_targets, ui()._evidence_targets.size * Vector2(0.65,0.45))
	check(ui()._mode == "document" and ui()._document_reader.document_id == "ardi_photo", "Laptop photo opens new Ardi artwork")
	click(ui()._document_reader._window_controls, ui()._document_reader._window_controls.size * Vector2(0.95,0.065))
	check(ui()._mode == "evidence", "Artwork X closes photo back to laptop")
	click(ui()._evidence_targets, ui()._evidence_targets.size * Vector2(0.30,0.32))
	check(ui()._mode == "document" and ui()._document_reader.document_id == "student_card", "Laptop card opens new KTM artwork")
	check(not state.has_clue("C3") and state.clues.size() == 1, "Reading laptop attachment does not grant locker clue")
	click(ui()._document_reader._window_controls, ui()._document_reader._window_controls.size * Vector2(0.895,0.065))
	check(ui()._document_reader.zoom == 2.0, "Artwork maximize control enlarges attachment")
	press(KEY_ESCAPE)
	click(ui()._evidence_targets, ui()._evidence_targets.size * Vector2(0.77,0.74))
	check(ui()._evidence_body.text.contains("inventori sesi") and state.clues.size() == 1, "Laptop Save confirms session clue without duplication")
	click(ui()._evidence_targets, ui()._evidence_targets.size * Vector2(0.88,0.74))
	check(ui()._mode == "play", "Laptop Back returns to exploration")
	await interact("Object/PintuKeluarPortal")
	press(KEY_E)
	press(KEY_ESCAPE)
	check(state.loop_count == 1 and not paused, "Repeated input cannot duplicate loop or pause fade")
	await settle()
	check(ui()._mode == "dialogue" and state.get_clock_text().contains("22.17"), "First loop changes clock and starts dialogue")
	check(ui()._dialogue_portrait.texture.atlas.resource_path.ends_with("IMG_3825.PNG"), "First loop uses frightened portrait")
	finish_dialogue()
	check(state.get_objective().contains("mading dan loker"), "Loop objective points to LAB clues")
	await interact("Object/LokerInteractable")
	check(ui()._mode == "evidence" and state.has_clue("C3"), "Loker yields student card")
	check(not ui()._dialogue_portrait.visible, "Portrait hidden outside dialogue")
	click(ui()._screen, Vector2(900, 640))
	check(ui()._mode == "document" and ui()._document_reader.document_id == "diary", "Click red book opens diary")
	click(ui()._screen, Vector2(1290, 985))
	check(ui()._document_reader.page_index == 1 and ui()._document_reader._next.disabled, "Diary next page stops at last spread")
	click(ui()._screen, Vector2(630, 985))
	check(ui()._document_reader.page_index == 0 and ui()._document_reader._previous.disabled, "Diary previous returns to first spread")
	click(ui()._screen, Vector2(1615, 985))
	check(ui()._document_reader.zoom == 2.0, "Diary can be enlarged for reading")
	ui().toggle_pause()
	ui().toggle_pause()
	check(ui()._mode == "document" and ui()._document_reader.zoom == 2.0, "Pause resumes the same document")
	press(KEY_ESCAPE)
	check(ui()._mode == "evidence", "Diary Back returns to locker")
	click(ui()._screen, Vector2(1500,740))
	check(ui()._mode == "document" and ui()._document_reader.document_id == "student_card", "Locker provides actual student card artwork")
	press(KEY_ESCAPE)
	check(state.get_objective().contains("mading"), "Clues may be collected in either order")
	press(KEY_ESCAPE)
	await interact("Object/MadingInteractable")
	check(ui()._mode == "evidence" and state.has_clue("C2"), "Mading evidence retained")
	click(ui()._screen, Vector2(740, 425))
	check(ui()._mode == "document" and ui()._document_reader.document_id == "missing", "Missing-person poster is clickable")
	press(KEY_ESCAPE)
	click(ui()._screen, Vector2(947, 410))
	check(ui()._mode == "document" and ui()._document_reader.document_id == "ktm", "KTM announcement is clickable")
	check(not ui()._document_reader._next.visible, "Single poster hides page navigation")
	press(KEY_ESCAPE)
	press(KEY_ESCAPE)
	await interact("Object/MadingInteractable")
	press(KEY_ESCAPE)
	check(state.clues.size() == 3, "Repeated inspection does not duplicate clues")
	press(KEY_I)
	await process_frame
	check(ui()._mode == "inventory" and ui()._clue_list.get_child_count() == 3, "Inventory contains C1-C3")
	var saved_locker_button: Button = ui()._clue_list.get_child(1).get_child(2)
	saved_locker_button.pressed.emit()
	check(ui()._mode == "evidence", "Collected locker can be reopened from inventory")
	click(ui()._screen, Vector2(900, 640))
	check(ui()._mode == "document", "Diary can be reread from inventory")
	press(KEY_ESCAPE)
	press(KEY_ESCAPE)
	check(ui()._mode == "inventory" and state.clues.size() == 3, "Document navigation returns to inventory without new clues")
	press(KEY_ESCAPE)
	await interact("Object/PintuKeluarPortal")
	await settle()
	check(state.loop_count == 2 and ui()._mode == "play", "Later loops do not repeat opening or first-loop dialogue")
	check(state.clues.size() == 3, "Loop keeps investigation")
	await interact("Object/PintuGudangPortal")
	await settle()
	check(state.current_area == "gudang" and ui()._mode == "dialogue", "Gudang arrival dialogue")
	finish_dialogue()
	await interact("ClueCatatan")
	check(ui()._mode == "dialogue", "Old note is readable until continued")
	finish_dialogue()
	check(state.get_objective().contains("rekaman suara"), "Objective names remaining Gudang clue")
	await interact("ClueRekaman")
	check(ui()._dialogue_body.text.contains("Transkrip"), "Recording uses approved temporary transcript")
	finish_dialogue()
	await interact("PintuStudio")
	await settle()
	check(state.current_area == "studio_desain" and ui()._mode == "dialogue", "Studio arrival")
	finish_dialogue()
	await interact("ClueDokumentasi")
	check(ui()._mode == "finale" and not state.has_clue("C6"), "C6 requires connecting evidence")
	await process_frame
	await process_frame
	click(ui()._screen, Vector2(1180,598))
	check(state.deduction_step == 0 and not state.investigation_complete, "Incorrect deduction does not award C6")
	check(ui()._finale_screen._body.text.contains("Baca kembali C1"), "Incorrect deduction gives an evidence hint")
	await process_frame
	await process_frame
	click(ui()._screen, Vector2(1180,694))
	check(state.deduction_step == 1, "First deduction advances")
	press(KEY_I)
	check(ui()._mode == "inventory", "Evidence can be consulted during deduction")
	press(KEY_ESCAPE)
	check(ui()._mode == "finale", "Closing inventory resumes deduction")
	press(KEY_ESCAPE)
	check(ui()._mode == "play" and not state.has_clue("C6"), "Deduction can be cancelled without gaining clue")
	await interact("ClueDokumentasi")
	check(state.deduction_step == 1, "Solved deduction steps survive reopening")
	await process_frame
	await process_frame
	click(ui()._screen, Vector2(1180,790))
	await process_frame
	await process_frame
	click(ui()._screen, Vector2(1180,598))
	check(state.investigation_complete and state.get_objective().contains("Studio"), "C6 completes investigation in Studio")
	finish_dialogue()
	await create_timer(0.2).timeout
	check(state.current_area == "studio_desain" and state.finale_phase == "briefing", "Studio investigation starts chase briefing")
	finish_dialogue()
	await create_timer(0.1).timeout
	check(state.clues.size() == 6 and state.finale_phase == "chase", "Investigation continues into Ardi chase")
	await interact("PintuKembali")
	await settle()
	check(state.current_area == "gudang" and state.finale_phase == "chase", "Pursuit continues from Studio into Gudang")
	root.size = Vector2i(1024, 768)
	await process_frame
	await process_frame
	var stage: Control = ui()._screen
	var available := root.get_visible_rect().size
	var factor := minf(available.x / 1920.0, available.y / 1080.0)
	check(stage.scale.is_equal_approx(Vector2.ONE * factor), "UI scales with viewport")
	ui()._restart_run()
	await settle()
	check(state.clues.is_empty() and state.loop_count == 0 and not paused, "Restart clears story and clues")
	check(ui()._mode == "dialogue" and state.seen_story_events.size() == 1, "Restart replays opening only")
	print("STORY_FLOW_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
