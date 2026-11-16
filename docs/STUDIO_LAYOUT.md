# Studio Desain — pemasangan background asli

## Perubahan

- `studio_desain.tscn` memakai `assets/studiodesain/LATAR BELAKANG STUDIO.png` (5822 × 4414) pada scale 0.5. Ukuran world 2911 × 2207 setara background LABKOM; PNG tidak diedit.
- Polygon placeholder WallLeft, WallRight, dan Floor diganti background asli.
- Empat meja studio membentuk kelompok kerja di tengah, dengan lorong terbuka. Lemari, loker, rak, meja panjang, IFP, dan dispenser mengikuti tepi lantai. Board dipasang pada dinding.
- Semua furnitur lama dipertahankan. Origin setiap furnitur berada di pijakan; sprite memakai offset terukur dari PNG. Root Studio dan Props menggunakan Y-sort agar furnitur dan Raka tersortir bersama.
- Collision baru memakai StaticBody2D dan polygon pijakan, termasuk area kursi bawaan gambar meja. Tidak menggunakan seluruh tinggi sprite sebagai collider.
- Empat strip collision membatasi lantai, dengan sambungan overlap pada sudut.
- Pintu, marker interaksi, Raka, dan spawn DariGudang dipindahkan ke sisi kiri ruangan. Kamera, ukuran karakter, dan script movement tidak diubah.
- ClueDokumentasi C6 berada di depan meja dosen. Syarat C6 untuk kembali ke LABKOM tetap berlaku.

Koordinat lantai world setelah transform background:
(-1405.5, 21.5), (-205.5, -668.5), (1404.5, 256.5), (194.5, 953.5).

## Validasi

Godot 4.7.2 berhasil mengimpor PNG baru. Tes physics yang sebelumnya untuk Gudang diperluas dengan argumen --studio agar pemeriksaan capsule dan pencarian jalur tidak diduplikasi.

```text
Godot --headless --path D:/AfterHours/after-hours --script res://tests/gudang_physics_check.gd -- --studio
Godot --headless --path D:/AfterHours/after-hours --script res://tests/story_flow_check.gd
```

Hasil: 44 pemeriksaan physics Studio dan 56 pemeriksaan alur cerita/UI lulus. Physics meliputi pijakan furniture, batas lantai, ruang bebas spawn/pintu/C6, dan jalur yang terhubung memakai capsule Raka serta swept test_move.

Preview komposisi diperiksa dari gambar dengan transform scene; bukan screenshot runtime Godot. Keterbacaan visual dan kenyamanan berjalan tetap memerlukan pengujian manual.

CLI mencatat masalah sertifikat Windows dan izin penyimpanan pengaturan editor di luar workspace; impor aset dan tes lokal tetap selesai. Folder .godot hanya dikelola oleh engine.

## Tes manual

1. Stop game, reload scene dari disk jika editor menanyakan, lalu F5.
2. Lanjutkan dari LABKOM dan Gudang sampai masuk Studio.
3. Pastikan Raka muncul di dekat pintu kiri dan dapat berjalan melalui lorong di antara meja.
4. Coba menabrak furniture dan keempat tepi lantai; lihat urutan gambar ketika Raka melewati depan/belakang objek.
5. Dekati meja dosen di belakang-tengah, tekan E untuk C6, lalu kembali melalui pintu kiri.

File yang diubah: studio_desain.tscn, tests/gudang_physics_check.gd, serta dokumen ini. File .import untuk background baru dihasilkan oleh Godot.
