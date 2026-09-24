# Expense Tracker

Expense Tracker adalah aplikasi Android untuk mencatat pengeluaran pribadi. MVP V0.1 dirancang agar pengguna dapat mencatat transaksi dengan cepat dan melihat total pengeluaran bulan berjalan.

> **Status proyek:** kerangka aplikasi Flutter Android sudah dibuat. Layar awal masih kosong; fitur MVP dan APK release belum tersedia.

## Fitur MVP yang direncanakan

- Menambah pengeluaran dengan nominal, kategori, tanggal, dan catatan opsional.
- Melihat seluruh riwayat pengeluaran serta lima transaksi terbaru di beranda.
- Melihat total pengeluaran bulan berjalan dalam Rupiah.
- Mengedit dan menghapus transaksi dengan konfirmasi penghapusan.
- Menggunakan semua fitur utama tanpa koneksi internet.

Data akan disimpan secara lokal di perangkat menggunakan SQLite. MVP ini dirancang tanpa akun, backend, atau sinkronisasi antarperangkat. Setelah aplikasi tersedia, menghapus aplikasi atau data aplikasi dapat menghilangkan riwayat yang tersimpan.

## Teknologi dan target

| Komponen | Rencana |
| --- | --- |
| Aplikasi | Flutter dan Dart |
| SDK pengembangan | Flutter 3.47.3 stable, Dart 3.13.3 |
| Platform | Android, minimum API 24; target dan compile API 36 |
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

## Menjalankan kerangka aplikasi

Siapkan Flutter 3.47.3, Android SDK, serta emulator atau perangkat Android. Dari root proyek, jalankan `flutter pub get` lalu `flutter run`. Aplikasi saat ini menampilkan layar kosong. Petunjuk build APK release akan ditambahkan setelah konfigurasi release selesai.
