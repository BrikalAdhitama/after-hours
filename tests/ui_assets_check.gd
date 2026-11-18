extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func run() -> void:
	var sources := ""
	for file in DirAccess.get_files_at("res://script"):
		if file.ends_with(".gd"): sources += FileAccess.get_file_as_string("res://script/" + file) + "\n"
	var regex := RegEx.new()
	regex.compile('res://assets/ui/[^"\n]+\\.png')
	var checked := {}
	for found in regex.search_all(sources):
		var path := found.get_string()
		if checked.has(path): continue
		checked[path] = true
		check(ResourceLoader.exists(path) and FileAccess.file_exists(path), "UI reference resolves: " + path.get_file())
	var audit := "# Audit aset UI — 17 November 2026\n\nSemua PNG diperiksa dimensi, alpha dan tampilannya. File sumber tidak diubah. Gambar halaman utuh merupakan variasi, bukan panel tambahan yang harus ditumpuk.\n\n| File | Dimensi | Alpha | Pemakaian |\n| --- | --- | --- | --- |\n"
	for folder: String in ["res://assets/ui", "res://assets/button-dan-logo"]:
		for file in DirAccess.get_files_at(folder):
			if not file.to_lower().ends_with(".png"): continue
			var path := folder + "/" + file
			var picture := Image.new()
			picture.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
			check(picture != null and not picture.is_empty() and ResourceLoader.exists(path), "PNG loads/imported: " + file)
			if picture == null: continue
			var alpha: String = ["Opaque", "Transparansi biner", "Transparansi bertingkat"][picture.detect_alpha()]
			var usage := "Digunakan scene/script" if sources.contains(path) else "Variasi/cadangan; tidak ditumpuk"
			audit += "| " + path.trim_prefix("res://") + " | %d × %d | %s | %s |\n" % [picture.get_width(),picture.get_height(),alpha,usage]
	var file := FileAccess.open("res://docs/UI_ASSETS_AUDIT.md",FileAccess.WRITE)
	file.store_string(audit)
	var state := root.get_node("GameState")
	state.reset_run()
	state.seen_story_events.append("opening")
	change_scene_to_file("res://lab_komputer.tscn")
	await process_frame
	await process_frame
	var ui := get_first_node_in_group("gameplay_ui")
	for area in ["labkom","gudang","studio_desain"]:
		state.current_area = area
		ui.toggle_pause()
		check(ui._pause_background.texture != null and ui._pause_background.texture.resource_path.ends_with("(1).png"), "Updated pause art: " + area)
		ui.toggle_pause()
	ui.add_clue("C1","Hasil deteksi CCTV","Tidak ada orang")
	ui.advance_dialogue()
	ui.advance_dialogue()
	check(ui._mode == "evidence", "Laptop opens after dialogue")
	ui.open_document("ardi_photo")
	for size in [Vector2i(1280,720),Vector2i(1024,768)]:
		root.size = size
		await process_frame
		await process_frame
		var reader: Control = ui._document_reader
		var button: Button = reader._window_controls.get_child(1)
		var point := button.get_global_transform() * (button.size * 0.5)
		check(root.get_visible_rect().has_point(point), "Document X remains in viewport " + str(size))
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = true
		root.push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		root.push_input(event,true)
		check(ui._mode == "evidence", "Document X is clickable at " + str(size))
		ui.open_document("ardi_photo")
	ui.close_overlay()
	ui.close_overlay()
	ui.toggle_inventory()
	var entry: VBoxContainer = ui._clue_list.get_child(0)
	entry.get_child(2).pressed.emit()
	check(ui._mode == "evidence" and ui._evidence_background.texture.resource_path.ends_with("LAPTOP.png"), "Laptop reopens from inventory")
	ui.close_overlay()
	check(ui._mode == "inventory", "Laptop Back returns to originating inventory")
	print("UI_ASSETS_RESULT failures=" + str(failures))
	quit(1 if failures else 0)
