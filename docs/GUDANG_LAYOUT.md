# Revisi Gudang: ukuran dan collision

Scene: `gudang.tscn`. Revisi ini hanya mengubah Gudang dan menambah tes physics.

## Penyebab masalah

Sprite rak/kursi, collision, dan origin Y-sort menggunakan offset yang berbeda. Contohnya RakKanan memiliki sprite pada (-467, -329), tetapi collision pada (-411, -150) relatif ke anchor yang masih berada jauh dari pijakan gambar. KursiTersimpan juga mempunyai collision jauh dari gambar. Gudang belum memiliki batas physics lantai.

## Perbaikan

- Background asli 3655 × 3162 memakai scale 0.5, sehingga ukurannya menjadi 1827.5 × 1581 world units. Sebagai pembanding, background LABKOM adalah 2911 × 2207 pada scale 1. Gudang kini merupakan ruangan penyimpanan yang lebih kecil.
- Furniture memakai scale 0.18; pintu 0.22. Scale karakter dan zoom kamera tetap.
- Tiga rak disusun mengikuti dinding panjang. Kursi dikelompokkan di sisi kanan dan area tengah terbuka.
- Setiap rak/kursi memiliki origin di tengah pijakan. Posisi sprite dan polygon diturunkan dari koordinat sumber PNG dengan transform yang sama: (pixel - anchor) × scale.
- Background, PNG, dan tekstur asli tidak diedit. Offset Cermin yang sebelumnya memakai ukuran world sebagai offset tekstur dihilangkan.
- Pintu terpasang pada kedua dinding; pintu kanan memakai flip_h agar kemiringannya mengikuti dinding. Marker interaksi serta spawn diperbarui mengikuti lokasi pintu.
- Batas lantai menggunakan empat CollisionPolygon2D di bawah StaticBody2D BatasLantai. Strip tepi saling overlap di sudut.
- C4 berada di depan rak dus kiri, C5 di depan rak HVS. Script interaksi dan syarat progres tetap.

Titik lantai world yang diukur dari background dan transformnya:
(-863.75, 234.5), (336.25, -463), (863.75, -160.5), (-336.25, 537).

## Validasi

Godot 4.7.2 headless:

- 32 pemeriksaan physics lulus: overlap capsule Raka, pijakan furniture di dalam lantai, batas tepi, spawn/petunjuk/pintu bebas collision, serta jalur terhubung dari tengah ruangan. Pencarian jalur memakai grid 24 world units dan swept test_move dengan capsule Raka yang sebenarnya.
- 39 pemeriksaan alur cerita lulus kembali setelah perubahan posisi.
- Preview komposisi dibuat dari texture dan transform scene untuk inspeksi susunan; ini bukan screenshot render Godot.

Perintah tes:

```text
Godot --headless --path D:/AfterHours/after-hours --script res://tests/gudang_physics_check.gd
Godot --headless --path D:/AfterHours/after-hours --script res://tests/story_flow_check.gd
```

Masih perlu pengujian manual: gerakkan Raka mengitari dan menabrak seluruh sisi rak, periksa perubahan tumpang-tindih sprite ketika melewati depan/belakang objek, lalu gunakan kedua pintu dan periksa C4–C5 dengan E. Jalankan ulang game setelah me-reload scene dari disk.
