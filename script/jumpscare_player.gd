extends Control
## Viewport overlay. The original Theora file is used without editing its pixels.
signal completed
var stream_path := "res://assets/ilustrasi/Karya_Seni_Tanpa_Judul.ogv"
var video: VideoStreamPlayer
var _fallback: TextureRect
var _active := false
var _elapsed := 0.0
var used_fallback := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = 3520.0 / 2488.0
	add_child(aspect)
	video = VideoStreamPlayer.new()
	video.expand = true
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.add_child(video)
	video.finished.connect(_finish)
	_fallback = TextureRect.new()
	_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fallback.texture = preload("res://assets/ilustrasi/IMG_3842.PNG")
	_fallback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fallback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fallback)
	hide()

func play() -> void:
	if _active: return
	_active = true
	_elapsed = 0
	used_fallback = false
	show()
	_fallback.hide()
	video.show()
	var stream: VideoStream
	if ResourceLoader.exists(stream_path): stream = load(stream_path) as VideoStream
	if stream != null:
		video.stream = stream
		video.play()
	else:
		_show_fallback()

func _process(delta: float) -> void:
	if not _active: return
	_elapsed += delta
	if used_fallback and _elapsed >= 1.8:
		_finish()
	elif not used_fallback and _elapsed >= 8.0:
		# Guard against missing/corrupt playback, never an endless black screen.
		push_warning("Jumpscare playback stalled; using existing illustration.")
		_show_fallback()

func _show_fallback() -> void:
	video.stop()
	video.hide()
	_fallback.show()
	used_fallback = true
	_elapsed = 0

func _finish() -> void:
	if not _active: return
	_active = false
	video.stop()
	hide()
	completed.emit()
