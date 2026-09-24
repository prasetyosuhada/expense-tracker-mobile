# Expense Tracker

Expense Tracker adalah aplikasi Android untuk mencatat pengeluaran pribadi. MVP V0.1 dirancang agar pengguna dapat mencatat transaksi dengan cepat dan melihat total pengeluaran bulan berjalan.

> **Status proyek:** masih dalam tahap perencanaan. Repository ini berisi spesifikasi; aplikasi Flutter dan APK belum tersedia.

## Fitur MVP yang direncanakan

- Menambah pengeluaran dengan nominal, kategori, tanggal, dan catatan opsional.
- Melihat seluruh riwayat pengeluaran serta lima transaksi terbaru di beranda.
- Melihat total pengeluaran bulan berjalan dalam Rupiah.
- Mengedit dan menghapus transaksi dengan konfirmasi penghapusan.
- Menggunakan semua fitur utama tanpa koneksi internet.

Data disimpan secara lokal di perangkat menggunakan SQLite. MVP ini tidak memerlukan akun, backend, atau sinkronisasi antarperangkat. Menghapus aplikasi atau data aplikasi dapat menghilangkan riwayat yang tersimpan.

## Teknologi dan target

| Komponen | Rencana |
| --- | --- |
| Aplikasi | Flutter dan Dart |
| Platform | Android, minimum API 24 |
| Penyimpanan | SQLite lokal melalui `sqflite` |
| Bahasa dan mata uang | Bahasa Indonesia, IDR |
| Distribusi MVP | APK langsung |

## Dokumentasi

- [Product Requirements Document](docs/01-PRD.md) — kebutuhan dan batasan MVP.
- [UX/UI Specification](docs/02-UX-UI-SPEC.md) — alur, layar, dan desain antarmuka.
- [Technical Design](docs/03-TECHNICAL-DESIGN.md) — arsitektur dan keputusan teknis.
- [Data Model](docs/04-DATA-MODEL.md) — kontrak data dan skema SQLite.
- [Test Plan](docs/05-TEST-PLAN.md) — skenario pengujian dan kriteria kelulusan.
- [Coding Conventions](docs/06-CODING-CONVENTIONS.md) — aturan penulisan kode.

Petunjuk instalasi, menjalankan aplikasi, dan membangun APK akan ditambahkan setelah proyek Flutter diinisialisasi.
