extends RefCounted
## Deductions use only facts already present in C1-C5; no new lore or arbitrary password.
const QUESTIONS := [
	{
		"question": "C1 — Apa yang membuat hasil CCTV ini janggal?",
		"options": ["Waktu training model terlalu lama", "Seseorang terlihat, tetapi hasilnya tidak mendeteksi orang", "Koridor terlihat kosong pada malam hari"],
		"answer": 1,
		"hint": "Baca kembali C1: bandingkan isi foto dengan hasil deteksi model."
	},
	{
		"question": "C2 + C3 — Bukti mana yang menghubungkan nama Ardi dengan kasus ini?",
		"options": ["Pengumuman kehilangan KTM saja", "Jam yang berhenti di 22.17", "Informasi mading dan identitas kartu mahasiswa"],
		"answer": 2,
		"hint": "Poster KTM adalah pengumuman umum. Cocokkan informasi mading C2 dengan kartu dari loker C3."
	},
	{
		"question": "C4 + C5 — Apa kaitan permintaan dalam rekaman dengan catatan lama?",
		"options": ["Ardi meminta ditunggu setelah tertinggal sendirian", "Ardi ingin mengambil laptop Raka", "Ardi sedang menunggu training model selesai"],
		"answer": 0,
		"hint": "Baca transkrip C4 dan catatan C5. Apa yang diminta, dan apa yang pernah terjadi pada Ardi?"
	},
]
static func is_correct(step: int, answer: int) -> bool:
	return step >= 0 and step < QUESTIONS.size() and answer == int(QUESTIONS[step]["answer"])
