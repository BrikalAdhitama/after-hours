extends Control
## Reusable reader for the team's isolated artwork; no baked UI controls.
signal closed
const DOCUMENTS := {
	"diary": {"title": "Diary", "pages": ["res://assets/ui/DIARY HAL 1 3 (1).png", "res://assets/ui/DIARY HAL 3 5 (1).png"]},
	"missing": {"title": "Poster orang hilang", "pages": ["res://assets/ui/ORANG HILANG (1).png"]},
	"ktm": {"title": "Pengumuman KTM hilang", "pages": ["res://assets/ui/POSTER KTM (1).png"]},
	"student_card": {"title": "Kartu mahasiswa Ardi", "pages": ["res://assets/ui/KTM IMAGE.png"]},
	"ardi_photo": {"title": "Foto Ardi", "pages": ["res://assets/ui/ARDI IMAGE.png"]},
}
var document_id := ""
var page_index := 0
var zoom := 1.0
var _pages: Array = []
var _view: TextureRect
var _scroll: ScrollContainer
var _title: Label
var _page_label: Label
var _previous: Button
var _next: Button
var _zoom_button: Button
var _window_controls: Control

func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = Label.new()
	_title.position = Vector2(300, 20)
	_title.size = Vector2(1320, 55)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(160, 90)
	_scroll.size = Vector2(1600, 810)
	add_child(_scroll)
	_view = TextureRect.new()
	_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_scroll.add_child(_view)
	_window_controls = Control.new()
	_window_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_window_controls)
	_window_button(Rect2(0.872,0.027,0.05,0.076), toggle_zoom, "Perbesar / ukuran semula")
	_window_button(Rect2(0.927,0.027,0.05,0.076), func(): closed.emit(), "Tutup lampiran")
	_view.resized.connect(_fit_window_controls)
	_button("Kembali [Esc]", Rect2(160, 955, 290, 65), func(): closed.emit())
	_previous = _button("Sebelumnya", Rect2(500, 955, 260, 65), turn_page.bind(-1))
	_page_label = Label.new()
	_page_label.position = Vector2(785, 955)
	_page_label.size = Vector2(350, 65)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_size_override("font_size", 26)
	add_child(_page_label)
	_next = _button("Berikutnya", Rect2(1160, 955, 260, 65), turn_page.bind(1))
	_zoom_button = _button("Perbesar", Rect2(1470, 955, 290, 65), toggle_zoom)

func open_document(id: String) -> void:
	if not DOCUMENTS.has(id):
		return
	document_id = id
	page_index = 0
	zoom = 1.0
	_pages = DOCUMENTS[id]["pages"]
	_title.text = DOCUMENTS[id]["title"]
	_update_page()

func turn_page(direction: int) -> void:
	page_index = clampi(page_index + direction, 0, _pages.size() - 1)
	_update_page()

func toggle_zoom() -> void:
	zoom = 2.0 if zoom == 1.0 else 1.0
	_update_page()

func _update_page() -> void:
	_view.texture = load(str(_pages[page_index])) as Texture2D
	_view.custom_minimum_size = Vector2(1580, 790) * zoom
	_view.size = _view.custom_minimum_size
	_previous.disabled = page_index == 0
	_next.disabled = page_index == _pages.size() - 1
	_previous.visible = _pages.size() > 1
	_next.visible = _pages.size() > 1
	_page_label.text = "Bentang %d / %d" % [page_index + 1, _pages.size()] if _pages.size() > 1 else ""
	_zoom_button.text = "Ukuran semula" if zoom > 1.0 else "Perbesar"
	_scroll.set_deferred("scroll_horizontal", 0)
	_scroll.set_deferred("scroll_vertical", 0)
	_fit_window_controls()

func _fit_window_controls() -> void:
	_window_controls.visible = document_id in ["student_card", "ardi_photo"]
	if _view.texture == null: return
	var image_size := _view.texture.get_size()
	var factor := minf(_view.size.x / image_size.x, _view.size.y / image_size.y)
	_window_controls.size = image_size * factor
	_window_controls.position = (_view.size - _window_controls.size) * 0.5

func _window_button(rect: Rect2, action: Callable, hint: String) -> void:
	var button := Button.new()
	button.flat = true
	button.tooltip_text = hint
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_window_controls.add_child(button)
	button.anchor_left = rect.position.x
	button.anchor_top = rect.position.y
	button.anchor_right = rect.end.x
	button.anchor_bottom = rect.end.y
	button.pressed.connect(action)

func _button(text: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(action)
	add_child(button)
	return button
