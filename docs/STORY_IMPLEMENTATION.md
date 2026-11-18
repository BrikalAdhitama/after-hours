# Implementasi revisi gameplay — 17 November 2026

Acuan cerita: `D:/AfterHours/GDD Kel 1 (1) (1).pdf`. Revisi pengguna terbaru mengganti batas pengejaran dalam lampiran: **mulai di Studio, lalu Ardi dapat mengikuti ke semua ruangan**. Loker tetap untuk petunjuk, lemari untuk persembunyian, dan loop hanya di pintu utama.

## Perubahan yang diterapkan

| File | Perubahan |
| --- | --- |
| `lab_komputer.tscn` | Collider enam meja komputer dan dua lemari depan mengikuti pijakan; dua titik persembunyian depan; titik interaksi mading/loker/lemari dan pintu digeser ke sisi lantai yang terjangkau; marker spawn di dekat pintu. Posisi/ukuran/tekstur seluruh sprite dan kamera dipertahankan. |
| `gudang.tscn` | Kedua portal menjadi Area2D; syarat clue pintu dihapus. Layout dan collision dipertahankan. |
| `studio_desain.tscn` | Portal Area2D menuju Gudang sebagai pasangan rute masuk; syarat clue pintu dihapus; marker persembunyian di depan lemari yang sudah ada. Layout/collision dipertahankan. |
| `script/portal.gd` | Area2D lingkaran radius 160, overlap Raka + E, bebas clue gate, fade yang sudah ada, meneruskan pengejaran lewat pintu dan menguji pintu akhir. |
| `script/room_controller.gd` | Spawn berdasar kaki, bukan origin body LABKOM yang bergeser (454,-15); controller pengejaran di tiap ruangan; poligon lantai aktual untuk sampling navigasi. |
| `script/raka.gd` | Validasi jangkauan Area pintu, kunci input/gerak selama fade, simpan titik keluar lemari dan cek capsule physics sebelum keluar. Rumus movement/orientasi, animasi, dan kamera dipertahankan. |
| `script/interactable.gd` | Sistem hide reusable yang sama menerima lemari sumber. |
| `script/game_state.gd` | Objective bebas pintu; C6 memerlukan bukti C1–C5; trigger Studio; status/transisi ancaman; checkpoint menyimpan scene, posisi, clue, event, loop, dan deduksi. Timer kemenangan bersembunyi lama dihapus. |
| `script/ardi_chase.gd` | Navigasi AStar2D dibangun dari capsule sweep dan collision tiap ruangan. State CHASE/SEARCH/PATROL (IDLE jika tidak ada jalur), target terakhir hanya diperbarui saat benar-benar melihat Raka. Repath tidak menarik Ardi mundur ke titik grid lama. |
| `script/finale_controller.gd` | Trigger sekali pada progres Studio, checkpoint sebelum ancaman, kedatangan lintas ruangan, pencarian aktif saat sembunyi, kondisi lolos, penangkapan sekali. |
| `script/gameplay_ui.gd` | Status ancaman, modal jumpscare, retry ke checkpoint Studio, memakai UI lama. |
| `script/jumpscare_player.gd` | VideoStreamPlayer pada CanvasLayer UI, rasio dipertahankan, finished ke Game Over, fallback ilustrasi jika aset tidak tersedia/stall. |
| `script/finale_screen.gd` | Game Over: COBA LAGI / MENU UTAMA. Ending: Tunggu Ardi / Pergi Sendiri. |
| `script/story_data.gd` | Percakapan pemicu dipindah ke Studio; arahan awal/antar-area sesuai pintu bebas, tanpa penambahan fakta masa lalu Ardi. |
| `tests/*_check.gd` | Tes akses/lemari, AI lintas ruangan, story/UI, video/checkpoint/ending sesuai aturan terbaru. |

Garis diagonal depan LABKOM mengikuti tepi lantai isometrik dan dipertahankan. Keempat sisi diuji menggunakan gerakan capsule. Collider furnitur yang masih berfungsi dan layout manual tidak dibuang. PNG tidak diubah. SceneTransition fade yang sudah ada digunakan kembali; tidak ada plugin, musik, commit, atau push baru.

## Aturan runtime

- Rute pintu berpasangan: LABKOM ↔ Gudang ↔ Studio. Marker menyatakan posisi kaki dalam koordinat room, memperhitungkan parent dan offset shape LABKOM.
- Tidak ada teleport dari body_entered. Hanya E baru; echo ditolak dan fade mengunci kontrol. Radius Area 160 konsisten dengan jangkauan interaksi Raka 180.
- C1–C6, loop pertama, dan penyelesaian dialog investigasi di Studio memulai ancaman. Kunjungan Studio awal aman. C6 tidak memutus loop.
- Ardi bergerak 155 saat mengejar, 125 saat mencari, 85 saat patroli; Raka tetap 180. Deteksi memakai jarak 360 dan ray tanpa halangan. Navigasi sampling 40 unit; node dan koneksi diuji dengan collision capsule.
- Saat tersembunyi, sprite Raka disembunyikan dan tidak menjadi target deteksi/tangkap. Ardi tetap menuju posisi terakhir yang terlihat, mencari, lalu patroli setelah 9 detik tanpa sight. Posisi tersembunyi tidak memperbarui ingatannya. Setelah keluar, sight dapat memulai CHASE kembali.
- Pindah ruangan menyimpan status dan waktu tempuh; Ardi muncul di dekat pintu masuk tujuan setelah 2,5–7 detik. Ia mencari titik masuk, bukan koordinat pemain yang terus bergerak. Tidak ada reset investigasi/pengejaran setiap masuk Studio.
- Lolos: di LABKOM, Ardi sudah tiba, berada dalam PATROL, dan tidak melihat Raka ketika E pada pintu utama. Jika belum, pintu mengulang LABKOM beserta ancamannya. Ketika lolos, ancaman berhenti dan kedua pilihan ending dibuka.
- Tertangkap: phase caught segera mencegah tangkap ganda, video mengunci kontrol sampai finished, kemudian Game Over. Retry memulihkan checkpoint Studio beserta semua petunjuk. Ending tidak dipicu oleh tangkap.
- Save/checkpoint masih di memori sesi; belum menyimpan ke disk.

Durasi pencarian, kecepatan, jeda kedatangan, radius deteksi, dan kriteria lolos adalah parameter implementasi untuk playtest, bukan fakta cerita dari GDD. Dialog penghubung tetap draf. Tidak ada cerita kematian/identitas baru yang ditambahkan.

## Video yang benar-benar tersedia

Audit filesystem terbaru menemukan `assets/ilustrasi/Karya_Seni_Tanpa_Judul.ogv`, bukan MP4 yang disebut dalam audit lama. FFprobe dari instalasi lokal memverifikasi container **ogg**, codec **theora**, **3520×2488**, **12 fps**, **2,916667 detik**, **159.218 byte**, satu stream video dan **tanpa stream audio**. Jadi file ini bukan MP4 yang hanya diganti ekstensi. Tidak perlu konversi; file sumber tidak diubah/dihapus. Program pemeriksa diekstrak dari paket FFmpeg Android Studio yang sudah terpasang ke direktori validasi di luar project, tanpa download/dependency runtime.

VideoStreamPlayer Godot berhasil memuat dan memutar sampai sinyal finished. Fallback `IMG_3842.PNG` selama 1,8 detik diuji dengan path video yang sengaja tidak ada; watchdog 8 detik mencegah layar macet jika pemutaran rusak. Video memakai rasio asli di atas latar hitam, terikat viewport dan tidak mengikuti Camera2D.

## Validasi dan batasnya

Godot **4.7.2**, headless:

- `tests/revision_access_check.gd`: geometri spawn, flood-fill akses interaksi di tiga ruangan, empat batas lantai per ruangan, portal tanpa clue, E tanpa teleport berulang, semua lemari masuk/keluar aman dan tahan key echo.
- `tests/revision_chase_check.gd`: Studio awal tidak memicu ancaman; C6 memicu saat sudah di dalam; navigasi tiap ruangan; pencarian/patroli tetap bergerak; tidak melacak posisi tersembunyi; deteksi ulang; status mengikuti Studio → Gudang → LABKOM.
- `tests/story_flow_check.gd`: main menu, C1–C6, loop, diary/poster, portrait laptop/dialog, inventori, deduksi, transisi, reset, viewport.
- `tests/finale_flow_check.gd`: proximity catch, video native benar-benar advancing/finished, input lock, fallback, klik Game Over, checkpoint Studio, loop saat belum lolos, jalan ke pintu terakhir dengan move_and_slide, klik kedua ending, restart.
- `tests/gudang_physics_check.gd` (normal dan `--studio`): footprint furnitur, batas lantai, akses central aisle.

Tes alur memakai pemindahan posisi dekat objek agar efisien; tes akses memeriksa konektivitas dengan collision aktual. Tes akhir benar-benar menjalankan move_and_slide ke pintu, tetapi mengendalikan state/posisi Ardi untuk memisahkan pengujian kondisi berhasil. Ini belum membuktikan keseimbangan kesulitan pada permainan manusia. Tampilan visual, layering sprite, keterbacaan dan rasa pengejaran tetap memerlukan F5/playtest; panduan ada di GAMEPLAY_GUIDE.md.

Lingkungan sandbox memberi error root certificate Windows; editor CLI juga tidak bisa menyimpan editor settings di luar workspace. Keduanya terpisah dari script/scene, tes runtime tetap selesai. Tidak ada klaim bahwa screenshot/render visual telah diuji.

Perintah (ganti `Godot` dengan executable lokal):

```text
Godot --headless --path D:/AfterHours/after-hours --script res://tests/revision_access_check.gd --quit-after 5000
Godot --headless --path D:/AfterHours/after-hours --script res://tests/revision_chase_check.gd --quit-after 8000
Godot --headless --path D:/AfterHours/after-hours --script res://tests/story_flow_check.gd --quit-after 8000
Godot --headless --path D:/AfterHours/after-hours --script res://tests/finale_flow_check.gd --quit-after 12000
Godot --headless --path D:/AfterHours/after-hours --script res://tests/gudang_physics_check.gd --quit-after 5000
Godot --headless --path D:/AfterHours/after-hours --script res://tests/gudang_physics_check.gd --quit-after 5000 -- --studio
```

Pemakaian aset UI/portrait sebelumnya tetap: HOME PAGE, pause per area, ikon tas/pause, MADING AJA, LOKER + BUKU, dua bentang diary, ORANG HILANG, POSTER KTM, portrait Raka, dan ilustrasi dua ending. Alternatif PNG satu halaman tidak ditumpuk di atas halaman yang sudah aktif. ASSET_USAGE.csv diperbarui untuk video OGV.

Hasil akhir revisi: **273 pemeriksaan lulus, 0 gagal** (akses/lemari 74; AI 34; cerita/UI 60; finale/video 29; Gudang 32; Studio 44). Log validasi berada di `D:/AfterHours/revision-*.log`. Tes tambahan memastikan pintu utama dapat dicoba sebelum laptop tanpa mengubah objective awal, serta melewati Raka yang tersembunyi tidak memicu tangkap di ketiga ruangan.
