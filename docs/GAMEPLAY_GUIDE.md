# Panduan gameplay After Hours — revisi 17 November 2026

Inventori menyimpan petunjuk untuk dibaca ulang. Setelah menutupnya dengan I/Esc, ikuti objective. Pintu antar-area bebas dipakai sejak awal; urutan di bawah adalah arahan investigasi, bukan penguncian pintu.

1. **LABKOM:** E di laptop untuk C1, baca hasil CCTV dan monolog sampai selesai. Foto/kartu pada laptop dapat diklik untuk diperbesar; Back/Esc menutup pemeriksaan agar kembali berjalan.
2. **Pintu keluar utama:** E untuk mencoba pulang. Pintu berulang ke LABKOM dan waktu menunjukkan 22.17. Jika dicoba sebelum laptop, objective tetap mengarahkan ke laptop.
3. **Mading dan loker LABKOM:** dapatkan C2/C3. Buku merah membuka diary; poster mading dapat diklik. Kartu mahasiswa berasal dari loker, bukan lemari.
4. **Gudang:** lewat pintu penghubung LABKOM. Cari C4 (transkrip rekaman) dan C5 (catatan). Pintu lainnya menuju Studio.
5. **Studio:** periksa dokumentasi C6. Jika bukti C1–C5 belum lengkap, UI menyebutkan yang masih kurang. Hubungkan tiga kesimpulan; I membuka bukti dan jawaban salah memberi petunjuk.
6. **Pengejaran dimulai di Studio:** setelah C6 dan dialog selesai, checkpoint dibuat. Ardi dapat mengikuti Raka ke Gudang dan LABKOM. Pintu Studio kembali ke Gudang; pintu Gudang kembali ke LABKOM. E dan fade hitam berlaku di semua pintu.
7. **Hindari Ardi:** gunakan furnitur untuk memutus garis pandang. E di lemari untuk bersembunyi, E lagi untuk keluar. Dua lemari berdiri di depan LABKOM, lemari LABKOM lama, dan lemari empat pintu Studio dapat dipakai. Gudang tidak diberi lemari baru.
8. **Ardi tetap aktif:** ia mencari posisi terakhir, lalu berpatroli setelah sekitar 9 detik tanpa melihat Raka. Bersembunyi tidak menghilangkan Ardi. Ia dapat mendeteksi kembali ketika Raka keluar. HUD menampilkan status pengejaran; Esc menjeda, I dinonaktifkan selama ancaman.
9. **Pintu terakhir:** ketika Ardi kehilangan jejak dan tidak sedang melihat Raka, gunakan pintu keluar utama LABKOM. Jika ia masih mencari/mengejar, pintu tetap mengulang ruangan. Pindah ruangan saja tidak menyelesaikan pengejaran.
10. **Ending:** Tunggu Ardi → **Akhirnya Pulang**. Pergi Sendiri → **Pulang**. Kedua pilihan tersedia pada tahap akhir, tanpa skor jumlah clue tambahan.

Saat pindah ruangan, Ardi masuk melalui pintu yang sama setelah waktu tempuh 2,5–7 detik. Waktu ini memberi kesempatan menjauh dari spawn; status pengejaran tidak direset. Petunjuk tidak hilang karena loop atau perpindahan.

## Tertangkap

Raka berhenti → video jumpscare → **GAME OVER**. **COBA LAGI** mengembalikan posisi sebelum pengejaran di Studio, keenam clue, dan progres deduksi. **MENU UTAMA** kembali ke menu. Ini terpisah dari dua pilihan ending. Restart dari pause/ending memulai run baru.

Checkpoint tersimpan selama sesi aplikasi, belum ke disk. Musik belum ditambahkan. Video yang tersedia tidak memiliki audio; rekaman Gudang tetap memakai transkrip.

## Pengujian manual di editor

Buka `D:/AfterHours/after-hours/project.godot`, muat ulang perubahan dari disk bila diminta, lalu F5 → Start Game.

- Sebelum mengambil clue, coba seluruh pintu antar-ruangan dan kembali. Raka muncul di sisi dalam pintu tujuan; diam tanpa E tidak menyebabkan perpindahan.
- Coba berjalan di keempat tepi lantai dan mengitari meja/lemari. Overlay collision editor bukan bagian dari gambar permainan; nonaktifkan Debug → Visible Collision Shapes untuk melihat tampilan normal.
- Coba kedua lemari depan LABKOM secara terpisah: prompt E, masuk, tahan WASD, tekan E lagi. Raka kembali ke titik aman di depan lemari.
- Ikuti investigasi hingga Studio. Keluar ke Gudang lalu LABKOM: Ardi tetap mengikuti, tidak langsung dianggap berhasil.
- Bersembunyi dan lihat apakah gerakan mencari/patroli, kecepatan, ukuran sprite, serta jeda kedatangan terasa adil. Keluar dekat Ardi untuk mencoba deteksi ulang.
- Biarkan tertangkap: video sekitar 3 detik, kemudian Game Over. Uji kedua tombol. Uji pula dua ending pada run terpisah.
- Periksa rasio video/portrait dan keterbacaan UI pada ukuran jendela yang biasa digunakan. Tes headless tidak menilai komposisi visual atau rasa kesulitan.
