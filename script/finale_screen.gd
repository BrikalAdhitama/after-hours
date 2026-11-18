extends Control
const Investigation = preload("res://script/investigation_data.gd")
signal action_selected(action: String)
var _title: Label
var _body: Label
var _art: TextureRect
var _raka: TextureRect
var _actions: VBoxContainer

func _ready() -> void:
	size = Vector2(1920,1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/button-dan-logo/AFTER HOURS WHITE.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(680,35)
	logo.size = Vector2(560,180)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	_art = _image(Rect2(90,200,470,750))
	_raka = _image(Rect2(350,320,340,630))
	_title = _label(44,Rect2(720,250,1050,90))
	_body = _label(30,Rect2(720,360,1000,260))
	_actions = VBoxContainer.new()
	_actions.position = Vector2(720,660)
	_actions.size = Vector2(940,280)
	_actions.add_theme_constant_override("separation",20)
	add_child(_actions)

func present(mode: String, feedback: String = "") -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	_raka.hide()
	_art.position = Vector2(130,210)
	_art.size = Vector2(480,740)
	_body.size.y = 260
	_actions.position.y = 660
	match mode:
		"deduction":
			var step: int = mini(GameState.deduction_step, Investigation.QUESTIONS.size() - 1)
			var question: Dictionary = Investigation.QUESTIONS[step]
			_title.text = "Hubungkan petunjuk %d / 3" % (step + 1)
			_body.size.y = 190
			_body.text = str(question["question"]) + ("\n\n" + feedback if not feedback.is_empty() else "\nPilih kesimpulan yang didukung bukti. I untuk membaca petunjuk.")
			_art.texture = preload("res://assets/ilustrasi/IMG_3828.PNG")
			_actions.position.y = 560
			for i in range(question["options"].size()):
				_action(str(question["options"][i]), "case_answer_" + str(i))
			_action("Baca petunjuk [I]", "case_read")
			_action("Kembali menelusuri ruangan [Esc]", "case_back")
			for button in _actions.get_children():
				button.add_theme_font_size_override("font_size",24)
		"caught":
			_art.position = Vector2(50,210)
			_art.size = Vector2(620,740)
			_title.text = "GAME OVER"
			_body.text = "Ulangi dari sesaat sebelum pengejaran. Semua petunjuk yang sudah tersimpan pada checkpoint tetap ada."
			_art.texture = preload("res://assets/ilustrasi/IMG_3842.PNG")
			_action("COBA LAGI", "retry")
			_action("MENU UTAMA", "menu")
		"choice":
			_title.text = "Pintu terakhir"
			_body.text = "Ardi masih meminta untuk ditunggu. Apa yang akan kamu lakukan?"
			_art.texture = preload("res://assets/ilustrasi/IMG_3845.PNG")
			_action("Tunggu Ardi", "wait")
			_action("Pergi Sendiri", "leave")
		"ending":
			_art.position = Vector2(70,220)
			_art.size = Vector2(300,700)
			_raka.position = Vector2(380,220)
			_raka.size = Vector2(300,700)
			var good := GameState.ending_id == "wait"
			_title.text = "Akhirnya Pulang" if good else "Pulang"
			_body.text = "Raka memilih menunggu dan menemani Ardi. Ardi akhirnya bisa pulang bersama Raka." if good else "Raka memilih keluar sendirian. Ardi kembali tertinggal dalam pengulangan malam yang sama."
			_art.texture = preload("res://assets/ilustrasi/IMG_3844.PNG") if good else preload("res://assets/ilustrasi/IMG_3849.PNG")
			_raka.texture = preload("res://assets/ilustrasi/IMG_3832.PNG") if good else preload("res://assets/ilustrasi/IMG_3829.PNG")
			_raka.show()
			_action("Main lagi dari awal", "restart")
			_action("Kembali ke menu", "menu")
	_art.texture = _trim(_art.texture)
	if _raka.visible:
		_raka.texture = _trim(_raka.texture)

func _trim(texture: Texture2D) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = texture.get_image().get_used_rect()
	return atlas

func _action(text: String, id: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 76
	button.add_theme_font_size_override("font_size",30)
	button.pressed.connect(func(): action_selected.emit(id))
	_actions.add_child(button)

func _label(font_size: int, rect: Rect2) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	add_child(label)
	return label

func _image(rect: Rect2) -> TextureRect:
	var view := TextureRect.new()
	view.position = rect.position
	view.size = rect.size
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	return view
