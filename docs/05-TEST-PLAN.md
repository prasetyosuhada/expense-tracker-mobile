# Test Plan

## Expense Tracker Android

| Informasi | Detail |
| --- | --- |
| Versi dokumen | 1.0 |
| Versi produk | MVP V0.1 |
| Tanggal | 20 September 2026 |
| Platform | Android, Flutter |
| Model penggunaan | Offline, satu pengguna pada satu perangkat |
| Penyimpanan | SQLite lokal melalui `sqflite`, schema version 1 |
| Dokumen acuan | [01-PRD.md](01-PRD.md), [02-UX-UI-SPEC.md](02-UX-UI-SPEC.md), [03-TECHNICAL-DESIGN.md](03-TECHNICAL-DESIGN.md), [04-DATA-MODEL.md](04-DATA-MODEL.md) |
| Status | Rencana pengujian; belum merupakan laporan hasil eksekusi |

## 1. Tujuan

Dokumen ini mendefinisikan cara memverifikasi bahwa MVP memenuhi user story, menjaga integritas data lokal, dan dapat digunakan pada perangkat Android tanpa jaringan. Setiap skenario memiliki ID agar dapat dihubungkan ke automated test, hasil pengujian manual, dan defect.

PRD menjadi sumber kebutuhan produk tertinggi. Dokumen 02 menentukan perilaku dan tampilan UI, dokumen 03 menentukan kontrak teknis, dan dokumen 04 menentukan kontrak data. Test plan tidak menambahkan fitur produk atau mengubah keputusan dokumen tersebut.

Kelulusan ditentukan oleh hasil eksekusi terhadap build yang teridentifikasi, bukan oleh keberadaan dokumen atau banyaknya test.

## 2. Ruang Lingkup

### 2.1 In Scope

- Alur tambah, lihat, edit, dan hapus pengeluaran.
- Total bulan berjalan dan maksimal lima transaksi terbaru secara global.
- Validasi, normalisasi, formatting, dan urutan data.
- Navigasi, keyboard, dirty form, loading, success, empty, error, dan retry.
- SQLite asli pada Android, termasuk persistensi, constraint, mapping, dan change event.
- Lifecycle aplikasi, pergantian bulan, dan penanganan hasil request yang terlambat.
- Light theme Wise-inspired, aksesibilitas, layout responsif, serta font lokal.
- Performa dengan 10.000 transaksi.
- Privasi, permission, backup configuration, instalasi, dan artifact release.

### 2.2 Out of Scope

Backend, API, autentikasi, cloud sync/backup sebagai fitur, multi-device, pemasukan, budgeting, filter, pencarian, grafik, export, OCR, AI, notifikasi, serta integrasi bank tidak diuji sebagai fitur MVP karena belum termasuk produk.

Verifikasi bahwa database tidak ikut cloud backup tetap masuk scope privasi. Pengujian upgrade schema hanya berlaku ketika sudah ada schema release sebelumnya; MVP tidak memerlukan migration fiktif dari version 0.

## 3. Strategi dan Prioritas

### 3.1 Level Pengujian

| Kode | Level | Tanggung jawab |
| --- | --- | --- |
| U | Unit | Domain, validator, formatter, mapper, dan view model menggunakan fake terkontrol. |
| W | Widget | Interaksi layar, semantics, navigasi, state, dan layout. |
| G | Golden | Regresi visual pada environment, font, ukuran, dan clock yang dipin. |
| I | Integration Android | Alur lintas layar dan repository dengan `sqflite` asli. |
| M | Manual/device | TalkBack, keyboard, force-stop, reboot, offline, dan usability pada perangkat. |
| R | Review artifact | Manifest hasil merge, dependency, asset, signing configuration, dan release artifact. |

Sebagian besar variasi input diuji pada U/W. I menguji jalur utama dan batas integrasi nyata; fake repository tidak membuktikan kebenaran SQLite atau persistensi setelah proses berhenti. G tidak menggantikan W untuk perilaku atau M untuk aksesibilitas.

Jika satu kasus mencantumkan beberapa level, bukti boleh berasal dari beberapa test yang bersama-sama memenuhi expected result. Bukti fake tidak dapat menggantikan level I/M yang memang memerlukan perangkat atau penyimpanan nyata.

### 3.2 Prioritas Eksekusi

| Prioritas | Makna | Contoh |
| --- | --- | --- |
| P0 | Wajib pada smoke test dan menjadi penghalang release jika gagal | CRUD, total salah, kehilangan data, crash alur utama, kebocoran data. |
| P1 | Wajib pada full regression sebelum release | Boundary input, retry, race condition, aksesibilitas, layout, visual, dan performa. |
| P2 | Tambahan eksplorasi di luar matriks minimum | Variasi OEM/perangkat atau input tambahan yang belum menjadi kasus wajib. |

P0/P1 menyatakan urutan eksekusi, bukan izin mengabaikan acceptance criteria. Tingkat keparahan defect dinilai terpisah pada bagian 15.

## 4. Environment dan Prasyarat

### 4.1 Matriks Minimum

Baseline API berikut mengikuti dokumen 03, bukan pernyataan kebijakan distribusi terbaru. Jika baseline SDK berubah, matriks diperbarui bersama Technical Design sebelum release.

| Environment | Konfigurasi | Cakupan minimum |
| --- | --- | --- |
| Host automated test | Flutter/Dart terpin, dependency terkunci, locale `id_ID`, clock tetap | U, W, G, static analysis, coverage. |
| Android minimum | API 24, emulator atau perangkat | Integration CRUD/SQLite, offline smoke, instalasi, layout, Back. |
| Android baseline target | API 36 atau lebih baru sesuai SDK terpin | Integration, permission/backup, lifecycle, gesture navigation, offline smoke. |
| Perangkat fisik kelas menengah | Model, RAM, API, refresh rate, dan build mode dicatat | Performa profile/release, TalkBack, keyboard, force-stop, reboot. |
| Variasi layout | Lebar 320dp, ponsel standar 360–412dp, landscape, viewport lebih dari 600dp | Overflow, safe area, form scroll, nominal panjang, pembatas lebar konten. |
| Variasi font/motion | Skala default, 2.0 pada widget test, ukuran font terbesar target perangkat, reduce motion | Keterbacaan, akses aksi utama, semantics, animasi. |
| Variasi waktu | Asia/Jakarta, UTC, zona dengan pergantian tanggal berbeda; clock akhir bulan/tahun | Date-only tetap, batas bulan, refresh resume/foreground. |

Tidak semua kombinasi memerlukan cross-product penuh. Jalankan alur utama di kedua API minimum/target, seluruh variasi layout di W, dan pemeriksaan perangkat pada target yang disebutkan. Catat kombinasi yang benar-benar dieksekusi.

### 4.2 Isolasi dan Testability

- Gunakan emulator/perangkat khusus test dan data sintetis. Jangan menjalankan reset, clear data, uninstall, atau fault injection terhadap database pribadi.
- Setiap test repository mendapat path/file database terisolasi. Tutup connection, batalkan subscription/timer, lalu bersihkan hanya fixture milik test tersebut.
- Untuk uji restart/reboot, pertahankan file yang sama di antara fase sebelum dan sesudah restart; cleanup dilakukan setelah verifikasi.
- Build debug dan release tidak otomatis memiliki sandbox terpisah jika memakai `applicationId` yang sama. Gunakan target instalasi khusus test; jangan mengandalkan build mode untuk isolasi.
- Sediakan `FakeExpenseRepository`, `FakeAppClock`, dan Future yang penyelesaiannya dapat dikendalikan. Fake harus mengikuti kontrak domain, ordering, dan event yang sama.
- Harness fault injection dan seed data tidak masuk artifact production.
- Rekam versi Flutter/Dart, dependency lockfile, OS host, Android API, locale, timezone, device, build version, dan revision atau hash source/artifact.

## 5. Test Data dan Expected Result

### 5.1 Fixture Dasar

| Fixture | Isi | Kegunaan |
| --- | --- | --- |
| F-EMPTY | Database schema v1 tanpa row | Empty state dan total nol. |
| F-ONE | Satu transaksi Rp25.000, Makanan, tanggal hari ini, note `Makan siang` | Smoke CRUD. |
| F-MIX | Delapan row pada tabel berikut | Ordering, bulan/tahun, edit/delete, latest-five. |
| F-BOUNDARY | Variasi nominal, tanggal, kategori, dan note pada bagian 7 | Validasi dan mapper. |
| F-VOLUME | 10.000 row sintetis deterministik | Performa serta presisi agregat. |
| F-FAULT | Fake failure atau file database test khusus yang rusak | Error, recovery, dan integritas. |

Reset ke fixture awal sebelum setiap kasus, kecuali skenario secara eksplisit berupa rangkaian langkah. ID pada F-MIX adalah ID fixture; automated test tidak boleh mengasumsikan ID instalasi produksi selalu dimulai dari 1.

### 5.2 F-MIX

Clock tetap: `20 September 2026, 12:00 Asia/Jakarta` atau `2026-09-20T05:00:00Z`. Semua row memakai kode kategori valid dan note opsional. `updated_at = created_at` pada kondisi awal.

| ID | `transaction_date` | `amount` | `category` | `created_at` UTC |
| --- | --- | --- | --- | --- |
| 1 | 2026-08-31 | 10000 | food | 2026-09-20T01:00:00Z |
| 2 | 2026-09-01 | 25000 | transportation | 2026-09-20T01:01:00Z |
| 3 | 2026-09-19 | 15000 | shopping | 2026-09-20T01:02:00Z |
| 4 | 2026-09-20 | 40000 | bills | 2026-09-20T01:03:00Z |
| 5 | 2026-09-20 | 60000 | other | 2026-09-20T01:03:00Z |
| 6 | 2026-09-30 | 5000 | food | 2026-09-20T01:04:00Z |
| 7 | 2026-10-01 | 70000 | transportation | 2026-09-20T01:05:00Z |
| 8 | 2025-09-20 | 80000 | shopping | 2026-09-20T01:06:00Z |

Expected result independen dari implementasi:

- Total September 2026: `145000`, ditampilkan `Rp145.000`.
- Urutan seluruh ID: `[7, 6, 5, 4, 3, 2, 1, 8]`.
- Lima terbaru Home: `[7, 6, 5, 4, 3]`, meskipun ID 7 berada di bulan depan.
- Tanggal masa depan dalam bulan berjalan, seperti ID 6, tetap masuk total bulan itu; perhitungan bukan month-to-date.
- Jika hanya ID 1, 7, 8 tersisa, total September adalah `Rp0`, tetapi daftar terbaru tidak kosong.
- Dari fixture awal: tambah Rp20.000 pada 20 September → total `165000`, row count 9.
- Dari fixture awal: ubah amount ID 2 menjadi `35000` → total `155000`, row count tetap 8.
- Dari fixture awal: pindahkan tanggal ID 4 ke 31 Agustus → total September `105000`.
- Dari fixture awal: hapus ID 5 → total September `85000`, row count 7.

### 5.3 F-VOLUME

Gunakan generator dengan seed tetap dan simpan expected row count, urutan, serta total per bulan terpisah dari production query. Salah satu fixture presisi wajib berisi 10.000 transaksi pada bulan yang sama, masing-masing bernilai maksimum `999999999999`, sehingga total tepat `9999999999990000`.

Batas nominal berlaku per transaksi; total tidak boleh dipotong menjadi batas satu transaksi atau dihitung sebagai floating-point. Gunakan juga fixture tanggal/kategori tersebar untuk mengukur query range bulan dan scroll yang representatif. Waktu seed tidak termasuk pengukuran operasi pengguna.

## 6. Kasus Fungsional dan Navigasi

Seluruh kasus memakai locale `id_ID` dan fixture terisolasi. Expected result mencakup persistensi bila operasi berhasil; snackbar saja tidak membuktikan write berhasil.

| ID | Prioritas / Level | Setup dan tindakan | Expected result |
| --- | --- | --- | --- |
| FUN-01 | P0 / W,I | Buka aplikasi dengan F-EMPTY; pindah Beranda/Transaksi. | Home awal aktif, `Rp0`, empty copy dan CTA sesuai dokumen 02; kedua destinasi dapat digunakan. |
| FUN-02 | P0 / W,I | Dari Home tambah Rp25.000, Makanan, hari ini, `Makan siang`. | Satu row tersimpan; kembali Home; item, total, dan snackbar `Pengeluaran berhasil ditambahkan` benar. |
| FUN-03 | P0 / W,I | Tambah dari Transaksi; ulangi akses melalui CTA empty state pada fixture baru. | Form terbuka; setelah sukses kembali ke asal; tab lain ikut diperbarui. |
| FUN-04 | P0 / W,I | Buka Transaksi dengan F-MIX dan scroll. | Semua 8 row tersedia dalam urutan fixture; label, tanggal, nominal, serta note opsional benar. |
| FUN-05 | P0 / U,W,I | Buka Home dengan F-MIX; uji pula 0, 1, 5, dan 6 row. | Total mengikuti fixture; latest global dibatasi maksimum 5 tanpa menyembunyikan row dari daftar lengkap. |
| FUN-06 | P1 / W,I | Hanya simpan row bulan/tahun lain. | Total bulan berjalan `Rp0`; riwayat tetap tampil; tidak memakai empty state global. |
| FUN-07 | P0 / W,I | Tap row, lalu pada percobaan terpisah pilih menu Edit; ubah nominal/kategori/note. | Nilai awal sesuai row; perubahan tersimpan; ID/createdAt tetap; total dan kedua tab mutakhir. |
| FUN-08 | P0 / U,I | Pada F-MIX pindahkan ID 4 ke Agustus. | Total September `105000`; row berpindah urutan berdasarkan tanggal baru. |
| FUN-09 | P0 / W,I | Pilih Hapus; batalkan melalui Batal, Back, dan tap luar dialog pada percobaan terpisah. | Dialog tertutup, row count dan total tidak berubah. |
| FUN-10 | P0 / W,I | Konfirmasi hapus ID 5 pada F-MIX. | Row hilang dari SQLite dan kedua tab; total `85000`; snackbar `Pengeluaran berhasil dihapus`; tanpa undo. |
| FUN-11 | P1 / W,I | Hapus satu-satunya row pada F-ONE. | Kedua layar menjadi empty state dan total `Rp0` setelah write selesai. |
| FUN-12 | P1 / W,I | Tap `Lihat semua`, bottom navigation, FAB; tekan Back di Transaksi lalu Home. | Destinasi tidak menumpuk route; Transaksi → Home; Back di Home mengikuti Android. |
| FUN-13 | P1 / W | Back pada form yang belum berubah; ulangi dengan form berubah. | Form bersih langsung tutup; form dirty menampilkan `Buang perubahan?`. |
| FUN-14 | P1 / W | Dalam dialog dirty pilih `Tetap di sini`, tap luar, atau Back; lalu uji `Buang`. | Tiga tindakan pertama mempertahankan input; `Buang` kembali ke asal tanpa write. |
| FUN-15 | P1 / W,M | Buka category sheet/date picker, lalu Back; batalkan date picker. | Komponen paling atas ditutup lebih dahulu; form dan tanggal sebelumnya tetap. |
| FUN-16 | P1 / W,M | Buka add/edit dan jalankan form dengan keyboard terbuka. | Add fokus nominal dengan keyboard numerik; edit tanpa autofocus; semua field dan tombol dapat dijangkau melalui scroll. |
| FUN-17 | P1 / W,I | Edit note menjadi kosong; simpan dua transaksi identik melalui dua submit terpisah yang selesai. | Note tersimpan null; dua transaksi identik diperbolehkan dan memiliki ID berbeda. |
| FUN-18 | P1 / W,I | Scroll Transaksi, edit note tanpa mengubah tanggal, lalu kembali. | Urutan tidak berubah karena updatedAt; posisi scroll dipertahankan jika memungkinkan. |

## 7. Validasi, Normalisasi, dan Formatting

Kasus form dijalankan pada mode tambah dan edit. Kasus yang diblokir input formatter tetap diuji langsung pada boundary domain/repository agar perlindungan tidak hanya bergantung pada keyboard.

| ID | Prioritas / Level | Input atau tindakan | Expected result |
| --- | --- | --- | --- |
| VAL-01 | P0 / U,W | Nominal kosong; submit. | `Nominal wajib diisi`; tidak ada write. |
| VAL-02 | P0 / U,W | Nominal `0`; panggil validator/repository dengan nominal negatif. | `Nominal harus lebih besar dari 0` untuk validasi terkait; repository menolak nilai nonpositif. |
| VAL-03 | P1 / U,W,I | Nominal `1`, `999999999999`, lalu `1000000000000`. | Dua nilai pertama round-trip tepat; nilai terakhir ditolak dengan `Nominal terlalu besar`. |
| VAL-04 | P1 / U,W | Input gagal parse melalui view model; ketik/paste karakter nondigit di widget. | Gagal parse menghasilkan `Nominal tidak valid`; widget hanya menyisakan input sesuai formatter digit, tanpa crash atau nilai pecahan. |
| VAL-05 | P1 / U,W | Ketik `25000`, edit digit di tengah, hapus, paste digit panjang. | Tampilan `25.000`, cursor tetap usable; parsing ke `25000`; digit tidak hilang/bertambah akibat reformat. |
| VAL-06 | P0 / U,W | Kategori kosong; kemudian pilih setiap kategori. | `Kategori wajib dipilih`; hanya lima kategori tersedia dengan urutan dan label dokumen 02; satu pilihan aktif. |
| VAL-07 | P1 / U,I | Round-trip lima kode kategori; mapper menerima kode tidak dikenal. | Kode kanonik tetap; kode asing menghasilkan `CorruptDataFailure`, tanpa fallback `other`. |
| VAL-08 | P1 / U,W,I | Note kosong, whitespace-only, `  Makan siang  `, dan `Makan\nsiang`. | Dua pertama null; trim tepi; whitespace internal dan newline dipertahankan. |
| VAL-09 | P1 / U,W,I | Note 99/100/101 grapheme; emoji keluarga dan huruf dengan combining mark. | Counter mengikuti grapheme sebelum trim; input ke-101 diblokir; repository menolak >100; 100 grapheme majemuk dapat tersimpan. |
| VAL-10 | P1 / U | Parse `2024-02-29`, `2026-02-29`, `2026-04-31`, `2026-9-01`, serta string berjam. | Hanya tanggal valid strict `YYYY-MM-DD` diterima; tanggal invalid tidak dinormalisasi diam-diam. |
| VAL-11 | P1 / W,M | Clock 2026; buka picker add, pilih masa depan; edit row valid tahun 1900. | Rentang default 1 Jan 1926–31 Des 2126; masa depan diterima; edit memperluas rentang untuk row tersimpan. |
| VAL-12 | P1 / U,I,M | Simpan date-only, ganti timezone, baca ulang. | Tanggal transaksi tetap sama; audit timestamp tetap instant UTC; bulan berjalan mengikuti waktu lokal perangkat. |
| VAL-13 | P1 / W | Submit form dengan beberapa error; perbaiki field satu per satu. | Fokus/scroll ke invalid pertama; error di bawah field diperbarui setelah submit pertama; input tetap ada. |
| VAL-14 | P1 / U,W | Format 0, 25000, nominal maksimum, total di atas maksimum satu transaksi; tampilkan tanggal/bulan. | `Rp0`, `Rp25.000`, tanpa desimal/spasi setelah Rp/singkatan; nama bulan Indonesia sesuai konteks. |
| VAL-15 | P1 / U,I | Uji boundary awal/akhir September, Desember → Januari, dan Februari tahun kabisat. | Range `[awal bulan, awal bulan berikutnya)` benar; bulan yang sama pada tahun lain tidak ikut SUM. |

Tanda minus dan separator bukan data domain. Pengujian formatter memeriksa perilaku digit-only yang ditetapkan dokumen 03; jangan mengasumsikan paste string bebas adalah parser nominal finansial yang mendukung format apa pun.

## 8. Repository, SQLite, dan Integritas

| ID | Prioritas / Level | Setup dan tindakan | Expected result |
| --- | --- | --- | --- |
| DAT-01 | P0 / I | Buka database baru dan periksa metadata/schema. | Version 1; table `expenses`, column/constraint sesuai dokumen 04; index `idx_expenses_order` tersedia. |
| DAT-02 | P0 / U,I | Create, read, update, delete dengan payload valid. | Field round-trip tepat; amount/timestamp integer, tanggal ISO, kategori kode; delete hanya row target. |
| DAT-03 | P1 / U,I | Clock create tetap; ubah clock sebelum update. | Create membaca clock sekali, timestamp sama; update mempertahankan id/createdAt dan memakai waktu baru untuk updatedAt. |
| DAT-04 | P1 / U,I | Jalankan F-MIX; ulangi timestamp sama dan clock mundur. | Order selalu tanggal DESC, createdAt DESC, id DESC; tidak mengandalkan updatedAt atau timestamp monotonic. |
| DAT-05 | P0 / I | Query monthly/latest dengan F-MIX dan F-EMPTY. | Expected fixture cocok; SUM kosong 0; latest memakai limit 5; batas bulan inklusif/eksklusif tepat. |
| DAT-06 | P1 / U,I | Request latest limit nonpositif; update/delete ID tidak ada; ID nonpositif. | Limit/ID invalid ditolak; ID positif tidak ditemukan → `NotFoundFailure`; tidak ada mutasi row lain. |
| DAT-07 | P1 / I | Bypass repository pada DB test: insert amount 0/di atas maksimum, category asing, required field null. | Constraint SQL yang didefinisikan menolak; row valid tidak berubah. Validitas kalender dan grapheme tetap tanggung jawab domain/mapper. |
| DAT-08 | P1 / U,I | Mapper menerima field hilang, tipe salah, tanggal invalid, note >100, category asing. | `CorruptDataFailure`; tidak skip row, memberi nilai palsu, atau menghapus database. |
| DAT-09 | P1 / I | Simpan note seperti `O'Brien; --` dan string mirip SQL dalam batas panjang. | Data tersimpan sebagai literal melalui parameter binding; table dan row lain tidak berubah. |
| DAT-10 | P0 / U,I | Tahan Future write; subscribe changes; selesaikan sukses/gagal. | Event created/updated/deleted hanya setelah commit sukses, satu per mutasi; tidak ada event sukses untuk write gagal. |
| DAT-11 | P1 / I,R | Picu read Home bersamaan dengan write terkontrol; tinjau batas read transaction. | Total dan latest berasal dari snapshot yang sama, tidak mencampur keadaan sebelum/sesudah write. |
| DAT-12 | P1 / U,I | Coba mutasi entity/list hasil query; buka database berulang dalam satu proses. | Entity/list immutable; caller tidak mengubah source state; instance koneksi digunakan sesuai kontrak. |
| DAT-13 | P1 / U,I | Gagalkan open pertama, pulihkan, lalu retry. | Cached failed Future dibersihkan; open benar-benar dicoba ulang; database lama tidak di-reset. |
| DAT-14 | P1 / I | Baca seluruh F-VOLUME dan hitung total dengan oracle fixture. | Row count, urutan, dan aggregate tepat sebagai integer termasuk total `9999999999990000`. |

Untuk DAT-08, gunakan mapper unit fixture bagi row yang tidak mungkin masuk melalui constraint production. Pada integration test, gunakan row korup yang masih dapat melewati schema, misalnya tanggal kalender invalid sepanjang 10 karakter atau note >100 grapheme. Jangan melemahkan schema production untuk menciptakan fixture.

## 9. State, Error, dan Concurrency

| ID | Prioritas / Level | Setup dan tindakan | Expected result |
| --- | --- | --- | --- |
| STA-01 | P1 / U,W | Tahan initial read, lalu selesaikan dengan data/kosong/error. | Loading tidak menampilkan false empty; hasil masuk state yang tepat; initial error tidak tampil sebagai `Rp0` valid. |
| STA-02 | P0 / U,W,I | Gagalkan create/update sebelum commit; kemudian retry sukses. | Form dan input tetap; snackbar gagal sesuai operasi; tidak ada row tambahan/perubahan parsial; retry sukses tepat sekali. |
| STA-03 | P0 / U,W,I | Gagalkan delete sebelum commit. | Dialog tutup, row tetap, snackbar `Pengeluaran gagal dihapus. Coba lagi.`; retry tersedia. |
| STA-04 | P1 / U,W | Tap Simpan cepat berulang dan tekan Back saat write ditahan. | Satu request; label/progress tetap; input dan Back terkunci sementara, dibuka lagi setelah gagal. |
| STA-05 | P1 / U,W | Tap Hapus berulang saat delete ditahan; coba tutup dialog. | Satu request untuk ID itu; aksi/dismiss saat in-flight tidak memicu operasi lain; loading tidak diterapkan ke seluruh row. |
| STA-06 | P1 / U,W | Setelah snapshot valid, gagalkan refresh storage; kemudian retry/reload. | Snapshot lama dipertahankan dengan feedback gagal, bukan berubah menjadi kosong; setelah pulih, snapshot terbaru tampil. |
| STA-07 | P1 / U,W | Mulai request A lalu B; selesaikan B dahulu dan A terakhir, termasuk A gagal. | Hasil/error A tidak menimpa state B; generation token bekerja. |
| STA-08 | P1 / U,W,I | Mutasi dari satu tab saat tab lain tersembunyi, lalu pindah tab. | Home dan Transaksi memuat snapshot terbaru melalui event; total/daftar tidak tertinggal. |
| STA-09 | P1 / U,W | Dispose view model ketika request pending; kirim event/selesaikan request. | Tidak ada notify setelah dispose, crash, listener bocor, atau timer aktif yang tertinggal. |
| STA-10 | P1 / U,W,M | Ubah clock melewati akhir bulan saat foreground; ulangi saat background lalu resume. | Home mengganti bulan dan total; timer hari berikutnya dijadwalkan ulang; row tidak diubah. |
| STA-11 | P1 / U,W,M | Resume ketika belum pernah load sukses atau state sebelumnya error. | Load dicoba ulang sesuai dokumen 03; lifecycle tidak menutup database secara paksa. |
| STA-12 | P1 / U,W | Simulasikan `NotFoundFailure`, `CorruptDataFailure`, dan `UnexpectedFailure`. | Not-found memberi feedback/reload; corrupt menjadi read error tanpa skip/reset; exception internal tidak bocor ke UI. |

Initial read failure berbeda dari refresh failure setelah data pernah tersedia. Pada refresh storage failure, snapshot lama boleh dipertahankan dengan feedback sesuai dokumen 03; jangan menampilkannya sebagai hasil refresh sukses. Data yang diketahui korup mengikuti aturan read error, bukan fallback total nol atau daftar yang sudah menghilangkan row bermasalah.

Write yang sudah commit tetapi refresh UI kemudian gagal juga berbeda dari write gagal. Verifikasi row tersimpan dan jangan mengulangi create otomatis hanya karena refresh gagal, karena transaksi identik memang diperbolehkan.

Fault injection menggunakan fake untuk U/W dan harness database test untuk I. Jangan menyatakan error storage teruji pada SQLite hanya berdasarkan fake. Kegagalan yang sulit direproduksi secara aman pada perangkat dicatat sebagai keterbatasan bukti, bukan dianggap Pass.

## 10. Offline, Lifecycle, dan Persistensi

| ID | Prioritas / Level | Setup dan tindakan | Expected result |
| --- | --- | --- | --- |
| LIF-01 | P0 / I,M | Matikan Wi-Fi/data seluler sebelum cold launch; jalankan create/read/update/delete. | Seluruh alur selesai; tanpa permintaan koneksi, banner offline, atau indikator sync. |
| LIF-02 | P0 / I,M | Simpan sukses, hentikan proses aplikasi, lalu launch ulang tanpa reseed/clear data. | Row dan total tetap tepat dari file yang sama. Membuat ulang widget tree saja tidak cukup sebagai bukti restart. |
| LIF-03 | P0 / M | Simpan/edit/hapus sampai sukses, reboot perangkat test, lalu buka lagi. | Seluruh perubahan yang sudah sukses bertahan; row yang dihapus tidak muncul kembali. |
| LIF-04 | P1 / I,M | Background/resume berulang dan rotasi saat form/daftar aktif. | Tidak crash atau membuat write ganda; input bertahan selama proses/state masih hidup; layout tetap usable. |
| LIF-05 | P1 / I,M | Hentikan proses sekitar write pada fixture khusus, lalu buka database. | Mutasi atomic: row sebelum atau sesudah write, tanpa record parsial/schema rusak. Setelah sukses telah ditampilkan, write wajib bertahan. |
| LIF-06 | P1 / M | Clear app data atau uninstall pada instalasi test, lalu install/buka ulang. | Aplikasi mulai kosong sesuai kebijakan lokal; tidak menjanjikan recovery atau cloud restore. |
| LIF-07 | P1 / M,R | Cold launch offline pada instalasi release baru. | Geist/Inter tersedia dari asset; tidak memerlukan unduhan font atau seed development. |

Persistensi draft form setelah proses dibunuh OS belum menjadi kontrak MVP. Bedakan kehilangan draft yang belum disimpan dari kehilangan transaksi yang telah berhasil di-commit.

## 11. Visual, Aksesibilitas, dan Usability

### 11.1 Kasus UI

| ID | Prioritas / Level | Pemeriksaan | Expected result |
| --- | --- | --- | --- |
| UI-01 | P1 / W,G,R | Theme dan komponen utama. | Primary `#9FE870`/onPrimary `#163300`; canvas/surface/danger dan category colors mengikuti dokumen 02, bukan warna default Material yang tidak diadaptasi. |
| UI-02 | P1 / W,G,M | Primary/FAB, input, card, dialog, sheet, navigation, snackbar pada default/pressed/focus/disabled/loading/error. | Shape, spacing, border, typography, dan state sesuai dokumen 02; loading tidak mengubah lebar tombol atau menghilangkan label. |
| UI-03 | P1 / W,G,R | Font display/body dan iconography. | Geist/Inter lokal dengan weight benar; font fallback tetap usable; tidak ada logo, nama, atau aset merek Wise di aplikasi. |
| UI-04 | P1 / W,M | Lebar 320dp, landscape, keyboard terbuka, cutout/gesture inset, viewport lebar. | Tanpa overflow horizontal; aksi utama terjangkau; safe area dihormati; konten lebar dibatasi sekitar 600dp. |
| UI-05 | P1 / W,M | Text scaling besar dengan nominal maksimum dan total F-VOLUME. | Nominal/total terbaca utuh tanpa pemendekan rb/jt; tindakan utama tidak terpotong; note daftar maksimal dua baris dengan ellipsis. |
| UI-06 | P1 / W,M | Ukur target sentuh, jalankan TalkBack melalui alur tambah/edit/hapus. | Target minimal 48×48dp; fokus logis; aksi berlabel; ikon dekoratif tidak dibacakan; menu menyebut konteks transaksi. |
| UI-07 | P1 / W,M | Submit invalid dan hasil operasi dengan TalkBack aktif. | Error terkait field dan feedback penting dapat diumumkan; kategori/error tidak bergantung pada warna saja. |
| UI-08 | P1 / W,M | Audit kontras pasangan teks/surface termasuk error dan focus; aktifkan reduce motion. | Teks normal ≥4.5:1, teks besar ≥3:1 menurut dokumen 02; focus terlihat; motion dinonaktifkan/dipersingkat sesuai preferensi. |
| UI-09 | P1 / W,M | Tinjau label, picker, snackbar, dialog dan format angka pada locale perangkat berbeda. | UI tetap Bahasa Indonesia; microcopy dokumen 02 sesuai konteks; snackbar tidak menutupi FAB/navigation. |

Nilai kontras adalah kriteria internal yang disalin dari UX/UI Spec. Menguji warna token saja tidak cukup: periksa pasangan warna setelah opacity, overlay, dan state diterapkan.

### 11.2 Golden Baseline

Golden wajib mencakup Home kosong, Home berisi F-MIX, Transactions, dan form error. Pin ukuran viewport, device pixel ratio, text scaling, clock, locale, platform, versi SDK, renderer/environment host, dan font asset. Tunggu font serta animasi mencapai keadaan deterministik sebelum snapshot.

Golden pertama harus ditinjau terhadap dokumen 02. Perubahan baseline disertai diff visual dan alasan; jangan memperbarui snapshot otomatis hanya untuk membuat CI hijau. Screenshot perangkat melengkapi golden ketika perbedaan platform/font tidak tercakup host.

### 11.3 Usability Singkat

Minta penguji yang belum terbiasa dengan aplikasi mencatat pengeluaran, menemukan riwayat, memperbaiki nominal, dan membatalkan penghapusan tanpa arahan langkah demi langkah. Catat kebingungan, salah tap, serta waktu sebagai observasi. PRD belum menetapkan target durasi input, sehingga hasil ini tidak digunakan untuk menciptakan SLA baru.

## 12. Performa

Gunakan F-VOLUME dan profile/release pada perangkat fisik kelas menengah. Catat model, OS/API, refresh rate, suhu/kondisi perangkat, build mode, ukuran database, serta sampel mentah. Pengukuran debug tidak menjadi bukti kelulusan budget.

| ID | Prioritas | Aktivitas dan batas ukur | Budget dari dokumen 03 |
| --- | --- | --- | --- |
| PERF-01 | P1 | Launch proses sampai frame konten awal atau valid error state | ≤2 detik; happy path seeded database wajib diukur. |
| PERF-02 | P1 | Pemanggilan repository Home sampai snapshot selesai dimapping | ≤300 ms. |
| PERF-03 | P1 | Tap Transaksi sampai frame daftar siap diinteraksikan | ≤500 ms. |
| PERF-04 | P1 | Tap create/update/delete valid sampai commit dan UI aktif diperbarui | ≤500 ms per operasi. |
| PERF-05 | P1 | Scroll daftar berulang, termasuk nominal/note panjang | Tidak ada jank berulang yang terlihat; sertakan frame timeline. |

Protokol pengukuran plan ini: ambil 10 cold launches tanpa menghapus database dan minimal 20 sampel untuk setiap operasi warm setelah warm-up. Laporkan median, p95, maksimum, dan outlier; bandingkan p95 dengan budget untuk keputusan release. Definisi p95 yang dipakai adalah nearest-rank pada sampel terurut. Semua latency end-to-end memakai frame/state selesai, bukan sekadar saat Future write return.

Jika budget gagal, cari bottleneck query, mapping, atau rendering, lalu ukur ulang setelah perbaikan. Jangan menambahkan pagination atau mengurangi dataset agar lulus tanpa perubahan scope. Error state cepat bukan pengganti keberhasilan membuka data yang valid.

## 13. Privasi, Migration, dan Release Artifact

| ID | Prioritas / Level | Pemeriksaan | Expected result |
| --- | --- | --- | --- |
| SEC-01 | P0 / R,M | Manifest hasil merge/build release, dependency dan observasi traffic per aplikasi. | Tanpa permission INTERNET, permission berbahaya, analytics/crash SDK atau network client pengirim data; tidak ada traffic transaksi. |
| SEC-02 | P0 / I,R | Lokasi database dan log release saat sukses/gagal. | Database di internal app storage; nominal/note/row/path lengkap tidak bocor ke log atau shared storage. |
| SEC-03 | P0 / R,M | `allowBackup`, `fullBackupContent`, `dataExtractionRules`, cloud backup dan transfer pada target yang tersedia. | Konfigurasi sesuai dokumen 03; database dikecualikan dari cloud backup; perilaku device-to-device tercatat dan sesuai kebijakan lokal. |
| SEC-04 | P1 / R,M | Periksa artifact release dan cold launch. | Tanpa seed/fault hooks, asset Wise, download font, atau klaim encryption/recovery yang tidak tersedia; font beserta lisensinya dibundel. |
| MIG-01 | P0 / I | Fresh install tanpa database. | Schema v1 dibuat atomic; table/index benar dan CRUD dapat digunakan. |
| MIG-02 | P1 / I | Jika schema berikutnya tersedia, upgrade fixture dari setiap versi release yang didukung. | Row count/nilai tetap, mapping benar, constraint/index baru tersedia; bukan sekadar menguji database kosong. |
| MIG-03 | P1 / I | Jika migration tersedia, injeksikan gagal di tengah migration/rebuild. | Rollback tanpa kehilangan row atau schema parsial; tidak ada destructive fallback/downgrade otomatis. |
| REL-01 | P0 / R,M | Build AAB release; install APK yang dihasilkan dari artifact tersebut dengan tooling distribusi yang dipin. | Install/launch sukses; label, application ID, version/build number, min/target SDK, dan signing benar. |
| REL-02 | P0 / M | Jalankan smoke offline pada artifact release di API minimum dan target. | FUN-01/02/04/05/07/09/10 serta LIF-01/02 lulus; screenshot/log sesuai build yang diuji. |
| REL-03 | P1 / M | Jika ada build release sebelumnya, install update tanpa clear data dengan identitas/signing sesuai. | Data lama tetap ada dan CRUD berjalan; jangan menguji update melalui uninstall. |

MIG-02/MIG-03 dan REL-03 dapat berstatus N/A pada release pertama dengan alasan belum ada schema/build release sebelumnya. Database v1 tetap harus bisa ditutup dan dibuka ulang tanpa berubah. AAB tidak diperlakukan sebagai file yang dapat langsung di-install dengan `adb install`.

Observasi tanpa traffic saja tidak membuktikan seluruh kebijakan privasi: sertakan review artifact. Jika backup/transfer tidak dapat diuji di environment yang tersedia, tandai bagian tersebut Blocked dan jelaskan cakupan yang belum dibuktikan; jangan menyimpulkan perilaku semua OEM hanya dari satu perangkat.

## 14. Pelaksanaan dan Automation

### 14.1 Urutan Kerja

1. Konfirmasi versi dokumen, keputusan terbuka, environment, serta fixture.
2. Jalankan formatter, analysis, U/W/G dan evaluasi coverage.
3. Jalankan I pada Android minimum/target dengan database terisolasi.
4. Jalankan pengujian lifecycle, aksesibilitas, privacy/artifact, dan performa pada perangkat.
5. Catat defect, perbaiki, retest kasus gagal, lalu jalankan regresi area terdampak.
6. Bangun candidate release final, jalankan smoke pada artifact final, dan buat laporan kelulusan.

Pada proyek satu pengembang, orang yang sama dapat menjalankan peran developer dan tester. Review acceptance criteria dan keputusan release tetap dicatat terpisah agar asumsi teknis tidak dianggap otomatis sebagai persetujuan produk.

### 14.2 Perintah Quality Gate

Perintah berikut dijalankan setelah proyek Flutter dan suite test tersedia; dokumen ini tidak menyatakan bahwa perintah tersebut sudah dijalankan.

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter test integration_test -d <android-device>
flutter build appbundle --release
```

Ganti `<android-device>` dengan ID target yang dipilih. Menjalankan integration suite tidak dengan sendirinya membuktikan force-stop/reboot; kasus itu memerlukan harness lifecycle atau eksekusi manual yang terdokumentasi. Build/signing dilakukan setelah konfigurasi release tersedia.

Coverage minimal 80% untuk masing-masing kelompok domain, formatter, dan view model sesuai sasaran dokumen 03. Hitung dari laporan coverage dengan scope file eksplisit; generated localization/build files boleh dikecualikan, business logic tidak. Coverage tinggi tidak menggantikan boundary test, SQLite nyata, dan acceptance criteria.

### 14.3 Frekuensi

| Pemicu | Suite |
| --- | --- |
| Perubahan domain/data | U terkait, repository I, total/order/persistence regression. |
| Perubahan UI/theme | W/G terkait, navigation/form regression, visual dan accessibility smoke. |
| Perubahan dependency/SDK/schema | Full automated suite, Android matrix, migration yang berlaku, artifact review. |
| Sebelum merge | Format, analysis, unit/widget/golden, integration, dan release build sebagaimana gate dokumen 03. |
| Sebelum release | Full P0/P1, manual/device, performance, privacy, final artifact smoke, laporan test. |

## 15. Hasil Test dan Defect Management

### 15.1 Status Test

| Status | Arti |
| --- | --- |
| Not Run | Belum dieksekusi pada candidate yang dinilai. |
| Pass | Actual result sesuai expected result dan ada bukti. |
| Fail | Actual result berbeda; sertakan defect ID. |
| Blocked | Tidak dapat dieksekusi karena prasyarat/environment; bukan Pass. |
| N/A | Tidak berlaku, dengan alasan dan persetujuan reviewer; bukan untuk menyembunyikan kegagalan. |

Template hasil eksekusi:

| Build / device | Case ID | Fixture | Status | Actual result / bukti | Defect / catatan |
| --- | --- | --- | --- | --- | --- |
| Belum ditentukan | FUN-02 | F-EMPTY | Not Run | — | — |

Bukti minimal berupa log automated test atau catatan langkah dan actual result. Sertakan screenshot/video untuk defect UI, snapshot/query data sintetis untuk integritas, serta hasil ukur untuk performa. Data test tidak memakai informasi finansial nyata.

### 15.2 Severity Defect

| Severity | Definisi | Kebijakan release |
| --- | --- | --- |
| S1 Critical | Kehilangan/korupsi data tersimpan, kebocoran data, crash yang menghalangi aplikasi. | Wajib diperbaiki. |
| S2 Major | CRUD/total/validasi salah, persistensi/offline gagal, atau aksi utama tidak dapat diakses. | Wajib diperbaiki. |
| S3 Moderate | Gangguan nonkritis dengan workaround, tidak melanggar acceptance criteria wajib. | Dapat dipertimbangkan sebagai known issue dengan pemilik dan alasan. |
| S4 Minor | Cosmetic kecil tanpa menghambat keterbacaan/perilaku. | Dicatat dan ditinjau; perubahan visual tetap mengikuti spesifikasi. |

Defect mencatat build/device, langkah reproduksi, expected/actual, fixture, severity, bukti, pemilik, status perbaikan, dan hasil retest. Bug total salah tetap penghalang release meskipun hanya muncul pada kombinasi input tertentu.

## 16. Entry, Exit, dan Keputusan Release

### 16.1 Entry Criteria

- Source/build dapat diidentifikasi dan suite terkait tersedia.
- Dependency/SDK terpin; device dan fixture siap serta terisolasi.
- Expected result dan kasus yang berlaku disepakati dari dokumen 01–04.
- Untuk release run: application ID, signing owner, publisher, serta kanal distribusi sudah ditentukan.

### 16.2 Exit Criteria

- Semua acceptance criteria US-01–US-05, FR-01–FR-08, dan NFR yang berlaku terverifikasi melalui traceability.
- Semua kasus P0/P1 yang berlaku Pass; tidak ada Not Run/Blocked yang belum diselesaikan pada cakupan wajib.
- Kasus conditional N/A memiliki alasan eksplisit; tidak dihitung sebagai Pass untuk menggelembungkan hasil.
- Tidak ada S1/S2 terbuka atau pelanggaran acceptance criteria. Known issue nonkritis memiliki keputusan dan pemilik tindak lanjut.
- Format, analysis, automated tests, coverage, integration Android, dan release build lulus.
- Budget performa, offline/restart/reboot, aksesibilitas, serta privacy/artifact checks memenuhi kriteria.
- Candidate final diidentifikasi dan smoke sesuai artifact distribusi selesai.
- Keputusan produk/konfigurasi pada bagian 18 ditutup sebelum release.

Ringkasan release mencatat jumlah Pass/Fail/Blocked/Not Run/N/A, device coverage aktual, defect tersisa, hasil performa, lokasi bukti, serta keputusan Go/No-Go oleh pemilik produk/release. Perubahan artifact setelah pengujian memerlukan retest cakupan yang terdampak dan smoke ulang.

## 17. Traceability

| Requirement / sumber | Kasus utama |
| --- | --- |
| US-01, FR-01 — Tambah/input | FUN-02/03, VAL-01–09, STA-02/04, LIF-02/03 |
| US-02, FR-03 — Riwayat/urutan | FUN-04/05, DAT-04/05, UI-05 |
| US-03, FR-04 — Total bulanan | FUN-05/06/08/10, VAL-15, DAT-05/11/14, STA-08/10 |
| US-04, FR-05 — Edit | FUN-07/08/17/18, DAT-03, STA-02 |
| US-05, FR-06 — Hapus | FUN-09/10/11, STA-03/05, DAT-06 |
| FR-02 — Kategori tetap | VAL-06/07, DAT-07 |
| FR-07, NFR-01 — Lokal/offline | DAT-01/02, LIF-01–07, SEC-01/03 |
| FR-08 — Validasi | VAL-01–13, STA-02, DAT-06/07/08 |
| NFR-02 — Performa | DAT-14, PERF-01–05 |
| NFR-03 — Reliability | DAT-02/08/10/13, STA-01–12, LIF-02–05, MIG-01–03 |
| NFR-04, UX requirements | FUN-12–16, UI-01–09, usability pada bagian 11.3 |
| NFR-05 — Privacy | SEC-01–04, LIF-06/07 |
| NFR-06 — Maintainability | Quality gates/coverage bagian 14; review kontrak fake dan dependency sesuai dokumen 03 |
| Dokumen 02 — Wise-inspired, navigation, state, accessibility | FUN-12–16, STA-01–06, UI-01–09, golden baseline |
| Dokumen 03 — MVVM, lifecycle, error, release | STA-01–12, LIF-01–07, PERF-01–05, SEC-01–04, REL-01–03 |
| Dokumen 04 — Invariant, schema, mapping, migration | VAL-01–15, DAT-01–14, MIG-01–03 |

## 18. Asumsi, Klarifikasi, dan Batas Bukti

| Topik | Baseline pengujian saat ini | Tindak lanjut |
| --- | --- | --- |
| Nominal maksimum | Rp999.999.999.999 per transaksi sesuai dokumen 02–04. | Ratifikasi pada PRD sebelum release; jika berubah, perbarui validator/schema/fixture bersama. |
| Rentang date picker | ±100 tahun; future date diizinkan; edit mencakup tanggal tersimpan. | Ratifikasi detail produk pada PRD sebagaimana catatan dokumen 03. |
| Android/SDK | API minimum 24 dan target 36 atau baseline lebih baru yang dipin. | Tinjau kembali kompatibilitas/kebutuhan distribusi saat persiapan release; jangan menganggap dokumen ini verifikasi kebijakan terkini. |
| Identitas/signing/distribusi | Mengikuti keputusan terbuka dokumen 03. | Ditentukan sebelum final artifact dan release testing. |
| Backup/transfer OEM | Config dan perilaku target perangkat harus diuji. | Laporkan keterbatasan device coverage serta keputusan sebelum release. |
| Schema/build pertama | Belum ada jalur upgrade dari release lama. | MIG-02/03 dan REL-03 conditional N/A sampai ada baseline release. |
| Eksekusi test | Dokumen ini hanya rencana. | Isi test report setelah implementasi dan suite tersedia; tidak ada klaim lulus saat dokumen dibuat. |

