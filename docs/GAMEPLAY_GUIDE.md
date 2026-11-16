# Setelah membaca inventori, harus ke mana?

Inventori adalah tempat membaca ulang petunjuk, bukan tujuan akhir misi. Bagian atas inventori sekarang selalu menunjukkan langkah berikutnya. Tutup dengan I/Esc, lalu ikuti tujuan dan arah yang muncul di HUD.

## Alur pemain

1. **LABKOM:** periksa laptop dengan E. Baca hasil CCTV sampai selesai.
2. **Pintu keluar utama:** coba pulang; Raka kembali ke LABKOM. Waktu menunjukkan 22.17.
3. **LABKOM:** periksa mading dan loker. Kartu mahasiswa diperoleh dari loker; buku merah dan dua poster bisa diklik untuk dibaca.
4. **Gudang:** setelah C1–C3, gunakan pintu Gudang. Cari transkrip rekaman suara dan catatan lama pada rak.
5. **Studio Desain:** setelah C4–C5, gunakan pintu Studio. Periksa dokumentasi di meja dosen.
6. **Kembali ke LABKOM:** sesudah C6, gunakan pintu kembali. Baca percakapan hingga selesai; Ardi muncul dan mengejar.
7. **Lemari:** hindari Ardi, dekati lemari sampai prompt muncul, tekan E untuk bersembunyi. Tetap di dalam selama 5 detik. Hitungan berhenti saat pause.
8. **Pintu akhir:** setelah objective berubah, tekan E untuk keluar dari lemari. Datangi pintu keluar utama LABKOM dan tekan E.
9. **Pilih ending:** Menunggu Ardi → Akhirnya Pulang. Pulang sendirian → Pulang.

Jika tertangkap, pilih **Ulangi dari checkpoint**. Petunjuk yang sudah dikumpulkan tetap ada. Checkpoint hanya berlaku dalam sesi berjalan; menutup aplikasi belum menyimpan progres ke disk.

## Pemakaian aset

Daftar semua 104 file PNG/MP4 di folder assets ada di [ASSET_USAGE.csv](ASSET_USAGE.csv). 75 PNG direferensikan scene/script. Semua aset telah dipetakan statusnya; tidak semua variasi harus tampil bersamaan.

| Bagian permainan | Aset yang digunakan |
| --- | --- |
| Menu, pause, inventori | HOME PAGE, pause per ruangan, ikon tas/pause, BACK |
| Pemeriksaan | MADING AJA, LOKER + BUKU, dua poster, dua bentang diary |
| Eksplorasi | Background dan furniture LABKOM/Gudang/Studio; empat arah Raka |
| Monolog dan laptop | Ilustrasi Raka netral, terkejut, takut, sedih |
| Setelah loop | EFEK VIGNETTE dengan intensitas ringan |
| Pengejaran | ARDI BELAKANG, ARDI KANAN DEPAN, ARDI KIRI DEPAN |
| Pertemuan/pilihan | IMG_3845 (Ardi), AFTER HOURS WHITE |
| Tertangkap | IMG_3842 |
| Good Ending | IMG_3844 (Ardi), IMG_3832 (Raka) |
| Bad Ending | IMG_3849 (Ardi), IMG_3829 (Raka) |

Halaman UI lengkap yang memuat tombol bawaan tetap merupakan alternatif terhadap versi objek terpisah; menumpuk keduanya menyebabkan masalah UI sebelumnya. Tiga variasi ekspresi belum dipilih untuk adegan. Dua belas aset ruangan cadangan tidak dipaksakan masuk ke layout yang sudah rapi. MP4 tersedia, tetapi pipeline pemutarannya belum divalidasi; adegan tertangkap memakai ilustrasi yang tersedia. Audio belum tersedia dan musik tidak ditambahkan.

## Hal yang perlu dicoba manual

- Kejelasan arah HUD dan jarak munculnya prompt E pada lemari/pintu.
- Apakah kecepatan Ardi, jarak awal, serta durasi 5 detik cukup menegangkan tetapi adil.
- Tampilan Ardi terhadap furnitur, ukuran portrait, dan keterbacaan layar ending pada ukuran jendela yang digunakan.
- Kedua ending dan retry checkpoint; jangan menyamakan tombol retry dengan restart dari awal.
