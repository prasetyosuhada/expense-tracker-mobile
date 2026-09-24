# Technical Design Document

## Expense Tracker Android

| Informasi | Detail |
| --- | --- |
| Versi dokumen | 1.1 |
| Versi produk | MVP V0.1 |
| Platform | Android |
| Framework | Flutter |
| Bahasa pemrograman | Dart |
| Model aplikasi | Offline, satu pengguna, satu perangkat |
| Dokumen acuan | `docs/01-PRD.md` dan `docs/02-UX-UI-SPEC.md` |
| Style UI | Wise-inspired, berdasarkan style aktif `wise` dari needmcp |
| Status | Siap digunakan sebagai acuan implementasi MVP |

## 1. Tujuan Dokumen

Dokumen ini mendefinisikan rancangan teknis untuk mengimplementasikan Expense Tracker MVP V0.1. Cakupannya meliputi:

- Arsitektur aplikasi dan batas tanggung jawab setiap komponen.
- Struktur source code Flutter.
- Model domain dan schema database lokal.
- Kontrak repository dan aliran data.
- State management, navigasi, validasi, serta formatting.
- Error handling, privacy, reliability, dan performance.
- Strategi testing, build, dan release.

Dokumen ini mengutamakan implementasi yang kecil, mudah diuji, dan mudah dipahami. Jika terdapat konflik kebutuhan produk, `docs/01-PRD.md` menjadi sumber utama. Jika terdapat konflik perilaku antarmuka, `docs/02-UX-UI-SPEC.md` menjadi sumber utama.

## 2. Ringkasan Keputusan Teknis

| Area | Keputusan |
| --- | --- |
| Arsitektur | MVVM ringan dengan UI layer dan Data layer; domain model tetap independen dari UI dan database. |
| Organisasi kode | Feature-first untuk fitur `expenses`, dengan folder bersama yang minimal. |
| State management | `ChangeNotifier` dan `ListenableBuilder`, tanpa package state management eksternal. |
| Dependency injection | Constructor injection manual dari composition root. |
| Navigasi | `Navigator` bawaan Flutter dan `MaterialPageRoute`; `NavigationBar` + `IndexedStack` untuk dua destinasi utama. |
| Penyimpanan | SQLite melalui package `sqflite`. |
| ID transaksi | SQLite `INTEGER PRIMARY KEY AUTOINCREMENT`. |
| Nominal | Integer Rupiah; tidak menggunakan floating-point. |
| Tanggal transaksi | Date-only string `YYYY-MM-DD`, tanpa timezone. |
| Timestamp audit | UTC epoch milliseconds. |
| Kategori | Dart enum dengan kode stabil berbahasa Inggris di database. |
| Lokalisasi | Locale aplikasi dikunci ke `id_ID`; teks aplikasi disiapkan melalui Flutter localization. |
| Theme | Material 3 sebagai primitive dengan semantic token Wise-inspired yang disimpan lokal. |
| Font | Geist untuk display dan Inter untuk body; keduanya dibundel sebagai asset aplikasi. |
| Network | Tidak ada client HTTP, backend, analytics, atau permission internet pada release. |
| Testing | Unit, widget, dan integration test pada emulator/perangkat Android. |

### 2.1 Klarifikasi Produk yang Diperkenalkan

Technical Design menutup dua detail yang belum memiliki nilai eksplisit pada PRD:

- Nominal maksimum Rp999.999.999.999 per transaksi sebagai guardrail penyimpanan dan agregasi.
- Rentang date picker dinamis ±100 tahun dari tahun perangkat, dengan tanggal masa depan tetap diperbolehkan.

Keduanya telah diselaraskan ke UX/UI Spec. Karena PRD tetap menjadi sumber kebutuhan tertinggi, keputusan ini perlu diratifikasi pada revisi PRD berikutnya sebelum release jika diperlakukan sebagai aturan produk permanen.

## 3. Sasaran dan Non-Goals Teknis

### 3.1 Sasaran

- Seluruh CRUD dan ringkasan bulanan bekerja tanpa jaringan.
- Data tersimpan konsisten setelah aplikasi atau perangkat dimulai ulang.
- Tampilan Home dan Transactions selalu diperbarui setelah mutasi berhasil.
- Aturan produk dapat diuji tanpa harus merender widget.
- Database dapat dimigrasikan pada versi aplikasi berikutnya tanpa menghapus data.
- Dependency eksternal dijaga seminimal mungkin.

### 3.2 Non-Goals

- Backend, API client, sinkronisasi, dan conflict resolution.
- Arsitektur multi-module atau micro-package.
- Event sourcing, CQRS, atau distributed cache.
- Router deklaratif untuk deep link.
- Service locator atau dependency injection framework.
- ORM/code generator.
- Enkripsi database khusus aplikasi.
- Telemetry, remote logging, crash reporting, atau analytics eksternal.
- Pagination, search index, dan background job.

## 4. Technology Baseline

### 4.1 Flutter dan Dart

- Gunakan Flutter stable yang mendukung Android API 24 ke atas.
- Flutter SDK dan Dart SDK harus dipin saat proyek diinisialisasi dan digunakan konsisten di local development serta CI.
- Nomor patch aktual dicatat pada `README.md` atau file version manager yang dipilih ketika implementasi dimulai.
- `pubspec.lock` wajib di-commit karena produk ini adalah aplikasi, bukan package library.
- Gunakan Dart null safety dan lint resmi Flutter.

Saat dokumen ini dibuat, dokumentasi Flutter stable mencantumkan Android API 24 sebagai versi minimum yang didukung. Baseline tidak boleh diturunkan ke API yang sudah tidak didukung oleh Flutter SDK yang dipakai.

### 4.2 Android

| Konfigurasi | Nilai MVP |
| --- | --- |
| `minSdk` | 24 |
| `targetSdk` | 36 atau lebih baru jika diwajibkan saat rilis |
| `compileSdk` | Minimal sama dengan `targetSdk` dan kompatibel dengan Flutter stable yang dipin |
| Orientasi | Tidak dikunci; portrait menjadi layout utama dan landscape tetap usable |
| Application label | Expense Tracker |
| Release artifact utama | Android App Bundle (`.aab`) |

`applicationId` final harus ditentukan sebelum signing/release karena perubahan setelah publikasi menghasilkan aplikasi yang berbeda. Format yang disarankan adalah `com.<organisasi>.expensetracker`; jangan merilis dengan namespace `com.example`.

### 4.3 Dependency

Nomor versi tidak ditulis pada dokumen ini. Gunakan versi stable terbaru yang kompatibel ketika proyek diinisialisasi, pin hasil resolusinya di `pubspec.lock`, lalu ubah melalui perubahan yang dapat diuji.

Runtime dependency:

| Dependency | Tujuan | Alasan |
| --- | --- | --- |
| `flutter_localizations` dari Flutter SDK | Lokalisasi komponen Material ke Bahasa Indonesia. | Implementasi resmi Flutter. |
| `intl` | Format tanggal dan angka IDR. | Menghindari formatter locale buatan sendiri untuk display. |
| `sqflite` | Database SQLite pada Android. | Mendukung query, constraint, index, migration, dan CRUD lokal. |
| `path` | Membentuk path database dengan aman. | Digunakan bersama `getDatabasesPath()`. |
| `characters` | Menghitung catatan berdasarkan karakter yang dipersepsikan pengguna. | Emoji atau grapheme tidak dihitung sebagai beberapa karakter secara keliru. |

Development dependency:

| Dependency | Tujuan |
| --- | --- |
| `flutter_test` dari Flutter SDK | Unit dan widget test. |
| `integration_test` dari Flutter SDK | End-to-end test di Android. |
| `flutter_lints` | Static analysis baseline. |

Dependency berikut sengaja tidak ditambahkan untuk MVP:

- Provider, Riverpod, Bloc, atau package state management lain.
- `go_router` atau router eksternal.
- Drift, Floor, Isar, Hive, atau ORM/local store kedua.
- GetIt atau service locator.
- Freezed, JSON serialization generator, dan build runner.
- UUID package.

Dependency baru hanya boleh ditambahkan jika mengurangi risiko atau kompleksitas total secara terukur dan dicatat melalui ADR.

### 4.4 UI Style Assets

- needmcp digunakan saat design/development untuk memperoleh referensi style; aplikasi tidak memanggil needmcp saat runtime.
- Token yang telah disetujui disalin menjadi semantic constants di source code agar build deterministik dan offline.
- Geist dan Inter dibundel melalui `pubspec.yaml`; jangan menggunakan runtime font loader atau request ke Google Fonts.
- File lisensi font wajib disimpan bersama asset font masing-masing: `assets/fonts/geist/OFL.txt` dan `assets/fonts/inter/OFL.txt`. Kedua font berlisensi SIL OFL 1.1 dan boleh di-bundle serta didistribusikan dalam aplikasi.
- Jika font tidak dapat dilisensikan atau dibundel, perubahan fallback harus disetujui di UX/UI Spec sebelum implementasi.

## 5. Arsitektur Aplikasi

### 5.1 Gaya Arsitektur

Aplikasi menggunakan MVVM ringan yang disesuaikan dengan ukuran MVP:

```text
┌───────────────────────────────────────────────────────┐
│ UI Layer                                              │
│                                                       │
│ View/Widget ──event──> ViewModel                      │
│      ^                    │                           │
│      └──── UI state ──────┘                           │
└───────────────────────────│───────────────────────────┘
                            │ domain model / commands
┌───────────────────────────▼───────────────────────────┐
│ Data Layer                                            │
│                                                       │
│ ExpenseRepository interface                           │
│              ▲                                        │
│              │                                        │
│ SqliteExpenseRepository ──> ExpenseDatabase ──> SQLite│
└───────────────────────────────────────────────────────┘
```

Domain model dan validator berada pada feature yang sama, tetapi tidak dibentuk sebagai use-case layer tersendiri. View model boleh memanggil repository secara langsung karena hanya ada satu repository dan business logic masih sederhana.

### 5.2 Dependency Rule

- View boleh bergantung pada view model dan widget bersama.
- View tidak boleh mengeksekusi SQL atau memanggil `sqflite`.
- View model boleh bergantung pada interface repository, domain model, validator, clock, dan formatter yang relevan.
- Implementasi repository boleh bergantung pada database service serta mapper.
- Domain model tidak boleh mengimpor Flutter Material, `sqflite`, atau class widget.
- Database row tidak boleh dikirim langsung ke UI.
- Tidak ada global mutable singleton untuk view model atau repository.

### 5.3 Composition Root

`AppBootstrap` menjadi satu-satunya tempat yang membentuk dependency inti production. View model dibentuk oleh pemilik lifecycle-nya menggunakan dependency tersebut:

```text
AppBootstrap
  ├── SystemClock
  ├── ExpenseDatabase
  └── SqliteExpenseRepository
             ↓ constructor injection
          AppShell / Form Route
             ↓ creates and owns
          ViewModels → Views
```

`AppShell` memiliki dan men-dispose Home/Transactions view model. Form route memiliki dan men-dispose form view model. Semua dependency diberikan melalui constructor. Test dapat mengganti repository dengan in-memory fake tanpa mengubah production code.

### 5.4 Mengapa Domain Layer Lengkap Tidak Digunakan

Use-case class seperti `CreateExpenseUseCase` untuk setiap operasi belum memberikan manfaat yang sebanding dengan boilerplate pada MVP ini. Use-case layer baru dipertimbangkan jika:

- Sebuah aturan digunakan oleh beberapa view model dan tidak cocok berada di repository.
- Satu tindakan harus menggabungkan beberapa repository.
- Business logic menjadi sulit diuji atau dibaca di view model.

## 6. Struktur Source Code

Struktur target:

```text
expense-tracker-mobile/
├── android/
├── assets/
│   └── fonts/
│       ├── geist/
│       │   ├── Geist-Bold.ttf
│       │   └── Geist-Black.ttf
│       └── inter/
│           ├── Inter-Regular.ttf
│           └── Inter-SemiBold.ttf
├── docs/
├── integration_test/
│   └── expense_flows_test.dart
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── app_bootstrap.dart
│   │   └── app_shell.dart
│   ├── core/
│   │   ├── clock/
│   │   │   ├── app_clock.dart
│   │   │   └── system_clock.dart
│   │   ├── errors/
│   │   │   └── app_failure.dart
│   │   ├── formatting/
│   │   │   ├── idr_formatter.dart
│   │   │   └── id_date_formatter.dart
│   │   ├── l10n/
│   │   │   ├── app_id.arb
│   │   │   └── generated/
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       ├── app_elevation.dart
│   │       ├── app_shapes.dart
│   │       ├── app_spacing.dart
│   │       ├── app_typography.dart
│   │       ├── category_colors.dart
│   │       ├── component_themes.dart
│   │       └── app_theme.dart
│   └── features/
│       └── expenses/
│           ├── domain/
│           │   ├── expense.dart
│           │   ├── expense_category.dart
│           │   ├── expense_change.dart
│           │   ├── expense_date.dart
│           │   ├── expense_draft.dart
│           │   ├── expense_month.dart
│           │   ├── expense_repository.dart
│           │   ├── home_summary.dart
│           │   └── expense_validator.dart
│           ├── data/
│           │   ├── expense_database.dart
│           │   ├── expense_mapper.dart
│           │   └── sqlite_expense_repository.dart
│           └── presentation/
│               ├── home/
│               │   ├── home_screen.dart
│               │   ├── home_state.dart
│               │   └── home_view_model.dart
│               ├── transactions/
│               │   ├── transactions_screen.dart
│               │   ├── transactions_state.dart
│               │   └── transactions_view_model.dart
│               ├── expense_form/
│               │   ├── expense_form_screen.dart
│               │   ├── expense_form_state.dart
│               │   └── expense_form_view_model.dart
│               └── widgets/
│                   ├── expense_list_item.dart
│                   ├── expense_empty_state.dart
│                   └── monthly_total_card.dart
├── test/
│   ├── core/
│   ├── features/expenses/domain/
│   ├── features/expenses/presentation/
│   ├── helpers/
│   │   ├── fake_app_clock.dart
│   │   └── fake_expense_repository.dart
│   └── widget/
├── analysis_options.yaml
└── pubspec.yaml
```

Aturan struktur:

- Satu file berisi satu class utama kecuali sealed state yang sangat terkait.
- Widget reusable lintas tiga layar ditempatkan di `presentation/widgets`.
- Helper yang hanya digunakan satu layar tetap berada dekat layar tersebut.
- Folder `core` tidak boleh menjadi tempat pembuangan kode yang tidak jelas kepemilikannya.
- Generated localization files tidak diedit manual.
- Asset font hanya memuat weight yang benar-benar digunakan agar ukuran artifact tetap terkendali.

## 7. Domain Model

### 7.1 Expense

```dart
final class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int amount;
  final ExpenseCategory category;
  final ExpenseDate transactionDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Aturan:

- Model immutable.
- `amount` adalah bilangan bulat Rupiah.
- `transactionDate` hanya memiliki tahun, bulan, dan hari.
- `createdAt` dan `updatedAt` selalu UTC pada domain boundary.
- `note` bernilai `null` jika kosong setelah trimming.
- Equality untuk kebutuhan test harus membandingkan seluruh field.

### 7.2 ExpenseDraft

`ExpenseDraft` mewakili data valid yang belum memiliki ID dan timestamp persistence:

```dart
final class ExpenseDraft {
  const ExpenseDraft({
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.note,
  });

  final int amount;
  final ExpenseCategory category;
  final ExpenseDate transactionDate;
  final String? note;
}
```

Form input mentah tidak langsung menjadi `ExpenseDraft`. View model memvalidasi dan menormalisasi input terlebih dahulu.

### 7.3 ExpenseCategory

Kategori menggunakan enum dengan kode persistence stabil:

| Enum | Kode database | Label UI |
| --- | --- | --- |
| `food` | `food` | Makanan |
| `transportation` | `transportation` | Transportasi |
| `shopping` | `shopping` | Belanja |
| `bills` | `bills` | Tagihan |
| `other` | `other` | Lainnya |

Label Bahasa Indonesia tidak disimpan di database. Mapper melakukan konversi kode database ke enum; localization mengubah enum menjadi label UI.

Kode kategori yang tidak dikenali dianggap sebagai data korup dan menghasilkan `CorruptDataFailure`, bukan diam-diam diubah menjadi `other`.

### 7.4 ExpenseDate

`ExpenseDate` adalah value object date-only:

- Memiliki `year`, `month`, dan `day`.
- Memvalidasi tanggal kalender ketika dibentuk.
- Dapat dikonversi dari/ke string ISO `YYYY-MM-DD`.
- Tidak menyimpan jam atau timezone.
- Dapat dibuat dari komponen lokal `DateTime` milik date picker tanpa memanggil `toUtc()`.

Tujuannya adalah mencegah tanggal transaksi bergeser satu hari akibat konversi timezone.

Rentang date picker MVP:

- `firstDate`: 100 tahun sebelum tahun perangkat saat ini, tanggal 1 Januari.
- `lastDate`: 100 tahun setelah tahun perangkat saat ini, tanggal 31 Desember.
- Tanggal masa depan diperbolehkan sesuai keputusan UX saat ini.

Data yang sudah tersimpan tetap harus dapat dirender walaupun suatu saat berada di luar rentang picker dinamis.
Ketika mengedit data tersebut, batas picker diperluas agar selalu mencakup tanggal awal transaksi.

### 7.5 Batas Nominal

| Aturan | Nilai |
| --- | --- |
| Minimum | `1` |
| Maksimum teknis per transaksi | `999_999_999_999` Rupiah |
| Desimal | Tidak diperbolehkan |
| Nilai negatif | Tidak diperbolehkan |

Batas maksimum mencegah overflow agregasi dan menjaga nominal tetap dapat ditampilkan. Pesan UI untuk nilai di atas batas adalah **Nominal terlalu besar**. Keputusan ini perlu diselaraskan ke UX/UI Spec dan Data Model jika batas produk berubah.

### 7.6 Aturan Catatan

- Maksimal 100 grapheme/user-perceived characters.
- Leading dan trailing whitespace dihapus.
- Whitespace internal dan baris baru dipertahankan.
- Input yang hanya berisi whitespace disimpan sebagai `null`.
- Repository memvalidasi ulang panjang grapheme sebelum write. SQLite `length()` tidak digunakan sebagai constraint 100 karakter karena perhitungannya dapat berbeda untuk grapheme majemuk seperti emoji.

## 8. Database Design

### 8.1 Pilihan Database

SQLite dipilih karena data bersifat terstruktur, memerlukan CRUD, pengurutan, filter bulan, agregasi `SUM`, constraint, dan migration. Implementasi menggunakan `sqflite` dengan satu database instance per proses aplikasi.

| Properti | Nilai |
| --- | --- |
| Nama file | `expense_tracker.db` |
| Schema version awal | `1` |
| Lokasi | App-specific database directory dari `getDatabasesPath()` |
| Encoding tanggal transaksi | `TEXT`, ISO `YYYY-MM-DD` |
| Encoding timestamp | `INTEGER`, UTC epoch milliseconds |

### 8.2 Schema Version 1

```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount INTEGER NOT NULL
    CHECK (amount > 0 AND amount <= 999999999999),
  category TEXT NOT NULL
    CHECK (category IN ('food', 'transportation', 'shopping', 'bills', 'other')),
  transaction_date TEXT NOT NULL
    CHECK (length(transaction_date) = 10),
  note TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_expenses_order
ON expenses (transaction_date DESC, created_at DESC, id DESC);
```

Constraint `length(transaction_date) = 10` bukan pengganti validasi kalender. Repository mapper tetap wajib mem-parse ISO date dengan ketat.

### 8.3 Mapping Database

| Column | SQLite | Dart | Aturan |
| --- | --- | --- | --- |
| `id` | INTEGER | `int` | Dibuat database. |
| `amount` | INTEGER | `int` | Rupiah, bukan floating-point. |
| `category` | TEXT | `ExpenseCategory` | Kode enum stabil. |
| `transaction_date` | TEXT | `ExpenseDate` | ISO date-only. |
| `note` | TEXT/NULL | `String?` | Sudah dinormalisasi. |
| `created_at` | INTEGER | `DateTime` | UTC epoch milliseconds. |
| `updated_at` | INTEGER | `DateTime` | UTC epoch milliseconds. |

`ExpenseMapper` menjadi satu-satunya komponen yang mengubah row database menjadi domain model dan sebaliknya.

### 8.4 Query Utama

Seluruh transaksi:

```sql
SELECT *
FROM expenses
ORDER BY transaction_date DESC, created_at DESC, id DESC;
```

Lima transaksi terbaru:

```sql
SELECT *
FROM expenses
ORDER BY transaction_date DESC, created_at DESC, id DESC
LIMIT 5;
```

Total bulan berjalan:

```sql
SELECT COALESCE(SUM(amount), 0) AS total
FROM expenses
WHERE transaction_date >= ?
  AND transaction_date < ?;
```

Parameter menggunakan awal bulan inklusif dan awal bulan berikutnya eksklusif, misalnya `2026-09-01` dan `2026-10-01`. Perbandingan string valid karena format ISO memiliki urutan leksikografis yang sama dengan urutan kalender.

Update dan delete selalu menggunakan parameter binding:

```sql
UPDATE expenses
SET amount = ?, category = ?, transaction_date = ?, note = ?, updated_at = ?
WHERE id = ?;

DELETE FROM expenses WHERE id = ?;
```

Nilai user tidak pernah digabungkan langsung ke string SQL.

### 8.5 Create, Update, dan Delete

Create:

- Repository memvalidasi `ExpenseDraft`.
- `created_at` dan `updated_at` diisi timestamp UTC yang sama.
- Insert mengembalikan ID database.
- Repository membaca atau membentuk domain object final setelah insert berhasil.
- Change event dipublikasikan hanya setelah operasi berhasil.

Update:

- `id` dan `created_at` tidak berubah.
- `updated_at` diganti dengan waktu UTC saat operasi.
- Jumlah row terpengaruh harus tepat satu.
- Nol row menghasilkan `NotFoundFailure`.

Delete:

- Menghapus berdasarkan ID.
- Jumlah row terpengaruh harus tepat satu.
- Nol row menghasilkan `NotFoundFailure`.
- Tidak ada soft delete atau undo pada MVP.

### 8.6 Initialization dan Migration

- Database dibuka secara lazy ketika repository pertama kali digunakan.
- Gunakan `singleInstance: true`.
- Future pembukaan yang gagal tidak boleh disimpan permanen; retry harus mencoba membuka kembali.
- `onCreate` membuat seluruh schema versi 1 dalam satu transaction.
- `onUpgrade` menggunakan langkah migration eksplisit per versi.
- Jangan menggunakan `DROP TABLE` sebagai strategi migration release.
- Jangan menghapus/recreate database otomatis ketika terjadi error atau korupsi karena dapat menghilangkan data pengguna.

Template migration:

```dart
Future<void> migrate(Database db, int oldVersion, int newVersion) async {
  for (var version = oldVersion + 1; version <= newVersion; version++) {
    switch (version) {
      // case 2: await migrateToV2(db);
      default:
        throw StateError('Missing migration for schema version $version');
    }
  }
}
```

Setiap schema baru wajib memiliki migration test dari seluruh versi release yang masih didukung.

## 9. Repository Contract

### 9.1 Interface

```dart
abstract interface class ExpenseRepository {
  Stream<ExpenseChange> get changes;

  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  });

  Future<List<Expense>> getAll();
  Future<Expense> create(ExpenseDraft draft);
  Future<Expense> update({required int id, required ExpenseDraft draft});
  Future<void> delete(int id);
}
```

`HomeSummary` berisi total bulan yang diminta dan maksimal lima transaksi terbaru global. Dua query Home dijalankan dalam read transaction yang sama agar menghasilkan snapshot konsisten.

`ExpenseChange` adalah enum `created`, `updated`, dan `deleted`. Payload data tidak diperlukan karena subscriber selalu memuat snapshot kanonik dari SQLite.

### 9.2 Change Notification

`SqliteExpenseRepository` memiliki broadcast stream in-process:

- Event dikirim setelah create, update, atau delete berhasil di-commit.
- Home dan Transactions view model subscribe ke stream.
- Saat event diterima, kedua view model meminta snapshot terbaru dari repository.
- Stream tidak menyimpan data dan bukan pengganti SQLite sebagai source of truth.
- Subscription selalu dibatalkan saat view model di-dispose.

Pendekatan ini mencegah layar dalam `IndexedStack` menampilkan data stale tanpa memperkenalkan state management package eksternal.

### 9.3 Fake Repository untuk Test

`FakeExpenseRepository`:

- Menggunakan koleksi in-memory.
- Mengimplementasikan kontrak dan aturan urutan yang sama.
- Dapat dikonfigurasi untuk menghasilkan failure.
- Tidak digunakan pada production build.
- Tidak dianggap sebagai pengganti integration test SQLite.

## 10. State Management

### 10.1 View Model

Setiap layar memiliki view model yang meng-extend `ChangeNotifier`:

| View model | Tanggung jawab |
| --- | --- |
| `HomeViewModel` | Memuat total bulan berjalan dan lima transaksi terbaru. |
| `TransactionsViewModel` | Memuat seluruh transaksi dan menjalankan delete. |
| `ExpenseFormViewModel` | Menyimpan input mentah, validasi, dirty state, create/update, dan submit state. |

View menggunakan `ListenableBuilder` atau `AnimatedBuilder` untuk rebuild hanya pada subtree yang membutuhkan state tersebut.

### 10.2 Load State

Home dan Transactions menggunakan state immutable:

```text
initial → loading → data
                  ↘ error
error ──retry──> loading
data ──change──> refreshing → data/error
```

Aturan:

- `initial` tidak dirender sebagai empty state.
- `loading` tanpa data menampilkan initial loading indicator.
- `refreshing` mempertahankan data lama sampai snapshot baru berhasil.
- Error initial menampilkan full content error state.
- Error refresh mempertahankan data lama dan menampilkan snackbar; data tidak diganti menjadi kosong.
- Hasil request lama tidak boleh menimpa request yang lebih baru; gunakan generation/request token sederhana.

### 10.3 Form State

Form state minimal berisi:

```text
amountText
selectedCategory
selectedDate
noteText
fieldErrors
hasSubmitted
isDirty
isSubmitting
submitFailure
```

Input controller widget boleh berada pada State object layar, tetapi nilai kanonik dan validasi berada di view model. Controller harus di-dispose bersama screen.

### 10.4 Delete State

- Delete state dilacak per ID agar item lain tidak ikut terlihat loading.
- Tombol dialog dinonaktifkan selama operasi.
- Delete ganda untuk ID yang sama dicegah.
- Setelah berhasil, dialog ditutup dan repository change event memicu refresh.

### 10.5 Pergantian Bulan Kalender

- `HomeViewModel` menyimpan bulan yang dipakai oleh snapshot saat ini.
- Ketika aplikasi kembali ke foreground, Home membandingkannya dengan bulan lokal dari `AppClock` dan refresh jika berbeda.
- Selama aplikasi terus berada di foreground, satu timer dijadwalkan ke awal hari lokal berikutnya; ketika aktif, Home mengevaluasi ulang bulan lalu menjadwalkan timer berikutnya.
- Timer dibatalkan ketika view model di-dispose.
- Timer tidak menulis data dan tidak membutuhkan background service.

## 11. Aliran Data

### 11.1 Startup dan Initial Load

```text
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → AppBootstrap membentuk dependency
  → runApp(ExpenseTrackerApp)
  → AppShell membuat HomeViewModel dan TransactionsViewModel
  → ViewModel.load()
  → Repository membuka SQLite secara lazy
  → Query data
  → Mapper membuat domain model
  → ViewModel menerbitkan UI state
  → View melakukan render
```

Database tidak dibuka sebelum `runApp()` agar kegagalan initialization dapat ditampilkan sebagai read error state dan pengguna dapat menekan **Coba Lagi**.

### 11.2 Tambah Pengeluaran

```text
ExpenseFormScreen
  → ExpenseFormViewModel.submit()
  → validasi dan normalisasi
  → ExpenseRepository.create(draft)
  → INSERT SQLite
  → publish repository change event
  → form mengembalikan success result
  → layar asal menampilkan snackbar
  → Home/Transactions reload snapshot
```

Jika insert gagal, form tidak ditutup dan seluruh input dipertahankan.

### 11.3 Edit Pengeluaran

```text
Expense item
  → buka form dengan Expense immutable
  → user mengubah field
  → validasi
  → ExpenseRepository.update(id: id, draft: draft)
  → UPDATE SQLite WHERE id = ?
  → publish change event
  → tutup form dan tampilkan feedback
```

Perhitungan total tidak diedit secara incremental di UI. Home selalu meminta agregasi baru dari database sehingga perpindahan tanggal antarbulan ditangani secara benar.

### 11.4 Hapus Pengeluaran

```text
Menu item
  → dialog konfirmasi
  → ExpenseRepository.delete(id)
  → DELETE SQLite WHERE id = ?
  → publish change event
  → tutup dialog
  → reload Home dan Transactions
  → tampilkan snackbar
```

## 12. Navigasi Teknis

### 12.1 AppShell

`AppShell` menggunakan:

- `Scaffold`.
- Material 3 `NavigationBar` dengan Beranda dan Transaksi.
- `IndexedStack` agar posisi scroll serta state kedua destinasi dipertahankan.
- Satu extended floating action button yang membuka form tambah dari tab aktif.

Selected index berada pada state `AppShell`. Menekan tombol Back pada Transactions mengubah selected index ke Home; Back pada Home mengikuti perilaku keluar Android.

### 12.2 Form Route

- Dibuka dengan `Navigator.push` dan `MaterialPageRoute`.
- Mode tambah menerima tidak ada `Expense`.
- Mode edit menerima `Expense` yang dipilih.
- Route mengembalikan enum result `created`, `updated`, atau `none`.
- Snackbar success ditampilkan oleh screen asal setelah route selesai.
- Proteksi perubahan belum disimpan menggunakan API pop interception Flutter yang tidak deprecated pada SDK yang dipin.

Router deklaratif belum dibutuhkan karena MVP tidak memiliki deep link, web URL, authentication redirect, atau nested route kompleks.

## 13. Validasi dan Normalisasi

### 13.1 Boundary Validasi

Validasi dilakukan pada dua lapisan:

1. `ExpenseFormViewModel` menghasilkan pesan field yang spesifik untuk UX.
2. Repository/domain validator menolak data tidak valid dari pemanggil mana pun.

Database constraint menjadi pertahanan terakhir, bukan sumber utama pesan pengguna.

### 13.2 Nominal

- Input formatter menerima digit `0–9` saja.
- Separator ribuan hanya tampilan dan dihapus sebelum parsing.
- String kosong berbeda dari nilai nol.
- Parsing menggunakan base 10.
- Rentang valid `1..999_999_999_999`.

| Kondisi | Pesan UI |
| --- | --- |
| Kosong | Nominal wajib diisi |
| Nol | Nominal harus lebih besar dari 0 |
| Gagal diproses | Nominal tidak valid |
| Di atas maksimum | Nominal terlalu besar |

### 13.3 Kategori

- Nilai wajib dipilih dari `ExpenseCategory`.
- Input string bebas tidak diterima.
- Nilai kosong menampilkan **Kategori wajib dipilih**.

### 13.4 Tanggal

- Selalu berasal dari date picker atau nilai transaksi yang tersimpan.
- Konversi menggunakan komponen lokal tahun/bulan/hari.
- Repository menolak ISO string atau value object yang bukan tanggal kalender valid.

### 13.5 Catatan

- Limit input 100 grapheme.
- Normalize dengan trim pada submit.
- Setelah trim, string kosong menjadi `null`.
- Character counter mengikuti nilai sebelum trim agar sesuai yang sedang diketik pengguna.

## 14. Localization dan Formatting

### 14.1 Locale

- `MaterialApp.locale` ditetapkan ke `Locale('id', 'ID')`.
- `supportedLocales` hanya berisi `id_ID` untuk MVP.
- Gunakan delegate dari `flutter_localizations` agar date picker dan komponen Material menggunakan Bahasa Indonesia.
- Semua user-facing strings ditempatkan pada ARB, termasuk validation dan error message.
- Jangan menulis string UI langsung di repository atau database service.

### 14.2 Rupiah

- Display formatter menggunakan locale `id_ID`, tanpa digit desimal.
- Output akhir dinormalisasi agar mengikuti UX: `Rp25.000` tanpa spasi.
- Input formatter terpisah dari display formatter.
- Domain dan database hanya menerima integer tanpa simbol atau separator.

### 14.3 Tanggal

| Konteks | Pattern |
| --- | --- |
| Form | `d MMMM yyyy` |
| List item | `d MMM yyyy` |
| Bulan Home | `MMMM yyyy` |

Formatter hanya menerima `ExpenseDate` untuk tanggal transaksi. `createdAt` dan `updatedAt` tidak ditampilkan pada MVP.

### 14.4 Clock Abstraction

`AppClock` menyediakan `DateTime now()`:

- Production menggunakan `SystemClock`.
- Test menggunakan `FakeAppClock` dengan waktu tetap.
- Home mengambil bulan berjalan dari local components `clock.now()`.
- Timestamp persistence menggunakan `clock.now().toUtc()`.

Abstraksi ini membuat perhitungan bulan dan pergantian tahun dapat diuji secara deterministik tanpa package tambahan.

## 15. Error Handling

### 15.1 Failure Types

Exception plugin tidak boleh bocor ke UI. Data layer memetakannya menjadi failure aplikasi:

| Failure | Contoh | Perlakuan UI |
| --- | --- | --- |
| `ValidationFailure` | Amount di luar batas. | Field error yang spesifik. |
| `StorageFailure` | Database gagal dibuka/query gagal. | Error state atau snackbar retry. |
| `NotFoundFailure` | ID edit/hapus sudah tidak ada. | Snackbar gagal dan reload snapshot. |
| `CorruptDataFailure` | Kategori/tanggal row tidak valid. | Jangan render data seolah valid; tampilkan read error. |
| `UnexpectedFailure` | Error yang belum dipetakan. | Pesan generik; tidak tampilkan detail internal. |

Gunakan satu pola error secara konsisten: typed exception atau sealed result. Jangan mencampur keduanya pada kontrak repository. Pilihan implementasi yang disarankan untuk MVP adalah typed application exception pada data boundary, lalu view model mengubahnya menjadi UI state.

### 15.2 Logging

- Debug build boleh menggunakan `debugPrint` untuk stack trace teknis.
- Release build tidak mencatat nominal, catatan, atau isi transaksi.
- Pesan log tidak boleh berisi path database lengkap atau data pengguna.
- Tidak ada pengiriman log atau crash report ke layanan eksternal pada MVP.
- Error storage tidak memicu penghapusan database otomatis.

### 15.3 Recovery

- Initial read gagal: tampilkan **Coba Lagi** dan buka/query database kembali.
- Create/update gagal: pertahankan form dan izinkan submit ulang.
- Delete gagal: pertahankan transaksi dan izinkan pengguna mencoba ulang.
- Refresh gagal setelah sebelumnya memiliki data: pertahankan snapshot lama dan beri feedback.
- Data korup: tampilkan error, jangan skip row secara diam-diam, dan jangan reset database.

## 16. Privacy dan Security

### 16.1 Data Boundary

- Semua data transaksi disimpan di app-specific internal storage.
- Database tidak diletakkan di shared/external storage.
- Tidak ada network client atau SDK yang mengirim data keluar perangkat.
- Tidak ada account identifier, advertising ID, contact, location, camera, atau microphone access.

### 16.2 Android Permission

Release manifest tidak meminta permission berbahaya dan tidak mendeklarasikan permission `INTERNET`. Debug/profile manifest boleh memiliki kebutuhan tooling Flutter, tetapi tidak boleh ikut ke release merged manifest.

Merged manifest release harus diperiksa sebagai bagian release checklist.

### 16.3 Backup

Karena PRD menyatakan tidak ada cloud backup dan data tetap di perangkat:

- Set `android:allowBackup="false"` pada application release.
- Konfigurasikan `android:fullBackupContent` untuk Android 11 ke bawah.
- Konfigurasikan `android:dataExtractionRules` untuk Android 12 ke atas.
- Exclude seluruh domain `database` dari cloud backup.
- Verifikasi perilaku device-to-device transfer sesuai aturan Android yang dipakai.

Kebijakan backup harus diuji pada manifest hasil merge, bukan hanya source manifest.

### 16.4 Encryption

MVP menggunakan SQLite biasa dan perlindungan app sandbox/keamanan perangkat Android. Database tidak memiliki encryption key khusus aplikasi. Konsekuensinya harus dipahami:

- Aplikasi tidak mengklaim database terenkripsi secara independen.
- Perangkat yang sudah di-root atau terkompromi berada di luar threat model MVP.
- Jika product requirement berikutnya membutuhkan proteksi at-rest tambahan, buat ADR dan evaluasi SQLCipher serta pengelolaan key Android Keystore.

### 16.5 Data Lifecycle

- Data bertahan sampai dihapus pengguna melalui aplikasi, clear app data, atau uninstall.
- Delete dari UI bersifat permanen pada database MVP.
- Tidak ada recycle bin, export, atau recovery otomatis.
- Debug seed data tidak boleh ada pada release build.

## 17. Reliability dan Data Consistency

- Satu instance database digunakan dalam satu proses aplikasi.
- Operasi write ditunggu sampai selesai sebelum UI menyatakan berhasil.
- Tombol submit/delete dinonaktifkan untuk mencegah request ganda.
- Repository change event baru dikirim setelah write berhasil.
- Home tidak menghitung total dari string formatted atau widget state.
- Edit mempertahankan `id` dan `createdAt`.
- Query selalu memiliki deterministic tie-breaker `id DESC` setelah `created_at DESC`.
- Tidak ada write dari background isolate pada MVP.
- App lifecycle pause/resume tidak menutup database secara paksa.
- Ketika aplikasi kembali ke foreground, view model refresh jika data belum pernah berhasil dimuat, state sebelumnya error, atau bulan lokal telah berubah.

## 18. Performance

### 18.1 Strategi

- Gunakan index komposit untuk urutan daftar dan range bulan.
- Gunakan `LIMIT 5` di SQL; jangan mengambil semua data hanya untuk Home.
- Gunakan `SUM` di SQLite; jangan menghitung total dari teks atau seluruh list UI.
- Transactions menggunakan `ListView.builder` agar widget dibuat secara lazy.
- Hindari rebuild seluruh app; batasi listener ke screen atau komponen terkait.
- Formatter tanggal/angka yang reusable boleh di-cache, bukan dibuat berulang untuk setiap frame.
- Tidak menjalankan query atau parsing berat di method `build()`.

### 18.2 Engineering Budget

Target berikut diukur pada release/profile build di perangkat Android kelas menengah, dengan 10.000 transaksi lokal:

| Aktivitas | Target |
| --- | --- |
| Cold start sampai konten/valid error state | ≤ 2 detik |
| Query Home | ≤ 300 ms |
| Membuka daftar transaksi | ≤ 500 ms |
| Create/update/delete dan refresh UI | ≤ 500 ms |
| Scroll daftar | Tidak menunjukkan jank berulang yang terlihat pengguna |

Angka ini adalah engineering budget untuk memenuhi NFR, bukan SLA eksternal. Jika daftar 10.000 item tidak memenuhi budget, optimalkan query dan rendering terlebih dahulu; pagination hanya ditambahkan melalui perubahan scope.

## 19. UI Theme dan Accessibility Implementation

### 19.1 Theme Architecture

`AppTheme.light()` membentuk satu `ThemeData` Material 3 dari semantic token lokal. Widget tidak membaca payload needmcp dan tidak mengetahui nama style sumber.

```text
needmcp style:wise (design-time reference)
             ↓ reviewed mapping
AppColors / AppTypography / AppShapes / AppSpacing
             ↓
ComponentThemes
             ↓
ThemeData + small semantic extensions
             ↓
Flutter widgets
```

Gunakan built-in theme API untuk komponen standar. `ThemeExtension` hanya digunakan untuk token yang tidak memiliki tempat semantik di `ColorScheme`, misalnya category colors atau summary-card colors.

### 19.2 Color Mapping

Mapping minimum ke Flutter:

| Semantic token | Nilai | Mapping utama |
| --- | --- | --- |
| `primary` | `#9FE870` | `ColorScheme.primary` |
| `onPrimary` | `#163300` | `ColorScheme.onPrimary` |
| `primaryContainer` | `#E2F6D5` | `ColorScheme.primaryContainer` |
| `surface` | `#FFFFFF` | `ColorScheme.surface` |
| `surfaceContainer` | `#F5F6F4` | Surface container/background section |
| `surfaceContainerHighest` | `#E8EBE6` | Disabled/pressed surface |
| `onSurface` | `#0E0F0C` | `ColorScheme.onSurface` |
| `onSurfaceVariant` | `#454745` | Secondary text |
| `outline` | `rgba(14,15,12,0.48)` | Input outline |
| `outlineVariant` | `rgba(14,15,12,0.08)` | Divider/card outline |
| `error` | `#D03238` | `ColorScheme.error` |
| `onError` | `#FFFFFF` | `ColorScheme.onError` |
| `scrim` | `rgba(14,15,12,0.50)` | Modal barrier |

`#CDFFAD`, `#8AD05E`, `rgba(22,51,0,0.60)`, `#1E201C`, dan `#FCFCFC` disimpan sebagai interaction/snackbar tokens karena tidak seluruhnya memiliki slot langsung pada `ColorScheme`.

Aturan implementasi:

- Gunakan nilai ARGB eksplisit pada `AppColors`; jangan parse hex saat runtime.
- Jangan meletakkan raw `Color(...)` di feature widget kecuali fixture test.
- Gunakan `categoryColors` theme extension untuk lima pasangan warna ikon kategori.
- Status success/danger tidak boleh menggunakan primary lime sebagai satu-satunya indikator.

### 19.3 Typography dan Font Assets

Daftarkan family pada `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Geist
      fonts:
        - asset: assets/fonts/geist/Geist-Bold.ttf
          weight: 700
        - asset: assets/fonts/geist/Geist-Black.ttf
          weight: 900
    - family: Inter
      fonts:
        - asset: assets/fonts/inter/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/inter/Inter-SemiBold.ttf
          weight: 600
```

Mapping `TextTheme`:

- `displaySmall`: Geist 40sp/900 untuk total bulanan.
- `headlineMedium`: Geist 26sp/900 untuk judul layar.
- `headlineSmall`: Geist 26sp/700 untuk dialog.
- `titleMedium`: Inter 18sp/600 untuk judul bagian.
- `bodyLarge`: Inter 16sp/400.
- `bodyMedium`: Inter 14sp/400.
- `labelLarge`: Inter 18sp/600 untuk CTA.
- `labelMedium`: Inter 14sp/600 untuk caption/action ringkas.

Jangan menetapkan `TextStyle(height: 0.85)` untuk teks mobile panjang. Adaptasi memakai minimum 1.1 pada display dan 1.44–1.55 pada body untuk menjaga keterbacaan.

### 19.4 Shape, Border, dan Elevation

| Komponen | Implementasi Flutter |
| --- | --- |
| Button/FAB | `StadiumBorder`, tinggi primary 56dp. |
| Input/select | `OutlineInputBorder`, radius 10dp, width 2dp. |
| Card | `RoundedRectangleBorder`, radius 30dp, outline tipis. |
| Alert | Radius 16dp. |
| Dialog | Radius 40dp, inset dan content padding responsif. |
| Bottom sheet | Top-left/top-right radius 40dp. |
| Navigation indicator | Stadium/pill, primary lime. |
| Snackbar | Radius 16dp, near-black background. |

- `CardTheme` memakai elevation 0 dan outline halus; shadow tambahan hanya untuk dialog/overlay.
- Transaction card memakai padding 16dp sebagai adaptasi mobile dari card token 24dp.
- Summary card mempertahankan padding 24dp serta primary background.
- Focus outline tidak boleh hilang hanya karena Flutter touch device tidak menampilkan hover.

### 19.5 Component Themes

`component_themes.dart` membentuk minimal:

- `FilledButtonThemeData` untuk primary pill.
- `OutlinedButtonThemeData` untuk secondary pill dengan border 2dp.
- `TextButtonThemeData` untuk ghost action.
- `FloatingActionButtonThemeData` untuk extended lime FAB.
- `InputDecorationTheme` untuk input/select/textarea state.
- `CardThemeData` untuk surface dan radius 30dp.
- `DialogThemeData` untuk modal radius 40dp.
- `BottomSheetThemeData` untuk top radius 40dp dan modal barrier.
- `NavigationBarThemeData` untuk active lime pill.
- `SnackBarThemeData` untuk near-black surface.
- `ProgressIndicatorThemeData` dengan primary/on-primary yang sesuai konteks.

Komponen yang memiliki kebutuhan visual khusus boleh memakai wrapper kecil seperti `ExpenseCard` atau `PrimaryActionButton`, tetapi wrapper tidak boleh menduplikasi token dari theme.

### 19.6 Interaction dan Motion

- Durasi interaction cepat: 150ms.
- Durasi perubahan state biasa: 200ms.
- Pressed primary menggunakan `#8AD05E`.
- Scale pressed maksimum 0.98; jangan menggunakan hover scale 1.05 pada touch karena dapat mengganggu layout.
- Gunakan state-property resolver yang disediakan Flutter SDK terpin untuk pressed, disabled, focused, dan hovered.
- Loading tidak mengubah dimensi button.
- Animasi dekoratif dihentikan/dipersingkat ketika platform meminta reduce motion.

### 19.7 Accessibility

- Gunakan widget Material semantic bawaan bila tersedia.
- Tambahkan `Semantics` hanya ketika label bawaan tidak cukup.
- Tombol ikon memiliki `tooltip` dan semantic label.
- Urutan widget di tree mengikuti urutan visual/fokus.
- Jangan menetapkan text scale factor tetap.
- Layout diuji pada lebar 320dp, landscape, dan ukuran font terbesar yang didukung test target.
- Error field dihubungkan dengan field terkait dan dapat diumumkan screen reader.
- Warna kategori selalu disertai ikon/label.
- Gunakan `SafeArea` dan keyboard/view insets.
- Pasangan warna kritis diuji otomatis atau melalui accessibility audit; perubahan token tidak boleh diasumsikan tetap kontras.

## 20. Testing Strategy

### 20.1 Test Pyramid

```text
             Integration tests
          Widget / View tests
     Unit tests: domain + view model
```

Sebagian besar test berada pada unit dan widget level. Integration test mencakup alur utama serta integrasi SQLite pada Android.

### 20.2 Unit Test

Wajib mencakup:

- Validasi nominal kosong, nol, batas bawah, batas atas, dan melebihi batas.
- Normalisasi separator nominal.
- Kategori wajib dan mapping seluruh kode kategori.
- Catatan kosong, whitespace-only, 100 grapheme, serta lebih dari 100.
- Parse dan serialize `ExpenseDate`, termasuk tanggal tidak valid dan leap year.
- Perhitungan awal/akhir bulan, termasuk Desember ke Januari.
- View model state transition untuk load, retry, create, update, dan delete.
- Request generation mencegah response lama menimpa state baru.
- Failure mapping ke UI state yang benar.
- Format IDR dan tanggal Indonesia.

Gunakan handwritten fake daripada mocking framework pada MVP.

### 20.3 Widget Test

Wajib mencakup:

- Home loading, error, zero total, empty, dan data state.
- Home hanya menampilkan maksimal lima transaksi.
- Transactions empty dan populated state.
- Item dengan/tanpa catatan serta nominal panjang.
- Bottom navigation dan FAB pada kedua destinasi.
- Form add dan edit beserta initial values.
- Validasi field dan fokus ke invalid field pertama.
- Dirty-form discard dialog.
- Delete confirmation dan loading state.
- Text scaling dan layar 320dp tidak overflow.
- Semantic label untuk aksi utama.
- Theme memetakan primary/on-primary, danger, surface, outline, dan typography sesuai token dokumen 02.
- Primary button, input, card, dialog, navigation indicator, dan snackbar memakai component theme yang benar pada setiap state.
- Geist dan Inter dapat dimuat dari asset tanpa network.
- Golden test untuk Home kosong, Home berisi data, Transactions, dan form error pada ukuran perangkat yang dipin.

### 20.4 Integration Test Android

Wajib mencakup:

1. Tambah pengeluaran dan verifikasi muncul di Home serta Transactions.
2. Tutup/restart aplikasi dan verifikasi data tetap tersedia.
3. Edit nominal/kategori/catatan dan verifikasi perubahan.
4. Edit tanggal ke bulan lain dan verifikasi total bulanan.
5. Hapus dengan Batal dan verifikasi data tetap ada.
6. Hapus dengan konfirmasi dan verifikasi data serta total berubah.
7. Dua transaksi bertanggal sama diurutkan berdasarkan waktu pembuatan.
8. Semua alur berjalan saat perangkat tidak memiliki koneksi.
9. Kegagalan database yang dapat disimulasikan menghasilkan state yang aman.

Database test harus menggunakan file/path test yang terisolasi dan dibersihkan per skenario, bukan database development pengguna.

### 20.5 Migration Test

- Versi 1 diuji dapat dibuat dari kondisi tanpa database.
- Setiap versi berikutnya wajib diuji upgrade dari seluruh versi release sebelumnya.
- Setelah migration, row lama tetap terbaca dan constraint/index yang diharapkan tersedia.
- Migration tidak dianggap aman hanya karena aplikasi dapat dibuka dengan database kosong.

### 20.6 Quality Gates

Sebelum merge/release, perintah berikut harus lulus:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test -d <android-device>
flutter build appbundle --release
```

Target coverage minimal 80% untuk domain, formatter, dan view model. Coverage widget keseluruhan bukan pengganti pengujian acceptance criteria.

## 21. Build dan Configuration

### 21.1 Environment

MVP tidak memiliki environment dev/staging/prod karena tidak ada backend. Satu application ID production cukup. Build debug tetap menggunakan konfigurasi database terpisah secara alami melalui sandbox instalasi aplikasi.

### 21.2 Signing

- Keystore release tidak disimpan di repository.
- Password signing diberikan melalui environment/secret store lokal atau CI.
- File property yang berisi secret masuk `.gitignore`.
- Gunakan Play App Signing jika aplikasi didistribusikan melalui Google Play.
- Backup keystore upload disimpan di lokasi aman di luar workspace.

### 21.3 Versioning

- Gunakan format Flutter `version: major.minor.patch+buildNumber`.
- MVP awal: `0.1.0+1`, kecuali release process menentukan lain.
- `buildNumber` selalu bertambah untuk artifact yang diunggah.
- Perubahan schema database tidak wajib sama dengan versi aplikasi; schema memiliki integer version sendiri.

### 21.4 Release Verification

- Build release, bukan hanya debug.
- Periksa merged manifest tidak memiliki permission/network SDK yang tidak diinginkan.
- Verifikasi `minSdk`, `targetSdk`, backup rules, app label, application ID, serta version code.
- Verifikasi seluruh font asset dan file lisensinya masuk artifact tanpa runtime download.
- Verifikasi tidak ada logo, nama, copywriting, atau aset merek Wise dalam artifact.
- Jalankan visual smoke test untuk primary, pressed, disabled, focus, error, dialog, snackbar, dan navigation state.
- Jalankan smoke test offline pada minimal satu perangkat API 24 dan satu perangkat API 36 atau yang lebih baru tersedia.
- Uji install baru dan upgrade dari build release sebelumnya ketika versi berikutnya dibuat.

## 22. Coding Conventions

- Ikuti `flutter_lints` dan `dart format`.
- Nama class/type menggunakan `UpperCamelCase`; variable/file menggunakan `lowerCamelCase`/`snake_case` sesuai Dart style.
- Hindari method `build()` yang panjang; ekstrak widget berdasarkan tanggung jawab, bukan sekadar jumlah baris.
- Jangan menggunakan `dynamic` untuk row/domain data kecuali boundary plugin mengharuskannya; map segera ke tipe eksplisit.
- Future yang memengaruhi state harus di-`await` dan error-nya ditangani.
- Jangan menggunakan force unwrap untuk data database atau input pengguna.
- Constant UI token ditempatkan pada theme/core, bukan magic value tersebar.
- Feature widget tidak boleh menggunakan raw color, radius, font family, atau animation duration yang sudah memiliki semantic token.
- Jangan menamai class produksi dengan nama merek sumber seperti `WiseButton`; gunakan nama semantik seperti `PrimaryActionButton`.
- SQL dan nama column dipusatkan pada database/data layer.
- Komentar menjelaskan alasan atau constraint, bukan mengulang kode.

## 23. Traceability

| Requirement | Komponen teknis utama |
| --- | --- |
| US-01 / FR-01 | `ExpenseFormScreen`, `ExpenseFormViewModel`, validator, repository create. |
| US-02 / FR-03 | `TransactionsScreen`, `TransactionsViewModel`, ordered query/index. |
| US-03 / FR-04 | `HomeScreen`, `HomeViewModel`, `getHomeSummary`, SQL `SUM`. |
| US-04 / FR-05 | Form mode edit, repository update, change stream. |
| US-05 / FR-06 | Delete dialog, per-ID delete state, repository delete. |
| FR-02 | `ExpenseCategory`, persistence code, localization label. |
| FR-07 / NFR-01 | SQLite app storage, tanpa network dependency. |
| FR-08 | Form validator, domain validator, database constraints. |
| NFR-02 | Index, `LIMIT`, SQL aggregate, lazy widget list. |
| NFR-03 | Awaited writes, deterministic query, migration, integration test. |
| NFR-04 | Localized UI state, Wise-inspired semantic theme, accessibility implementation, widget/golden test. |
| NFR-05 | Internal storage, no release internet permission, backup disabled. |
| NFR-06 | MVVM ringan, constructor injection, dependency minimal. |

## 24. Future Evolution Boundary

### V0.2 — Filter dan Insight

Kemungkinan perubahan:

- Tambahkan query repository berdasarkan rentang/kategori.
- Tambahkan index setelah dibuktikan melalui query plan/performance test.
- Tambahkan view model insight tanpa mengubah database source of truth.

### V0.3 — Backend dan Sync

Sinkronisasi tidak boleh sekadar ditambahkan ke repository SQLite saat ini. Versi ini memerlukan desain baru untuk:

- Stable cross-device identifier, bukan hanya autoincrement ID lokal.
- Sync state dan conflict resolution.
- Tombstone untuk delete.
- Network service dan retry policy.
- Authentication boundary serta encryption in transit.
- Migration data lokal yang sudah ada.

### V0.4 dan Sesudahnya

Account, multi-device, OCR, serta AI membutuhkan threat model, privacy review, cost control, dan technical design tersendiri. Tidak ada abstraksi spekulatif untuk kebutuhan tersebut pada MVP V0.1.

## 25. Keputusan Terbuka Sebelum Release

| Keputusan | Batas waktu | Dampak |
| --- | --- | --- |
| ~~`applicationId` final~~ ✅ `id.pras.expensetracker` | Sebelum signing pertama | Identitas permanen aplikasi. |
| Pemilik dan penyimpanan signing key | Sebelum release build | Kemampuan menerbitkan update. |
| ~~Kanal distribusi MVP~~ ✅ APK langsung (sideload) | Sebelum release checklist | Menentukan kebutuhan Play Console. |
| Nama organisasi/publisher | Sebelum metadata store | Package ID dan listing aplikasi. |

Keputusan ini tidak menghalangi implementasi fitur, tetapi tidak boleh dibiarkan terbuka ketika artifact release final dibuat.

## 26. Definition of Done Teknis

- [ ] Struktur kode dan dependency mengikuti dokumen ini atau penyimpangannya memiliki ADR.
- [ ] Seluruh user story dan acceptance criteria PRD terimplementasi.
- [ ] UI sesuai UX/UI Spec pada state normal maupun edge case.
- [ ] Semantic color, typography, shape, component state, dan motion sesuai style mapping Wise-inspired.
- [ ] Geist dan Inter dibundel lokal beserta informasi lisensi; tidak ada runtime font request.
- [ ] Tidak ada aset atau identitas merek Wise yang disalin ke aplikasi.
- [ ] SQLite schema, constraint, index, dan migration version tersedia.
- [ ] Tidak ada floating-point untuk nominal.
- [ ] Data bertahan setelah restart aplikasi.
- [ ] Home dan Transactions konsisten setelah create, update, dan delete.
- [ ] Semua quality gate lulus.
- [ ] Tidak ada crash pada alur utama.
- [ ] Release manifest tidak mengirim data atau meminta permission yang tidak diperlukan.
- [ ] Backup database dinonaktifkan sesuai kebijakan MVP.
- [ ] Release build telah diuji dalam kondisi offline.
- [ ] Keputusan terbuka bagian 25 telah ditutup.

## 27. Referensi Teknis Resmi

- [Flutter — Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter — Persist data with SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite)
- [Flutter API — ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)
- [Flutter — Internationalizing Flutter apps](https://docs.flutter.dev/ui/internationalization)
- [Flutter — Testing overview](https://docs.flutter.dev/testing/overview)
- [Flutter — Supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms)
- [Android Developers — Target API level requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Android Developers — Back up user data with Auto Backup](https://developer.android.com/identity/data/autobackup)
- [sqflite package documentation](https://pub.dev/packages/sqflite)

Sumber style internal:

- needmcp active style: **Wise** (`wise`).
- Mode token: light.
- Versi definisi komponen pada snapshot yang ditinjau: 2.4.0.
- Komponen yang dipetakan: button, card, input, select, textarea, modal, navbar, dan alert.
- Snapshot referensi ditinjau pada 8 September 2026; aplikasi menggunakan token lokal hasil review, bukan dependency runtime ke needmcp.

Referensi perlu ditinjau ulang ketika Flutter SDK, target Android, atau kebijakan distribusi dinaikkan.
