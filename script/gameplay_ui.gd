extends CanvasLayer
signal dialogue_finished
## One active modal. Artwork and controls are built once.
const Layout = preload("res://script/ui_layout.gd")
const Story = preload("res://script/story_data.gd")
const DocumentReader = preload("res://script/evidence_reader.gd")
const FinaleScreen = preload("res://script/finale_screen.gd")
const PORTRAITS := {
	"neutral": preload("res://assets/ilustrasi/IMG_3827.PNG"),
	"surprised": preload("res://assets/ilustrasi/IMG_3830.PNG"),
	"afraid": preload("res://assets/ilustrasi/IMG_3825.PNG"),
	"sad": preload("res://assets/ilustrasi/IMG_3829.PNG"),
	"ardi_ghost": preload("res://assets/ilustrasi/IMG_3845.PNG"),
}
const INVENTORY_ICON = preload("res://assets/button-dan-logo/INVENTORY BUTTON.png")
const PAUSE_ICON = preload("res://assets/button-dan-logo/PAUSE BUTTON.png")
const BACK_BUTTON = preload("res://assets/button-dan-logo/BACK.png")
const MADING = preload("res://assets/ui/MADING AJA.png")
const LOKER = preload("res://assets/ui/LOKER + BUKU.png")
const PAUSE_PATHS := {
	"labkom": "res://assets/ui/LABKOM PAUSE.png",
	"gudang": "res://assets/ui/GUDANG PAUSE.png",
	"studio_desain": "res://assets/ui/STUDIO PAUSE.png",
}
var clues: Array[Dictionary] = []
var inventory_open := false
var pause_open := false
var _mode := "play"
var _return_mode := "play"
var _screen: Control
var _hud: Control
var _shade: ColorRect
var _inventory_panel: PanelContainer
var _clue_list: VBoxContainer
var _prompt_label: Label
var _message_panel: PanelContainer
var _message_title: Label
var _message_body: Label
var _message_time_left := 0.0
var _evidence_overlay: Control
var _evidence_background: TextureRect
var _evidence_title: Label
var _evidence_body: Label
var _pause_overlay: Control
var _pause_background: TextureRect
var _busy := false
var _objective_label: Label
var _clock_label: Label
var _dialogue_panel: PanelContainer
var _dialogue_speaker: Label
var _dialogue_body: Label
var _dialogue_next: Button
var _dialogue_lines: Array = []
var _dialogue_index := 0
var _dialogue_portrait: TextureRect
var _portrait_cache: Dictionary = {}
var _document_reader: Control
var _document_return_mode := "evidence"
var _evidence_return_mode := "play"
var _evidence_targets: Control
var _finale_screen: Control
var _vignette: TextureRect
var _guidance_label: Label
var _inventory_goal: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("gameplay_ui")
	clues = GameState.clues.duplicate(true)
	_build_ui()
	_set_mode("play")
	GameState.progress_changed.connect(_refresh_progress)
	_refresh_progress()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if SceneTransition._transitioning:
		get_viewport().set_input_as_handled()
		return
	if _mode == "dialogue" and key in [KEY_E, KEY_ENTER, KEY_SPACE]:
		advance_dialogue()
		get_viewport().set_input_as_handled()
		return
	if key == KEY_ESCAPE:
		handle_escape()
		get_viewport().set_input_as_handled()
	elif key == KEY_I:
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif _mode != "play" and key in [KEY_E, KEY_W, KEY_A, KEY_S, KEY_D]:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _mode == "play":
		_update_guidance()
	if _mode == "play" and _message_time_left > 0.0:
		_message_time_left -= delta
		if _message_time_left <= 0.0:
			_message_panel.hide()

func _set_mode(mode: String) -> void:
	_mode = mode
	# Compatibility with Raka's existing movement/interactions lock.
	inventory_open = mode in ["inventory", "evidence", "dialogue", "document", "finale"]
	pause_open = mode == "pause"
	get_tree().paused = pause_open
	_hud.visible = mode == "play"
	_shade.visible = mode != "play"
	_shade.color.a = 0.35 if mode == "dialogue" else 0.98
	_dialogue_panel.visible = mode == "dialogue"
	_dialogue_portrait.visible = mode == "dialogue" and _dialogue_portrait.texture != null
	_document_reader.visible = mode == "document"
	_inventory_panel.visible = mode == "inventory"
	_evidence_overlay.visible = mode == "evidence"
	_pause_overlay.visible = mode == "pause"
	_finale_screen.visible = mode == "finale"
	_vignette.visible = mode == "play" and GameState.loop_count > 0
	_prompt_label.text = ""
	_message_panel.hide()

func toggle_inventory() -> void:
	if _busy or pause_open or _mode in ["dialogue", "finale"] or SceneTransition._transitioning:
		return
	if GameState.finale_phase == "chase":
		show_message("Ardi mendekat", "Cari lemari dahulu. Gunakan Esc jika ingin menjeda permainan.")
		return
	if _mode == "inventory":
		close_overlay()
	else:
		_rebuild_inventory()
		_set_mode("inventory")

func toggle_pause() -> void:
	# Pausing the tree during a door fade would stop the transition tween.
	if _busy or _mode == "finale" or SceneTransition._transitioning:
		return
	if pause_open:
		_set_mode(_return_mode)
	else:
		_return_mode = _mode
		_pause_background.texture = load(str(PAUSE_PATHS.get(GameState.current_area, PAUSE_PATHS["labkom"]))) as Texture2D
		_set_mode("pause")

func handle_escape() -> void:
	if _busy:
		return
	if pause_open:
		toggle_pause()
	elif _mode == "dialogue":
		toggle_pause()
	elif inventory_open:
		close_overlay()
	else:
		toggle_pause()

func close_overlay() -> void:
	if _busy or _mode in ["dialogue", "finale"]:
		return
	if _mode == "document":
		_set_mode(_document_return_mode)
		return
	if _mode == "evidence":
		_set_mode(_evidence_return_mode)
		return
	_set_mode("play")
	_return_mode = "play"

func set_interaction_prompt(prompt: String) -> void:
	_prompt_label.text = prompt if _mode == "play" else ""

func add_clue(clue_id: String, title: String, body: String) -> void:
	if _mode != "play" or SceneTransition._transitioning:
		return
	var blocked := GameState.clue_block_reason(clue_id)
	if not blocked.is_empty():
		show_message("Raka", blocked)
		return
	GameState.add_clue(clue_id, title, body)
	clues = GameState.clues.duplicate(true)
	if clue_id in ["C2", "C3"]:
		_show_evidence(clue_id, title, body, "play")
	else:
		show_dialogue(Story.clue_lines(clue_id, title, body))

func _show_evidence(clue_id: String, title: String, body: String, return_mode: String) -> void:
	_evidence_return_mode = return_mode
	_evidence_background.texture = MADING if clue_id == "C2" else LOKER
	_evidence_title.text = title
	_evidence_body.text = body + ("\nKlik poster untuk membaca lebih dekat." if clue_id == "C2" else "\nKlik buku merah untuk membaca diary.")
	for child in _evidence_targets.get_children():
		_evidence_targets.remove_child(child)
		child.queue_free()
	# Hit targets use normalized coordinates of the fitted artwork, not the viewport.
	var texture_size := _evidence_background.texture.get_size()
	var factor := minf(_evidence_background.size.x / texture_size.x, _evidence_background.size.y / texture_size.y)
	_evidence_targets.size = texture_size * factor
	_evidence_targets.position = _evidence_background.position + (_evidence_background.size - _evidence_targets.size) * 0.5
	if clue_id == "C2":
		_evidence_target(Rect2(0.25, 0.34, 0.16, 0.37), "missing", "Baca poster orang hilang")
		_evidence_target(Rect2(0.41, 0.30, 0.16, 0.40), "ktm", "Baca pengumuman KTM")
	else:
		_evidence_target(Rect2(0.39, 0.64, 0.13, 0.33), "diary", "Baca diary")
	_set_mode("evidence")

func _evidence_target(rect: Rect2, id: String, hint: String) -> void:
	_hotspot(_evidence_targets, Rect2(rect.position * _evidence_targets.size, rect.size * _evidence_targets.size), open_document.bind(id), hint)

func open_document(id: String) -> void:
	if _mode != "evidence" or not DocumentReader.DOCUMENTS.has(id):
		return
	_document_return_mode = _mode
	_document_reader.call("open_document", id)
	_set_mode("document")

func _inspect_saved_clue(clue: Dictionary) -> void:
	if _mode == "inventory":
		_show_evidence(str(clue["id"]), str(clue["title"]), str(clue["body"]), "inventory")

func play_story_event(event_id: String) -> void:
	var lines := Story.event_lines(event_id)
	if not lines.is_empty() and GameState.claim_story_event(event_id):
		show_dialogue(lines)

func show_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return
	_dialogue_lines = lines.duplicate(true)
	_dialogue_index = 0
	_set_mode("dialogue")
	_refresh_dialogue()

func _refresh_dialogue() -> void:
	var line: Dictionary = _dialogue_lines[_dialogue_index]
	var expression := str(line.get("portrait", "neutral" if line.get("speaker", "") == "Raka" else ""))
	_dialogue_portrait.texture = _portrait_texture(expression)
	_dialogue_portrait.visible = _dialogue_portrait.texture != null
	_dialogue_speaker.text = str(line.get("speaker", ""))
	_dialogue_body.text = str(line.get("text", ""))
	_dialogue_next.text = ("Selesai" if _dialogue_index == _dialogue_lines.size() - 1 else "Lanjut") + "  [E / Enter]"

func _portrait_texture(expression: String) -> Texture2D:
	if not PORTRAITS.has(expression):
		return null
	if not _portrait_cache.has(expression):
		var portrait := AtlasTexture.new()
		portrait.atlas = PORTRAITS[expression]
		# Display the upper body from the existing full-body canvas. PNG stays intact.
		portrait.region = Rect2(560, 580, 1430, 1750)
		if expression == "ardi_ghost":
			portrait.region = portrait.atlas.get_image().get_used_rect()
		_portrait_cache[expression] = portrait
	return _portrait_cache[expression] as Texture2D

func advance_dialogue() -> void:
	if _mode != "dialogue" or SceneTransition._transitioning:
		return
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_lines.size():
		_dialogue_lines.clear()
		_set_mode("play")
		dialogue_finished.emit()
	else:
		_refresh_dialogue()

func _refresh_progress() -> void:
	_objective_label.text = "Tujuan: " + GameState.get_objective()
	_inventory_goal.text = "Langkah berikutnya: " + GameState.get_objective() + "\nTutup inventori dengan I / Esc untuk melanjutkan."
	_clock_label.text = GameState.get_clock_text()

func _update_guidance() -> void:
	var player := get_tree().current_scene.get_node_or_null("Raka")
	if player == null: return
	if GameState.finale_phase == "chase" and bool(player.get("is_hidden")):
		_guidance_label.text = "Tetap bersembunyi... %d detik. Jangan tekan E dulu." % maxi(1,GameState.hidden_seconds)
		return
	var path := GameState.get_target_path()
	var target := get_tree().current_scene.get_node_or_null(path) as Node2D if not path.is_empty() else null
	if target == null:
		_guidance_label.text = ""
		return
	var delta: Vector2 = target.global_position - player.get_node("CollisionShape2D").global_position
	if delta.length() <= float(player.get("interaction_range")):
		_guidance_label.text = "Sudah dekat tujuan. Tekan E untuk berinteraksi."
	else:
		var horizontal := "kanan" if delta.x > 0 else "kiri"
		var vertical := "bawah" if delta.y > 0 else "atas"
		_guidance_label.text = "Arah tujuan: " + (vertical if absf(delta.x) < 80 else (horizontal if absf(delta.y) < 80 else horizontal + " " + vertical))

func show_finale(mode: String) -> void:
	_finale_screen.call("present", mode)
	_set_mode("finale")

func _finale_action(action: String) -> void:
	if _busy or _mode != "finale": return
	match action:
		"wait", "leave":
			if GameState.finale_phase != "choice": return
			GameState.choose_ending(action)
			show_finale("ending")
		"retry":
			if not GameState.restore_chase_checkpoint(): return
			_busy = true
			_set_mode("play")
			SceneTransition.change_scene("res://lab_komputer.tscn", "")
		"restart":
			_restart_run()
		"menu":
			_busy = true
			_set_mode("play")
			SceneTransition.change_scene("res://main_menu.tscn", "")

func show_message(title: String, body: String) -> void:
	_message_title.text = title
	_message_body.text = body
	_message_time_left = 5.0
	_message_panel.visible = _mode == "play"

func _build_ui() -> void:
	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.025, 0.035, 0.04, 0.98)
	add_child(_shade)
	_screen = Layout.new()
	add_child(_screen)
	_vignette = _texture(_screen, preload("res://assets/ui/EFEK VIGNETTE.png"), Rect2(0,0,1920,1080))
	_vignette.modulate.a = 0.25
	_hud = _control(_screen, Rect2(0, 0, 1920, 1080))
	var help := _label("E  Interaksi     I  Inventori     Esc  Jeda", 26)
	help.position = Vector2(40, 32)
	help.size = Vector2(1000, 50)
	_hud.add_child(help)
	_objective_label = _label("", 28)
	_objective_label.position = Vector2(40, 105)
	_objective_label.size = Vector2(1250, 90)
	_hud.add_child(_objective_label)
	_guidance_label = _label("", 24)
	_guidance_label.position = Vector2(40,200)
	_guidance_label.size = Vector2(1250,70)
	_hud.add_child(_guidance_label)
	_clock_label = _label("", 26)
	_clock_label.position = Vector2(1260, 35)
	_clock_label.size = Vector2(420, 60)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(_clock_label)
	_icon(_hud, INVENTORY_ICON, Rect2(1710, 28, 72, 72), toggle_inventory, "Inventori [I]")
	_icon(_hud, PAUSE_ICON, Rect2(1810, 28, 72, 72), toggle_pause, "Jeda [Esc]")
	_prompt_label = _label("", 30)
	_prompt_label.position = Vector2(280, 830)
	_prompt_label.size = Vector2(1360, 55)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_prompt_label)
	_message_panel = _panel(_hud, Rect2(260, 900, 1400, 150))
	var message := VBoxContainer.new()
	_message_panel.add_child(message)
	_message_title = _label("", 28)
	_message_body = _label("", 24)
	message.add_child(_message_title)
	message.add_child(_message_body)
	_inventory_panel = _panel(_screen, Rect2(340, 140, 1240, 800))
	var inventory := VBoxContainer.new()
	inventory.add_theme_constant_override("separation", 22)
	_inventory_panel.add_child(inventory)
	inventory.add_child(_label("Petunjuk yang terkumpul", 38))
	_inventory_goal = _label("",24)
	inventory.add_child(_inventory_goal)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory.add_child(scroll)
	_clue_list = VBoxContainer.new()
	_clue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_list.add_theme_constant_override("separation", 24)
	scroll.add_child(_clue_list)
	var back := Button.new()
	back.text = "Kembali"
	back.custom_minimum_size.y = 56
	back.pressed.connect(close_overlay)
	inventory.add_child(back)
	_evidence_overlay = _control(_screen, Rect2(0, 0, 1920, 1080))
	_evidence_background = _texture(_evidence_overlay, null, Rect2(180, 40, 1560, 740))
	_evidence_targets = _control(_evidence_overlay, Rect2())
	var caption := _panel(_evidence_overlay, Rect2(360, 810, 1200, 220))
	var evidence := VBoxContainer.new()
	caption.add_child(evidence)
	_evidence_title = _label("", 32)
	_evidence_body = _label("", 26)
	evidence.add_child(_evidence_title)
	evidence.add_child(_evidence_body)
	_icon(_evidence_overlay, BACK_BUTTON, Rect2(60, 940, 230, 80), close_overlay, "Kembali [Esc]")
	_document_reader = DocumentReader.new()
	_screen.add_child(_document_reader)
	_document_reader.connect("closed", close_overlay)
	_dialogue_portrait = _texture(_screen, null, Rect2(90, 210, 500, 500))
	_dialogue_panel = _panel(_screen, Rect2(200, 710, 1520, 330))
	var dialogue := VBoxContainer.new()
	dialogue.add_theme_constant_override("separation", 16)
	_dialogue_panel.add_child(dialogue)
	_dialogue_speaker = _label("", 32)
	_dialogue_body = _label("", 30)
	_dialogue_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_next = Button.new()
	_dialogue_next.custom_minimum_size = Vector2(360, 54)
	_dialogue_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	_dialogue_next.add_theme_font_size_override("font_size", 26)
	_dialogue_next.pressed.connect(advance_dialogue)
	dialogue.add_child(_dialogue_speaker)
	dialogue.add_child(_dialogue_body)
	dialogue.add_child(_dialogue_next)
	_pause_overlay = _control(_screen, Rect2(0, 0, 1920, 1080))
	_pause_background = _texture(_pause_overlay, null, Rect2(0, 0, 1920, 1080))
	# Labels already exist in the PNG. These buttons only supply hit targets.
	_hotspot(_pause_overlay, Rect2(1200, 400, 250, 70), toggle_pause, "Lanjutkan")
	_hotspot(_pause_overlay, Rect2(1200, 495, 250, 70), _restart_run, "Mulai ulang dari LABKOM")
	_hotspot(_pause_overlay, Rect2(1200, 590, 250, 70), _quit_game, "Keluar")
	_hotspot(_pause_overlay, Rect2(1785, 45, 80, 80), toggle_pause, "Lanjutkan")
	_hotspot(_pause_overlay, Rect2(1695, 45, 80, 80), _inventory_from_pause, "Inventori")
	_finale_screen = FinaleScreen.new()
	_screen.add_child(_finale_screen)
	_finale_screen.connect("action_selected", _finale_action)
	_rebuild_inventory()

func _inventory_from_pause() -> void:
	# A paused story conversation must be resumed, not discarded by the bag icon.
	if _return_mode == "dialogue":
		toggle_pause()
		return
	_set_mode("play")
	toggle_inventory()

func _control(parent: Node, rect: Rect2) -> Control:
	var control := Control.new()
	control.position = rect.position
	control.size = rect.size
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control

func _texture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var view := TextureRect.new()
	view.position = rect.position
	view.size = rect.size
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
	return view

func _icon(parent: Node, texture: Texture2D, rect: Rect2, callback: Callable, hint: String) -> void:
	var button := TextureButton.new()
	button.texture_normal = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = hint
	button.pressed.connect(callback)
	parent.add_child(button)

func _hotspot(parent: Node, rect: Rect2, callback: Callable, hint: String) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = hint
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	parent.add_child(button)

func _panel(parent: Node, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.085, 0.09, 0.98)
	style.border_color = Color(0.55, 0.50, 0.38)
	style.set_border_width_all(1)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.90, 0.79))
	return label

func _rebuild_inventory() -> void:
	for child in _clue_list.get_children():
		_clue_list.remove_child(child)
		child.queue_free()
	if clues.is_empty():
		_clue_list.add_child(_label("Belum ada petunjuk.", 28))
	for clue in clues:
		var entry := VBoxContainer.new()
		entry.add_child(_label(str(clue["id"]) + " - " + str(clue["title"]), 30))
		entry.add_child(_label(str(clue["body"]), 26))
		if str(clue["id"]) in ["C2", "C3"]:
			var inspect := Button.new()
			inspect.text = "Buka mading / poster" if str(clue["id"]) == "C2" else "Buka loker / diary"
			inspect.custom_minimum_size.y = 60
			inspect.add_theme_font_size_override("font_size", 26)
			inspect.pressed.connect(_inspect_saved_clue.bind(clue))
			entry.add_child(inspect)
		_clue_list.add_child(entry)

func _restart_run() -> void:
	if _busy:
		return
	_busy = true
	_set_mode("play")
	GameState.reset_run()
	SceneTransition.change_scene("res://lab_komputer.tscn", "")

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
