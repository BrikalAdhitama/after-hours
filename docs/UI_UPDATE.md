# Pembaruan UI — 17 November 2026

Ditemukan 28 PNG di assets/ui, termasuk 8 aset tambahan dibanding katalog sebelumnya. Aset lama dalam folder ini sudah tidak ada dengan nama sebelumnya; versi terbaru memakai akhiran `(1)`, termasuk `MADING (1) (1).png`. Script yang merujuk nama lama dapat gagal dimuat. Seluruh referensi UI pada script kini memakai nama file yang benar-benar tersedia. PNG tidak diganti nama atau diedit; import dilakukan oleh Godot CLI.

## Yang digunakan

- `HOME PAGE (1).png`: main menu; hotspot Start/Quit tetap mengikuti desain.
- `LABKOM PAUSE (1).png`, `GUDANG PAUSE (1).png`, `STUDIO PAUSE (1).png`: menu pause per ruangan.
- `MADING AJA (1).png`, `LOKER + BUKU (1).png`: layar pemeriksaan; poster dan diary tetap dapat diklik.
- `DIARY HAL 1 3 (1).png`, `DIARY HAL 3 5 (1).png`, `ORANG HILANG (1).png`, `POSTER KTM (1).png`: pembaca dokumen, halaman, zoom, dan kembali.
- `EFEK VIGNETTE (1).png`: efek yang sudah digunakan setelah loop.
- **LAPTOP.png**: ilustrasi saat monolog pemeriksaan C1 (bersebelahan dengan portrait Raka), kemudian tampilan lampiran interaktif. Foto/kartu dapat diklik. Save mengonfirmasi pencatatan clue di inventori sesi, Skip/Back menutup pemeriksaan; bukan save ke disk atau melompati investigasi.
- **ARDI IMAGE.png / KTM IMAGE.png**: foto dan kartu yang dapat diperbesar lewat pembaca dokumen yang sudah ada. Tombol persegi pada frame memperbesar; X kembali ke pemeriksaan asal. Kartu juga tersedia dari tombol Lihat kartu mahasiswa di layar loker.
- Inventori C1 memiliki tombol Buka laptop/lampiran. Menutupnya kembali ke inventori. C2/C3 tetap menyediakan mading/loker/diary.

Membaca lampiran laptop tidak memberikan C3 dan tidak mengubah objective atau fakta clue. C3 masih diperoleh dari loker. Tanggal/tulisan pada ilustrasi ditampilkan sesuai karya tim, tidak ditambahkan sebagai syarat puzzle baru.

## Variasi yang disimpan

`LAPTOP SCREEN.png`, `ARDI LAPTOP.png`, `KTM LAPTOP.png` adalah komposisi halaman utuh untuk aset yang sama. Versi terpisah dipakai supaya teks, portrait, dan kontrol tetap sesuai ukuran viewport. `LOKER UI (1).png`, halaman diary/poster utuh, mading utuh, dan pause transparan merupakan alternatif; tidak ditumpuk dengan panel aktif.

`LAMPU MATI.png` dan `LAMPU NYALA.png` merupakan variasi visual lampu/papan menu, belum dihubungkan dengan mekanik baru. Background menu yang dipakai sudah memuat papan/lampu. Tidak ada perubahan ruangan, collision, movement, AI, atau cerita hanya untuk memasukkan dekorasi ini. LOADING PAGE tetap cadangan.

## File berubah

- script/main_menu.gd: referensi artwork menu terbaru.
- script/gameplay_ui.gd: path UI, artwork dialog laptop, hotspot lampiran/Save/Skip/Back, tombol kartu di loker dan buka ulang laptop dari inventori.
- script/evidence_reader.gd: path dokumen terbaru, foto/kartu dan kontrol frame yang mengikuti skala gambar serta zoom.
- tests/story_flow_check.gd dan tests/ui_assets_check.gd: regresi alur, resource, klik, modal dan viewport.
- docs/ASSET_USAGE.csv serta UI_ASSETS_AUDIT.md: pemetaan dan metadata PNG terkini.

## Pengujian manual

1. Muat ulang perubahan dari disk jika diminta Godot, tunggu import selesai, lalu F5 → Start Game.
2. Dekati laptop, E. Portrait Raka dan laptop harus tampil bersama. Selesaikan dialog, klik foto/kartu, coba perbesar dan X. Back/Esc kembali ke ruangan.
3. Buka I, pilih Buka laptop/lampiran, lalu Back: kembali ke inventori.
4. Setelah loop, periksa loker: klik buku merah dan tombol Lihat kartu mahasiswa. Periksa kedua poster di mading.
5. Coba Esc di setiap ruangan dan ukuran jendela 16:9/4:3. Pastikan teks dan area klik nyaman; komposisi visual akhir masih memerlukan pemeriksaan di jendela game.

Audit dimensi/transparansi ada pada UI_ASSETS_AUDIT.md. Pengujian otomatis menggunakan Godot 4.7.2 headless; log berada di D:/AfterHours/ui-update-*.log. Root certificate store dan editor-settings di luar workspace masih menghasilkan pesan lingkungan sandbox; tidak ada kegagalan load PNG/GDScript pada pemeriksaan akhir.

Hasil akhir: **159 pemeriksaan lulus, 0 gagal** — 70 alur cerita/UI, 60 aset/menu/viewport, 29 video/checkpoint/ending. Kontrol lampiran diuji dengan klik aktual pada viewport 1280×720 dan 1024×768. Tampilan artistik dan keterbacaan tetap memerlukan playtest visual.
