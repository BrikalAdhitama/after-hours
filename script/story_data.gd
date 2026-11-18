extends RefCounted
## Draft connective dialogue. Canonical facts: GDD Kel 1, pp. 2-3.
## Opening line and room/clue order follow the user's approved working design.
const EVENTS := {
	"opening": [
		{"speaker": "Raka", "text": "Akhirnya selesai juga training-nya. Ambil laptop, terus pulang."},
	],
	"first_loop": [
		{"speaker": "Raka", "text": "Aku... kembali ke laboratorium?"},
		{"speaker": "Raka", "text": "Jamnya berhenti di 22.17. Ponselku juga tidak mendapat sinyal."},
		{"speaker": "Raka", "text": "Harus cari tahu apa yang terjadi. Mungkin ada informasi di mading dan loker."},
	],
	"early_loop": [
		{"speaker": "Raka", "portrait": "afraid", "text": "Pintu ini membawaku kembali ke laboratorium? Aku belum memeriksa hasil training di laptop."},
	],
	"enter_gudang": [
		{"speaker": "Raka", "text": "Barang-barang lama disimpan di sini. Mungkin ada catatan yang bisa diperiksa."},
	],
	"enter_studio": [
		{"speaker": "Raka", "text": "Masih ada dokumentasi di studio yang perlu diperiksa."},
	],
	"studio_chase": [
		{"speaker": "Raka", "text": "Ardi tertinggal di sini... dan terus mengulang malam yang sama."},
		{"speaker": "Raka", "text": "Dia hanya meminta untuk ditunggu."},
		{"speaker": "Ardi", "portrait": "ardi_ghost", "text": "Tunggu aku..."},
		{"speaker": "Raka", "text": "Dia mendekat! Pintu masih bisa dipakai, tetapi dia bisa mengikuti. Aku harus memutus pandangannya, lalu mencapai pintu keluar laboratorium."},
	],
	"return_lab": [{"speaker": "Raka", "text": "Pintu keluar utama ada di sini."}],
	"retry_chase": [
		{"speaker": "Raka", "text": "Aku kembali ke sini. Petunjuknya masih ada. Aku harus berlindung di lemari."},
	],
}
const CLUE_REACTIONS := {
	"C1": "Modelnya bilang tidak ada orang. Tapi ada seseorang duduk di ujung koridor... Sebaiknya aku pulang.",
	"C4": "Suara itu meminta ditunggu. Siapa yang ditinggalkan?",
	"C5": "Seseorang tertinggal di gedung... Apakah ini berhubungan dengan rekaman itu?",
	"C6": "Dia terjebak dalam pengulangan malam ketika ditinggalkan. Aku harus kembali ke laboratorium.",
}
static func event_lines(event_id: String) -> Array:
	var lines: Array = EVENTS.get(event_id, []).duplicate(true)
	var expression := "neutral"
	if event_id == "first_loop":
		expression = "afraid"
	elif event_id == "studio_chase":
		expression = "sad"
	for line in lines:
		if not line.has("portrait"):
			line["portrait"] = expression
	return lines

static func clue_lines(clue_id: String, title: String, body: String) -> Array:
	var lines: Array = [{"speaker": title, "text": body}]
	# Raka remains visible while he examines the laptop's output, not only in his reply.
	if clue_id == "C1":
		lines[0]["portrait"] = "surprised"
	if CLUE_REACTIONS.has(clue_id):
		lines.append({"speaker": "Raka", "text": CLUE_REACTIONS[clue_id], "portrait": "surprised" if clue_id == "C1" else "sad"})
	return lines
