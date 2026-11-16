extends Node
## Small persistent state shared by the room scenes.
signal progress_changed

var clues: Array[Dictionary] = []
var pending_spawn_id: String = ""
var current_area: String = "labkom"
var loop_count: int = 0
var investigation_complete: bool = false
var seen_story_events: PackedStringArray = []
var finale_phase := "investigation"
var ending_id := ""
var hidden_seconds := 0
var checkpoint: Dictionary = {}
var restoring_checkpoint := false

func reset_run() -> void:
	clues.clear()
	pending_spawn_id = ""
	current_area = "labkom"
	loop_count = 0
	investigation_complete = false
	seen_story_events.clear()
	finale_phase = "investigation"
	ending_id = ""
	hidden_seconds = 0
	checkpoint.clear()
	restoring_checkpoint = false
	progress_changed.emit()

func has_clue(clue_id: String) -> bool:
	for clue in clues:
		if str(clue.get("id", "")) == clue_id:
			return true
	return false

func add_clue(clue_id: String, title: String, body: String) -> bool:
	if clue_id.is_empty() or has_clue(clue_id):
		return false
	clues.append({"id": clue_id, "title": title, "body": body})
	if clue_id == "C6":
		investigation_complete = true
	progress_changed.emit()
	return true

func claim_story_event(event_id: String) -> bool:
	if event_id.is_empty() or event_id in seen_story_events:
		return false
	seen_story_events.append(event_id)
	progress_changed.emit()
	return true

func enter_area(area_id: String) -> String:
	current_area = area_id
	progress_changed.emit()
	match area_id:
		"labkom":
			if investigation_complete:
				return "return_lab"
			if loop_count > 0:
				return "first_loop"
			if not has_clue("C1"):
				return "opening"
		"gudang":
			return "enter_gudang"
		"studio_desain":
			return "enter_studio"
	return ""

func record_loop() -> void:
	loop_count += 1
	progress_changed.emit()

func clue_block_reason(clue_id: String) -> String:
	if has_clue(clue_id):
		return ""
	if clue_id in ["C2", "C3"] and loop_count == 0:
		return "Periksa hasil training di laptop dulu." if not has_clue("C1") else "Laptop sudah diperiksa. Coba pintu keluar utama terlebih dahulu."
	return ""

func get_objective() -> String:
	match finale_phase:
		"briefing", "chase":
			return "Hindari Ardi. Dekati lemari LABKOM, tekan E, lalu tetap bersembunyi 5 detik."
		"escape":
			return "Keluar dari lemari dengan E, lalu menuju pintu keluar utama LABKOM."
		"choice":
			return "Pilih: menunggu Ardi atau pulang sendirian."
		"caught":
			return "Ulangi dari checkpoint sebelum pengejaran. Petunjukmu tetap tersimpan."
		"ending":
			return "Akhirnya Pulang" if ending_id == "wait" else "Pulang"
	if not has_clue("C1"):
		return "Periksa hasil training model di laptop LABKOM."
	if loop_count == 0:
		return "Coba pulang melalui pintu keluar utama LABKOM."
	if not has_clue("C2") and not has_clue("C3"):
		return "Cari informasi di mading dan loker LABKOM."
	if not has_clue("C2"):
		return "Periksa mading LABKOM."
	if not has_clue("C3"):
		return "Periksa loker LABKOM untuk mencari kartu mahasiswa."
	if not has_clue("C4") or not has_clue("C5"):
		if current_area != "gudang":
			return "Masuk ke Gudang melalui pintu antar-area LABKOM."
		if not has_clue("C4") and not has_clue("C5"):
			return "Cari rekaman suara dan catatan lama di rak Gudang."
		return "Cari rekaman suara di rak Gudang." if not has_clue("C4") else "Cari catatan lama di rak Gudang."
	if not has_clue("C6"):
		return "Periksa dokumentasi lama di Studio Desain." if current_area == "studio_desain" else "Lanjutkan ke Studio Desain melalui Gudang."
	if current_area != "labkom":
		return "Kembali ke LABKOM."
	return "Temui Ardi di LABKOM. Selesaikan percakapan untuk melanjutkan."

func set_finale_phase(phase: String) -> void:
	finale_phase = phase
	progress_changed.emit()

func save_chase_checkpoint(player_position: Vector2) -> void:
	checkpoint = {"clues": clues.duplicate(true), "loop_count": loop_count,
		"events": seen_story_events.duplicate(), "position": player_position}

func restore_chase_checkpoint() -> bool:
	if checkpoint.is_empty():
		return false
	clues.assign(checkpoint["clues"].duplicate(true))
	loop_count = int(checkpoint["loop_count"])
	seen_story_events = checkpoint["events"].duplicate()
	investigation_complete = has_clue("C6")
	finale_phase = "briefing"
	ending_id = ""
	hidden_seconds = 0
	restoring_checkpoint = true
	progress_changed.emit()
	return true

func choose_ending(choice: String) -> void:
	if finale_phase != "choice" or choice not in ["wait", "leave"]:
		return
	ending_id = choice
	set_finale_phase("ending")

func get_target_path() -> String:
	if finale_phase in ["briefing", "chase"]:
		return "Object/LemariInteractable"
	if finale_phase == "escape":
		return "Object/PintuKeluarPortal"
	match current_area:
		"labkom":
			if not has_clue("C1"): return "Object/LaptopInteractable"
			if loop_count == 0: return "Object/PintuKeluarPortal"
			if not has_clue("C2"): return "Object/MadingInteractable"
			if not has_clue("C3"): return "Object/LokerInteractable"
			if not investigation_complete: return "Object/PintuGudangPortal"
		"gudang":
			if not has_clue("C4"): return "ClueRekaman"
			if not has_clue("C5"): return "ClueCatatan"
			return "PintuStudio" if not investigation_complete else "PintuKembali"
		"studio_desain":
			return "ClueDokumentasi" if not has_clue("C6") else "PintuKembali"
	return ""

func get_clock_text() -> String:
	return "22.17 — Jam berhenti" if loop_count > 0 else "Malam hari"

func get_missing_clues(required_clues: PackedStringArray) -> PackedStringArray:
	var missing := PackedStringArray()
	for clue_id in required_clues:
		if not has_clue(clue_id):
			missing.append(clue_id)
	return missing

func get_clue_name(clue_id: String) -> String:
	match clue_id:
		"C1":
			return "hasil CCTV di laptop"
		"C2":
			return "informasi dari mading"
		"C3":
			return "kartu mahasiswa di loker"
		"C4":
			return "transkrip rekaman suara di Gudang"
		"C5":
			return "catatan lama di Gudang"
		"C6":
			return "dokumentasi di Studio Desain"
		_:
			return clue_id
