# Alur cerita — investigasi sampai dua ending

Status: alur dasar dapat dimainkan sampai dua ending. Pengejaran pertama memakai mekanik sederhana yang masih perlu penyesuaian kesulitan lewat playtest.
Sumber utama: `D:/AfterHours/GDD Kel 1 (1) (1).pdf`, terutama halaman 2–3.
Keputusan percakapan pengguna mengatur penempatan clue, urutan ruangan, loker untuk petunjuk, lemari untuk sembunyi, dan loop hanya pada pintu utama.

## Alur yang dapat dimainkan

| Peristiwa | Pemicu | Tujuan berikutnya |
| --- | --- | --- |
| Pembukaan di LABKOM | Start Game atau Restart | Periksa hasil training di laptop |
| C1: anomali CCTV | E di laptop; baca sampai Selesai | Coba pintu keluar utama |
| Loop pertama | E di pintu utama sesudah C1 | Periksa mading dan loker |
| C2: informasi Ardi; C3: kartu mahasiswa | E di mading/loker, urutan keduanya bebas | Masuk Gudang |
| Tiba di Gudang | C1–C3 dan loop pertama sudah dilalui | Cari rekaman suara dan catatan lama |
| C4: transkrip; C5: catatan lama | E di lokasi petunjuk Gudang, urutan bebas | Masuk Studio Desain |
| C6: dokumentasi | E di dokumentasi Studio | Kembali ke LABKOM |
| Kembali ke LABKOM | C6 terkumpul | Refleksi Raka, kemunculan Ardi, checkpoint sebelum pengejaran |
| Pengejaran | Dialog pertemuan selesai | Hindari Ardi, dekati lemari dan tekan E |
| Bersembunyi | Raka berada di dalam lemari selama 5 detik | Tekan E untuk keluar, lalu menuju pintu keluar utama |
| Pintu terakhir | Ancaman sudah dilewati; E di pintu utama | Pilih menunggu Ardi atau pulang sendirian |
| Akhirnya Pulang | Pilih menunggu | Raka dan Ardi pulang bersama |
| Pulang | Pilih pulang sendirian | Ardi tertinggal dalam pengulangan malam |

Sebelum waktunya, interaksi clue LABKOM/pintu memberi arahan tertulis.
Petunjuk tetap dapat dibaca ulang. Loop berikutnya mempertahankan clue dan tidak mengulang dialog pembukaan/loop pertama.
Penanda waktu HUD menjadi **22.17 — Jam berhenti** setelah loop pertama; sprite jam dinding belum dianimasikan.
C6 tidak langsung memutus loop; C6 membuka pertemuan terakhir setelah kembali ke LABKOM. Saat ancaman aktif, pintu mengarahkan pemain mencari lemari. Setelah lolos, pintu utama membuka keputusan akhir. Tidak ada lagi objective buntu yang hanya meminta membaca inventori.

## Penyajian dan kontrol

- Dialog native Control memakai panel bawah di UI yang sudah ada; ruangan tetap terlihat.
- E, Enter, Space, atau tombol Lanjut/Selesai melanjutkan dialog. Teks tidak hilang karena timer.
- Gerakan dan interaksi dunia terkunci selama dialog, memakai penguncian modal yang sudah dikenali Raka.
- Esc menjeda dialog; Continue melanjutkan halaman yang sama. I tidak membuang percakapan.
- Pemeriksaan mading/loker tetap memakai aset tim dan inventori yang sudah ada.
- Musik/audio tidak ditambahkan; rekaman suara masih berupa transkrip sementara.
- Progres bertahan sepanjang sesi dan perpindahan scene; belum ada save/load ke disk.
- HUD memberi arah menuju objek tujuan. Inventori menampilkan langkah berikutnya dan cara menutup inventori.
- Selama pengejaran, I tidak membuka inventori. Gunakan Esc untuk menjeda; timer persembunyian dan Ardi ikut berhenti.
- Jika tertangkap, pilih Ulangi dari checkpoint untuk mengulang dari sebelum pengejaran. Pilihan Restart dari pause atau Main lagi dari awal pada ending memulai run baru.

## Teks yang bersumber dari GDD

Fakta yang dipertahankan: Raka mengerjakan model deteksi orang; CCTV memperlihatkan seseorang tetapi hasilnya “Tidak ada orang”; foto berasal dari beberapa tahun lalu; laboratorium berulang; jam 22.17; telepon tidak mendapat sinyal; Ardi hilang setelah tertinggal di gedung dan terjebak pada pengulangan malam tersebut; ia meminta untuk ditunggu.

Monolog pembuka memakai kalimat pengguna: “Akhirnya selesai juga training-nya. Ambil laptop, terus pulang.”

## Draf yang perlu review penulisan

Dialog penghubung di `script/story_data.gd` adalah draf implementasi, bukan kutipan verbatim GDD:
- Reaksi Raka pada CCTV dan loop pertama.
- Arahan pemeriksaan mading/loker, Gudang, dan Studio.
- Reaksi pada C4–C6 dan refleksi sesudah kembali ke LABKOM.

Isi C1–C6 tetap berasal dari teks clue yang sudah ada pada scene. Teks catatan, dokumentasi, dan transkrip belum merupakan naskah final lengkap. Tidak ditambahkan nama baru, tanggal kejadian pasti, identitas pelaku, atau sebab kematian.

## Pengejaran dan batas implementasi

Ardi memakai tiga PNG cimol yang sudah tersedia. Jalur dibentuk dari hasil pemeriksaan capsule terhadap collision LABKOM yang sebenarnya. Kecepatan awal Ardi 135 world units/detik, lebih lambat dari Raka (180); spawn dipilih dari titik yang terhubung dan berjarak 500–1000 world units dari Raka.

Angka kecepatan, jarak spawn, dan durasi sembunyi 5 detik adalah parameter prototipe implementasi, bukan ketentuan GDD. Saat Raka bersembunyi, Ardi menuju lokasi terakhir yang diketahui. Keluar sebelum waktunya membatalkan hitungan sembunyi; setelah 5 detik, ancaman berakhir dan objective mengarahkan pemain ke pintu utama.

Checkpoint menyimpan keenam clue, loop_count, peristiwa yang sudah dilihat, dan posisi sebelum pengejaran di memori sesi. Tertangkap menampilkan ilustrasi IMG_3842.PNG dan tombol ulang. Kedua ending dipilih secara langsung, tanpa penilaian jumlah clue tambahan.

Belum ada: adegan visual CCTV, animasi jam, perubahan geometri lingkungan, respons AI terhadap suara/cahaya, audio, save/load ke disk, serta pemutaran video MP4. Vignette yang tersedia dipakai ringan setelah loop. Ilustrasi ending dan teks sudah ada; belum berupa cutscene animasi.

## File

- `script/story_data.gd`: naskah draf per peristiwa dan reaksi clue.
- `script/game_state.gd`: objective, penanda waktu, peristiwa sekali per sesi, syarat urutan awal.
- `script/gameplay_ui.gd`: panel dialog, kontrol lanjut/jeda, objective dan waktu HUD.
- `script/room_controller.gd`: memicu peristiwa saat tiba di ruangan.
- `script/portal.gd`: urutan laptop/loop dan perlindungan terhadap interaksi berulang saat fade.
- `script/ardi_chase.gd`: sprite dan navigasi pengejaran menggunakan collision aktual.
- `script/finale_controller.gd`: kemunculan, checkpoint, sembunyi, dan tertangkap.
- `script/finale_screen.gd`: layar tertangkap, keputusan, dan kedua ending.
- `tests/finale_flow_check.gd`: uji pengejaran, berjalan ke lemari/pintu, pengulangan checkpoint, serta ending buruk.
- `tests/story_flow_check.gd`: uji alur dan regresi UI melalui Godot CLI.

Layout ruangan, PNG, collision, movement, animasi, dan kamera tidak diubah.

## Validasi

Uji otomatis dengan Godot 4.7.2 menggunakan main menu, input E/I/Esc, klik tombol menu, dan transisi asli. Lokasi pemain dipindahkan oleh test agar berada dalam jangkauan interaksi; tes ini tidak membuktikan bahwa semua lokasi dapat dicapai dengan berjalan.

Hasil: 58 pemeriksaan alur cerita/UI dan 24 pemeriksaan pengejaran/checkpoint/ending lulus. Uji pengejaran menggerakkan Raka dengan move_and_slide melalui jalur physics, bukan memindahkan langsung ke lemari/pintu. Uji menangkap sengaja memposisikan Ardi di dekat Raka untuk memicu kegagalan. Lingkungan CLI mengeluarkan error pembacaan root certificate store Windows yang tidak menghalangi tes lokal.

Perintah:
```text
Godot --headless --path D:/AfterHours/after-hours --script res://tests/story_flow_check.gd --quit-after 3600
Godot --headless --path D:/AfterHours/after-hours --script res://tests/finale_flow_check.gd --quit-after 7200
```

Pengujian manual:
1. F5 → Start Game; baca monolog dan perhatikan objective.
2. Dekati laptop, E, lalu lanjutkan dialog sampai selesai.
3. Gunakan pintu keluar utama, baca reaksi loop; periksa penanda 22.17.
4. Periksa mading dan loker; coba I untuk membaca clue.
5. Pergi ke Gudang, periksa kedua clue, lalu ke Studio dan ambil C6.
6. Kembali ke LABKOM; selesai dialog, hindari Ardi. Ikuti arah HUD menuju lemari, E, dan tunggu 5 detik.
7. Sesudah suasana tenang, E untuk keluar dari lemari, lalu dekati pintu keluar utama dan tekan E. Coba kedua pilihan ending dalam run terpisah.
8. Biarkan tertangkap dalam pengujian lain. Pastikan Ulangi dari checkpoint mempertahankan petunjuk dan mengembalikan posisi sebelum pengejaran.
7. Saat dialog, coba Esc → Continue; saat gameplay coba Restart. Pastikan posisi panel, ukuran teks, dan akses objek nyaman pada ukuran jendela yang digunakan.

## Pembaca dokumen dan portrait

Sudah terhubung ke UI yang ada, tanpa mengubah layout/collision ruangan atau PNG:

| Aset | Pemakaian |
| --- | --- |
| IMG_3827.PNG | Portrait Raka netral pada pembukaan dan percakapan biasa |
| IMG_3830.PNG | Portrait Raka terkejut pada pemeriksaan hasil laptop C1 dan reaksinya |
| IMG_3825.PNG | Portrait Raka takut pada loop pertama |
| IMG_3829.PNG | Portrait Raka sedih pada refleksi dan reaksi petunjuk berikutnya |
| DIARY HAL 1 3.png, DIARY HAL 3 5.png | Dua bentang diary, dibuka dengan mengklik buku merah di tampilan loker |
| ORANG HILANG.png | Poster yang dibuka dari mading |
| POSTER KTM.png | Pengumuman kehilangan KTM yang dibuka dari mading; bukan pengganti kartu mahasiswa C3 |

Portrait memakai AtlasTexture untuk menampilkan gambar dari PNG asli; gambar tidak diedit. Portrait tidak tampil pada halaman dokumen atau inventori. Ardi muncul dengan kalimat singkat “Tunggu aku...” saat pertemuan terakhir, sesuai premis GDD.

Pembaca dokumen menyediakan Sebelumnya/Berikutnya untuk diary, Perbesar/Ukuran semula dan scrollbar untuk membaca tulisan kecil. Esc/Kembali mengembalikan pemain ke loker/mading asal. Inventori C2 dan C3 menyediakan tombol untuk membuka kembali mading/loker; kembali dari pemeriksaan itu menuju inventori.

Tulisan diary dan poster ditampilkan persis dari gambar tim; tidak disalin menjadi fakta cerita baru atau persyaratan progres tambahan. Membaca dokumen tidak menambah clue duplikat.

Perubahan file tambahan: `script/evidence_reader.gd` untuk pembaca dokumen reusable; `script/gameplay_ui.gd` untuk area klik, navigasi dan portrait; `script/story_data.gd` untuk ekspresi; `tests/story_flow_check.gd` untuk pengujian interaksi baru.

Tes visual manual tambahan: periksa diary dan dua poster dengan klik, uji tombol halaman serta zoom/scroll, buka ulang lewat I, dan pastikan portrait Raka tampak saat membuka laptop serta ketika melanjutkan reaksinya. Pengujian CLI memastikan state/input/texture yang dipilih; keterbacaan tulisan dan komposisi final masih perlu dilihat di jendela game.
