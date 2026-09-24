# Data Model Specification

## Expense Tracker Android

| Informasi | Detail |
| --- | --- |
| Versi dokumen | 1.0 |
| Versi produk | MVP V0.1 |
| Platform | Android |
| Penyimpanan | SQLite lokal melalui `sqflite` |
| Schema version | 1 |
| Dokumen acuan | `docs/01-PRD.md`, `docs/02-UX-UI-SPEC.md`, dan `docs/03-TECHNICAL-DESIGN.md` |
| Status | Siap digunakan sebagai acuan implementasi MVP |

## 1. Tujuan Dokumen

Dokumen ini menjadi sumber kanonik untuk bentuk, arti, validasi, penyimpanan, dan lifecycle data Expense Tracker MVP V0.1. Dokumen ini mendefinisikan:

- Entity dan value object aplikasi.
- Data dictionary setiap field.
- Domain invariant dan aturan normalisasi.
- Representasi nominal, kategori, tanggal, dan timestamp.
- Schema, constraint, index, serta query SQLite.
- Aturan create, read, update, dan delete.
- Mapping antara input form, domain model, dan database row.
- Kebijakan migration, integritas, privacy, dan pengujian data.

Jika terdapat konflik kebutuhan produk, `docs/01-PRD.md` menjadi sumber utama. Technical Design menentukan arsitektur implementasi, sedangkan dokumen ini menentukan kontrak datanya.

## 2. Ruang Lingkup

### 2.1 In Scope

- Satu entity pengeluaran.
- Lima kategori tetap.
- Nominal dalam Rupiah.
- Tanggal transaksi tanpa waktu.
- Catatan opsional.
- Timestamp pembuatan dan perubahan.
- Penyimpanan lokal satu pengguna pada satu perangkat.
- Query daftar, lima transaksi terbaru, dan total bulanan.
- Migration schema lokal.

### 2.2 Out of Scope

- User atau account entity.
- Income, balance, budget, debt, asset, atau investment entity.
- Custom category.
- Currency table atau exchange rate.
- Recurring transaction.
- Attachment atau receipt image.
- Cloud identifier, sync status, conflict metadata, dan tombstone.
- Audit history untuk setiap perubahan.
- Soft delete, recycle bin, export, atau backup model.

## 3. Data Architecture

```text
Form input mentah
       │
       ▼ validate + normalize
ExpenseDraft
       │
       ▼ repository create/update
Expense domain model
       │
       ▼ ExpenseMapper
SQLite expenses row
       │
       ├── query all ───────────> Transactions
       ├── query latest 5 ──────> Home
       └── SUM by month ────────> Monthly total
```

Aturan boundary:

- SQLite adalah source of truth persisted.
- Repository adalah satu-satunya jalur baca/tulis production.
- UI tidak mengakses row atau SQL secara langsung.
- Domain model tidak menyimpan string yang sudah diformat untuk tampilan.
- Nilai turunan seperti total bulanan tidak dipersist.
- State loading, error, selected tab, dan dirty form tidak dipersist.

## 4. Conceptual Model

MVP hanya memiliki satu persisted entity:

```text
┌──────────────────────────────┐
│ Expense                      │
├──────────────────────────────┤
│ id                           │
│ amount                       │
│ category                     │
│ transactionDate              │
│ note                         │
│ createdAt                    │
│ updatedAt                    │
└──────────────────────────────┘
```

`ExpenseCategory` adalah enum/value, bukan entity atau table terpisah. Tidak ada relationship atau foreign key pada schema version 1.

## 5. Model Inventory

| Model | Jenis | Dipersist | Tujuan |
| --- | --- | --- | --- |
| `Expense` | Entity | Ya | Representasi pengeluaran yang sudah tersimpan. |
| `ExpenseDraft` | Command/value | Tidak | Payload valid untuk create atau update. |
| `ExpenseCategory` | Enum | Sebagai kode | Daftar kategori tetap. |
| `ExpenseDate` | Value object | Sebagai ISO string | Tanggal kalender tanpa timezone. |
| `ExpenseMonth` | Value object | Tidak | Rentang bulan untuk query total. |
| `HomeSummary` | Read model | Tidak | Total bulan dan lima transaksi terbaru. |
| `ExpenseChange` | Event in-process | Tidak | Memberi tahu view model setelah mutasi berhasil. |

## 6. Expense Entity

### 6.1 Domain Shape

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

Entity bersifat immutable. Perubahan menghasilkan payload baru dan dilakukan melalui repository; object yang sudah ada tidak dimutasi di tempat.

### 6.2 Data Dictionary

| Domain field | Column | Domain type | SQLite type | Nullable | Dibuat oleh | Aturan utama |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `id` | `int` | `INTEGER` | Tidak | SQLite | Primary key, positif, autoincrement, tidak berubah. |
| `amount` | `amount` | `int` | `INTEGER` | Tidak | Pengguna | `1..999_999_999_999`, satuan Rupiah. |
| `category` | `category` | `ExpenseCategory` | `TEXT` | Tidak | Pengguna | Salah satu dari lima kode kategori valid. |
| `transactionDate` | `transaction_date` | `ExpenseDate` | `TEXT` | Tidak | Pengguna/default hari ini | ISO `YYYY-MM-DD`, tanggal kalender valid. |
| `note` | `note` | `String?` | `TEXT` | Ya | Pengguna | Maksimal 100 grapheme setelah aturan input; blank menjadi `null`. |
| `createdAt` | `created_at` | UTC `DateTime` | `INTEGER` | Tidak | Repository | Epoch milliseconds; ditetapkan sekali saat create. |
| `updatedAt` | `updated_at` | UTC `DateTime` | `INTEGER` | Tidak | Repository | Epoch milliseconds; diperbarui pada update. |

### 6.3 Field Mutability

| Field | Create | Update | Delete |
| --- | --- | --- | --- |
| `id` | Dibuat SQLite | Tetap | Menentukan row target |
| `amount` | Wajib | Dapat berubah | — |
| `category` | Wajib | Dapat berubah | — |
| `transactionDate` | Wajib | Dapat berubah | — |
| `note` | Opsional | Dapat berubah/dikosongkan | — |
| `createdAt` | Dibuat repository | Tetap | — |
| `updatedAt` | Sama dengan `createdAt` | Dibuat ulang repository | — |

## 7. Domain Invariants

Setiap `Expense` atau `ExpenseDraft` valid harus memenuhi seluruh invariant berikut:

1. `id` pada persisted Expense lebih besar dari nol.
2. `amount` adalah integer dalam rentang `1..999_999_999_999`.
3. `amount` tidak memiliki simbol mata uang, separator, atau digit desimal pada domain/storage.
4. `category` adalah salah satu nilai enum yang dikenal.
5. `transactionDate` adalah tanggal kalender valid.
6. `transactionDate` tidak mengandung jam atau timezone.
7. `note` adalah `null` atau string yang sudah dinormalisasi.
8. `note` tidak memiliki leading atau trailing whitespace.
9. `note` memiliki maksimal 100 grapheme yang dipersepsikan pengguna.
10. `createdAt` dan `updatedAt` dinyatakan dalam UTC.
11. Create menetapkan `createdAt` dan `updatedAt` ke instant yang sama.
12. Update tidak mengubah `id` atau `createdAt`.
13. Duplicate Expense diperbolehkan; tidak ada uniqueness rule berdasarkan amount, category, date, atau note.

Validator domain dan repository wajib menolak pelanggaran invariant sebelum write. Constraint SQLite menjadi pertahanan tambahan untuk invariant yang dapat direpresentasikan dengan benar di SQLite.

## 8. ExpenseDraft

### 8.1 Tujuan

`ExpenseDraft` digunakan untuk create dan update agar UI tidak dapat menentukan ID atau audit timestamp.

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

### 8.2 Input Mentah Bukan ExpenseDraft

Form memegang nilai mentah seperti:

```text
amountText = "25.000"
selectedCategory = food
selectedDate = ExpenseDate(2026, 9, 8)
noteText = "  Makan siang  "
```

Setelah validasi dan normalisasi:

```text
amount = 25000
category = food
transactionDate = "2026-09-08"
note = "Makan siang"
```

`ExpenseDraft` hanya boleh dibentuk dari nilai hasil normalisasi yang valid.

## 9. ExpenseCategory

### 9.1 Canonical Values

| Enum Dart | Kode persistence | Label Bahasa Indonesia | Urutan pilihan |
| --- | --- | --- | --- |
| `food` | `food` | Makanan | 1 |
| `transportation` | `transportation` | Transportasi | 2 |
| `shopping` | `shopping` | Belanja | 3 |
| `bills` | `bills` | Tagihan | 4 |
| `other` | `other` | Lainnya | 5 |

Aturan:

- Database menyimpan kode persistence, bukan label UI.
- Kode menggunakan lowercase ASCII dan tidak diterjemahkan.
- Label berada pada localization resource.
- Urutan pilihan adalah aturan presentasi dan tidak memengaruhi urutan transaksi.
- Kode tidak boleh diubah tanpa migration data.
- Kode yang tidak dikenali menghasilkan `CorruptDataFailure`; jangan otomatis memetakannya ke `other`.

### 9.2 Mengubah Daftar Kategori

Penambahan, penghapusan, atau rename kategori berada di luar scope MVP. Jika dilakukan pada versi mendatang:

1. Perbarui PRD dan UX/UI Spec.
2. Perbarui enum dan localization.
3. Buat migration SQLite karena schema version 1 memiliki category `CHECK` constraint.
4. Tentukan mapping row lama secara eksplisit.
5. Tambahkan migration dan repository mapping tests.

## 10. Amount Model

### 10.1 Unit dan Tipe

- Unit kanonik adalah satu Rupiah.
- `25000` berarti Rp25.000.
- Gunakan Dart `int` dan SQLite `INTEGER`.
- Jangan menggunakan `double`, `REAL`, decimal fraction, atau string formatted untuk perhitungan.
- Prefix `Rp` dan pemisah ribuan hanya ditambahkan pada presentation layer.

### 10.2 Rentang

| Boundary | Nilai | Valid |
| --- | --- | --- |
| Kosong | Tidak ada nilai | Tidak |
| Minimum invalid | `0` | Tidak |
| Minimum valid | `1` | Ya |
| Typical | `25_000` | Ya |
| Maximum valid | `999_999_999_999` | Ya |
| Above maximum | `1_000_000_000_000` | Tidak |
| Negative | `-1` | Tidak |

Batas maksimum berasal dari Technical Design dan telah diselaraskan ke UX/UI Spec. Karena nilai maksimum belum tercantum eksplisit pada PRD v1.0, keputusan ini perlu diratifikasi pada revisi PRD sebelum release.

### 10.3 Aggregate Safety

SQLite `SUM(amount)` menghasilkan integer selama seluruh input berupa integer. Dengan maksimum per transaksi yang dipilih, agregasi tetap berada dalam signed 64-bit sampai lebih dari sembilan juta transaksi bernilai maksimum. Volume engineering MVP adalah 10.000 transaksi, sehingga masih memiliki margin yang besar.

Jika SQLite melaporkan integer overflow, repository memetakannya ke `StorageFailure`; aplikasi tidak boleh mengganti hasil dengan floating-point yang kehilangan presisi.

## 11. Date and Time Model

### 11.1 Transaction Date

`transactionDate` adalah civil/local calendar date, bukan instant waktu.

Canonical storage:

```text
YYYY-MM-DD
```

Contoh:

```text
2026-09-08
```

Aturan:

- Tahun selalu empat digit.
- Bulan dan hari selalu dua digit.
- Tidak memiliki suffix `Z`, offset, atau waktu.
- Tidak dikonversi dengan `toUtc()`.
- Parser harus strict dan menolak normalisasi tanggal invalid.
- `2026-02-29`, `2026-13-01`, dan `08-09-2026` tidak valid.
- Tanggal masa depan diperbolehkan sesuai UX/UI Spec.

Parser strict harus:

1. Memastikan pola `YYYY-MM-DD`.
2. Mem-parse komponen integer.
3. Membentuk tanggal kalender.
4. Membandingkan kembali year/month/day hasil dengan input agar overflow normalization terdeteksi.

### 11.2 Date Picker Range

- Batas awal default: 1 Januari pada tahun `currentYear - 100`.
- Batas akhir default: 31 Desember pada tahun `currentYear + 100`.
- Pada mode edit, rentang diperluas bila tanggal tersimpan berada di luar rentang default.
- Batas picker adalah aturan input UI; parser/domain tetap dapat membaca tanggal valid yang sudah tersimpan.

### 11.3 Audit Timestamp

`createdAt` dan `updatedAt` adalah instant UTC yang disimpan sebagai milliseconds sejak Unix epoch:

```text
DateTime UTC ↔ millisecondsSinceEpoch ↔ SQLite INTEGER
```

Aturan:

- Repository mengambil waktu melalui `AppClock`.
- Create menggunakan satu pembacaan clock untuk kedua timestamp.
- Update hanya mengganti `updatedAt`.
- Timestamp tidak ditampilkan pada UI MVP.
- Timestamp bukan tanggal transaksi dan tidak digunakan dalam total bulanan.

Jam perangkat dapat diubah pengguna sehingga timestamp tidak dijamin monotonic. Karena itu urutan menggunakan `id DESC` sebagai final deterministic tie-breaker setelah `created_at DESC`.

### 11.4 ExpenseMonth

`ExpenseMonth` terdiri dari `year` dan `month`, lalu menghasilkan dua boundary ISO:

```text
startInclusive = YYYY-MM-01
endExclusive   = awal bulan berikutnya
```

Contoh September 2026:

```text
startInclusive = 2026-09-01
endExclusive   = 2026-10-01
```

Contoh Desember 2026:

```text
startInclusive = 2026-12-01
endExclusive   = 2027-01-01
```

## 12. Note Model

### 12.1 Normalization

Urutan normalisasi catatan:

1. Ambil input persis dari form.
2. Hitung/batasi maksimal 100 grapheme pada UI.
3. Hapus leading dan trailing whitespace saat submit.
4. Pertahankan whitespace internal dan line break.
5. Ubah hasil kosong menjadi `null`.
6. Validasi ulang maksimum 100 grapheme pada repository.

Contoh:

| Input | Stored value |
| --- | --- |
| `""` | `NULL` |
| `"   "` | `NULL` |
| `"  Makan siang  "` | `"Makan siang"` |
| `"Makan\nsiang"` | `"Makan\nsiang"` |

### 12.2 Grapheme dan SQLite

Batas 100 mengacu pada grapheme/user-perceived character. Dart menghitungnya melalui package `characters`.

SQLite `length()` menghitung representasi karakter dengan semantik yang dapat berbeda untuk grapheme majemuk seperti emoji. Oleh karena itu schema tidak menggunakan `CHECK(length(note) <= 100)`. Enforcement dilakukan pada form dan repository agar input yang valid di UI tidak ditolak secara keliru oleh database.

Saat membaca row, mapper/repository memvalidasi ulang note. Row yang melanggar invariant menghasilkan `CorruptDataFailure`.

## 13. Physical SQLite Schema

### 13.1 Database Metadata

| Properti | Nilai |
| --- | --- |
| File | `expense_tracker.db` |
| Schema version | `1` |
| Directory | Hasil `getDatabasesPath()` pada app-specific storage |
| Table | `expenses` |
| Index | `idx_expenses_order` |
| Connection model | Single instance per application process |

### 13.2 DDL Version 1

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

### 13.3 Constraint Coverage

| Invariant | Form | Domain/repository | SQLite |
| --- | --- | --- | --- |
| Amount wajib dan numeric | Ya | Ya | `NOT NULL`/type affinity |
| Amount > 0 | Ya | Ya | `CHECK` |
| Amount ≤ maksimum | Ya | Ya | `CHECK` |
| Category dikenal | Ya | Ya | `CHECK` |
| Date pattern/length | Date picker | Ya | Length 10 |
| Date kalender valid | Date picker | Ya | Tidak |
| Note ≤100 grapheme | Ya | Ya | Tidak |
| Note blank menjadi null | Saat submit | Ya | Tidak |
| Timestamp tersedia | Tidak | Ya | `NOT NULL` |

SQLite tidak menjadi sumber pesan validasi pengguna. Pelanggaran constraint dari write production dipetakan ke application failure dan dianggap indikasi bug atau data race.

### 13.4 Index Rationale

`idx_expenses_order` mendukung:

- Urutan seluruh transaksi berdasarkan tanggal dan waktu dibuat.
- Query transaksi terbaru dengan `LIMIT 5`.
- Range scan berdasarkan `transaction_date` untuk total bulanan.
- Deterministic ordering melalui `id` sebagai tie-breaker terakhir.

Tidak ada index tambahan pada category atau note karena MVP tidak memiliki filter/pencarian tersebut.

## 14. Canonical Queries

### 14.1 All Expenses

```sql
SELECT
  id,
  amount,
  category,
  transaction_date,
  note,
  created_at,
  updated_at
FROM expenses
ORDER BY transaction_date DESC, created_at DESC, id DESC;
```

### 14.2 Latest Expenses

```sql
SELECT
  id,
  amount,
  category,
  transaction_date,
  note,
  created_at,
  updated_at
FROM expenses
ORDER BY transaction_date DESC, created_at DESC, id DESC
LIMIT ?;
```

Production Home selalu mengikat `LIMIT` ke `5`. Parameter tetap divalidasi positif pada repository.

### 14.3 Monthly Total

```sql
SELECT COALESCE(SUM(amount), 0) AS total
FROM expenses
WHERE transaction_date >= ?
  AND transaction_date < ?;
```

Contoh parameter September 2026:

```text
["2026-09-01", "2026-10-01"]
```

Transaksi pada boundary awal disertakan; transaksi pada awal bulan berikutnya tidak disertakan.

### 14.4 Insert

```sql
INSERT INTO expenses (
  amount,
  category,
  transaction_date,
  note,
  created_at,
  updated_at
) VALUES (?, ?, ?, ?, ?, ?);
```

### 14.5 Update

```sql
UPDATE expenses
SET amount = ?,
    category = ?,
    transaction_date = ?,
    note = ?,
    updated_at = ?
WHERE id = ?;
```

Update count harus tepat satu. `created_at` tidak berada pada `SET` clause.

### 14.6 Delete

```sql
DELETE FROM expenses
WHERE id = ?;
```

Delete count harus tepat satu. Delete bersifat permanen dan tidak menerbitkan success sebelum database menyelesaikan operasi.

### 14.7 Parameter Binding

- Seluruh input user diikat melalui argument API `sqflite`.
- Jangan melakukan interpolasi nilai ke SQL string.
- Nama table, column, dan SQL statis dipusatkan di data layer.
- Mapper hanya menerima column yang dinyatakan pada query.

## 15. Row Mapping

### 15.1 Row to Domain

Urutan mapping:

1. Pastikan seluruh column wajib tersedia dan non-null.
2. Cast `id`, `amount`, `created_at`, serta `updated_at` ke `int`.
3. Validasi rentang `id` dan `amount`.
4. Map category code secara strict.
5. Parse `transaction_date` menjadi `ExpenseDate` secara strict.
6. Normalize/validasi `note` sesuai invariant.
7. Bentuk timestamp UTC dengan `DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)`.
8. Bentuk immutable `Expense`.

Kegagalan mapping menghasilkan `CorruptDataFailure`; row tidak boleh diam-diam dilewati atau diberi default palsu.

### 15.2 Domain to Row

| Domain value | Row value |
| --- | --- |
| `amount` | Integer apa adanya |
| `category` | Stable persistence code |
| `transactionDate` | Strict ISO string |
| `note` | Normalized string atau `null` |
| `createdAt` | UTC epoch milliseconds |
| `updatedAt` | UTC epoch milliseconds |

`Rp`, titik pemisah ribuan, nama bulan, dan label kategori tidak pernah masuk ke database.

## 16. CRUD Lifecycle

### 16.1 Create

```text
RawFormInput
  → form validation
  → normalized ExpenseDraft
  → repository validation
  → read AppClock once
  → INSERT
  → receive generated id
  → return Expense
  → emit ExpenseChange.created
```

Jika insert gagal, tidak ada change event dan UI mempertahankan input.

### 16.2 Read

- Repository membuka database secara lazy.
- Query memakai explicit ordering.
- Row dimapping secara strict.
- Empty result adalah list kosong, bukan error.
- `SUM` tanpa row menghasilkan integer `0` melalui `COALESCE`.

### 16.3 Update

```text
id + normalized ExpenseDraft
  → repository validation
  → create updatedAt UTC
  → UPDATE WHERE id
  → verify affected rows == 1
  → return updated Expense
  → emit ExpenseChange.updated
```

Nol affected row menghasilkan `NotFoundFailure`. ID dan `createdAt` tidak berubah.

### 16.4 Delete

```text
id
  → validate id > 0
  → DELETE WHERE id
  → verify affected rows == 1
  → emit ExpenseChange.deleted
```

Nol affected row menghasilkan `NotFoundFailure`. Tidak ada `deleted_at`, undo record, atau archive table.

## 17. Ordering Rules

Canonical order:

```text
transaction_date DESC
created_at DESC
id DESC
```

Makna:

1. Tanggal transaksi paling baru lebih dahulu.
2. Jika tanggal sama, record yang dibuat lebih baru lebih dahulu.
3. Jika timestamp sama atau clock tidak dapat membedakan, ID lebih besar lebih dahulu.

`updated_at` tidak memengaruhi urutan. Mengedit note atau amount tidak memindahkan transaksi kecuali `transaction_date` ikut berubah.

## 18. Derived Data

### 18.1 HomeSummary

```dart
final class HomeSummary {
  const HomeSummary({
    required this.month,
    required this.monthlyTotal,
    required this.latestExpenses,
  });

  final ExpenseMonth month;
  final int monthlyTotal;
  final List<Expense> latestExpenses;
}
```

Invariant read model:

- `monthlyTotal >= 0`.
- `latestExpenses.length <= 5` pada request production Home.
- List menggunakan canonical order.
- List diekspos sebagai immutable/unmodifiable collection.
- Total dan list dibaca dalam transaction/snapshot database yang sama.

### 18.2 Data yang Tidak Dipersist

- Total bulanan.
- Formatted Rupiah.
- Formatted date.
- Category label, icon, atau color.
- Lima transaksi terbaru sebagai cache terpisah.
- Empty/loading/error state.
- Navigation selection.

Nilai tersebut selalu dihitung atau dibentuk dari source data agar tidak mengalami stale data.

## 19. Validation Matrix

| Field/operation | Invalid condition | Application failure | Pesan pengguna |
| --- | --- | --- | --- |
| Amount | Kosong | Form validation | Nominal wajib diisi |
| Amount | Nol/negatif | `ValidationFailure` | Nominal harus lebih besar dari 0 |
| Amount | Tidak dapat diparse | `ValidationFailure` | Nominal tidak valid |
| Amount | Di atas maksimum | `ValidationFailure` | Nominal terlalu besar |
| Category | Tidak dipilih | `ValidationFailure` | Kategori wajib dipilih |
| Category row | Kode tidak dikenal | `CorruptDataFailure` | Data tidak dapat dimuat |
| Date row | Format/tanggal invalid | `CorruptDataFailure` | Data tidak dapat dimuat |
| Note | Lebih dari 100 grapheme | `ValidationFailure` | Input dibatasi; write ditolak |
| Update/delete | ID tidak ditemukan | `NotFoundFailure` | Operasi gagal. Coba lagi. |
| Database | Open/query/write gagal | `StorageFailure` | Pesan retry sesuai konteks |

Detail exception database tidak ditampilkan kepada pengguna.

## 20. Integrity and Consistency

- Repository menjadi satu-satunya writer production.
- Satu database instance digunakan per application process.
- Write selalu di-`await` sebelum success feedback.
- Mutasi ganda dicegah pada UI dan tetap divalidasi repository.
- Change event hanya diterbitkan setelah write berhasil.
- Read model tidak menggantikan persisted source of truth.
- Database tidak dihapus atau dibuat ulang otomatis ketika mapping/open gagal.
- Row korup tidak dilewati karena dapat membuat total dan daftar berbeda.
- Duplicate business data diperbolehkan karena pengguna dapat melakukan transaksi identik.
- Delete permanen hanya dijalankan setelah konfirmasi UI, tetapi repository tidak bergantung pada UI untuk integritas ID.

MVP hanya melakukan write dari main application isolate. Background writer dan multi-process database access berada di luar scope.

## 21. Database Initialization and Migration

### 21.1 Initialization

- Database dibuka dengan `singleInstance: true`.
- `onCreate` membentuk table dan index schema version 1.
- Pembentukan schema bersifat atomic.
- Jika open gagal, cached Future dibersihkan agar retry benar-benar mencoba kembali.
- Database development/test tidak menggunakan path production user.

### 21.2 Migration Policy

- Setiap perubahan physical schema menaikkan integer schema version.
- Setiap version memiliki fungsi migration eksplisit.
- Migration dijalankan dalam transaction.
- Migration tidak boleh menghapus data sebagai fallback error.
- `DROP TABLE` hanya boleh digunakan dalam table-rebuild migration yang menyalin dan memverifikasi seluruh data di transaction yang sama.
- Setiap migration harus dapat diuji dari semua schema version release sebelumnya yang masih didukung.
- Downgrade destructive tidak didukung.

### 21.3 Category Constraint Migration

SQLite version yang digunakan tidak selalu dapat mengubah `CHECK` constraint secara langsung. Jika daftar category berubah, gunakan table rebuild:

1. Buat `expenses_new` dengan schema baru.
2. Salin row sambil melakukan mapping category eksplisit.
3. Verifikasi jumlah row sumber dan target.
4. Hapus table lama di dalam transaction.
5. Rename table baru menjadi `expenses`.
6. Buat ulang index.

Jangan memetakan kategori lama ke `other` tanpa keputusan produk terdokumentasi.

## 22. Privacy and Retention

### 22.1 Data Classification

| Data | Klasifikasi aplikasi | Perlakuan |
| --- | --- | --- |
| Amount | Data finansial pribadi | Internal app storage, tidak dilog. |
| Category | Data finansial pribadi | Internal app storage, tidak dilog. |
| Transaction date | Data finansial pribadi | Internal app storage, tidak dilog. |
| Note | Potensial data sensitif/free text | Internal app storage, tidak dilog. |
| ID/timestamp | Metadata internal | Tidak diekspos atau dikirim keluar. |

### 22.2 Storage and Backup

- Database berada di app-specific internal storage.
- Release tidak menyediakan export atau cloud sync.
- Backup database dinonaktifkan sesuai Technical Design.
- Database SQLite MVP tidak memiliki encryption key khusus aplikasi.
- Aplikasi tidak mengirim row, aggregate, atau metadata ke layanan eksternal.

### 22.3 Retention

- Expense bertahan sampai pengguna menghapusnya, clear app data, atau uninstall.
- Delete melalui aplikasi permanen.
- Tidak ada auto-expiry atau retention period.
- Tidak ada recovery setelah delete pada MVP.

## 23. Example Records

### 23.1 Domain Example

```dart
Expense(
  id: 42,
  amount: 25000,
  category: ExpenseCategory.food,
  transactionDate: ExpenseDate(2026, 9, 8),
  note: 'Makan siang',
  createdAt: DateTime.utc(2026, 9, 8, 5),
  updatedAt: DateTime.utc(2026, 9, 8, 5),
)
```

### 23.2 SQLite Row Example

```text
id               = 42
amount           = 25000
category         = "food"
transaction_date = "2026-09-08"
note             = "Makan siang"
created_at       = 1788843600000
updated_at       = 1788843600000
```

### 23.3 Display Projection

```text
Kategori = Makanan
Tanggal  = 8 Sep 2026
Nominal  = Rp25.000
Catatan  = Makan siang
```

Display projection bukan persisted data.

## 24. Test Requirements

### 24.1 Domain Boundary Tests

- Amount `0`, `1`, maximum, dan maximum + 1.
- Seluruh enum category dan unknown category code.
- Valid leap date dan invalid calendar date.
- ISO round-trip mempertahankan tanggal.
- Tanggal tidak bergeser pada timezone perangkat berbeda.
- Note kosong, whitespace-only, 100 grapheme, 101 grapheme, dan emoji majemuk.
- Create menghasilkan timestamp sama.
- Update mempertahankan ID dan createdAt.

### 24.2 Repository/SQLite Tests

- Schema version 1 membuat table, constraint, dan index yang tepat.
- Insert lalu read menghasilkan domain object yang setara.
- Update hanya mengubah field yang diizinkan dan `updated_at`.
- Delete menghapus tepat satu row.
- ID tidak ditemukan menghasilkan `NotFoundFailure`.
- Duplicate expenses dapat disimpan.
- Urutan tanggal sama mengikuti createdAt lalu ID.
- Latest query membatasi lima row.
- Monthly total menggunakan year dan month serta menangani zero result.
- Edit tanggal lintas bulan mengubah aggregate yang benar.
- Constraint amount/category menolak write invalid.
- Note 100 grapheme majemuk yang valid tidak ditolak SQLite.
- Row category/date/note korup menghasilkan `CorruptDataFailure`.

### 24.3 Migration Tests

- Fresh install membuat schema version 1.
- Database version lama dapat di-upgrade tanpa kehilangan row.
- Row count dan nilai field tetap benar setelah migration.
- Index dibuat ulang setelah table rebuild.
- Migration gagal melakukan rollback transaction, bukan meninggalkan schema parsial.

### 24.4 Data Volume Tests

Dengan fixture 10.000 rows:

- All-expense order tetap benar.
- Latest-five query tetap benar.
- Monthly `SUM` presisi sebagai integer.
- Query memenuhi engineering budget pada Technical Design.
- Mapping tidak menyebabkan UI menerima mutable list yang dapat mengubah source state.

## 25. Future Schema Considerations

Bagian ini bukan scope MVP dan tidak boleh diimplementasikan lebih awal.

### V0.2

- Filter category/date mungkin memerlukan index tambahan berdasarkan hasil pengukuran.
- Ringkasan per kategori dapat dihitung melalui query aggregate tanpa menyimpan cache.
- Grafik menggunakan read model turunan, bukan column baru per grafik.

### V0.3

Backend dan sync membutuhkan redesign, antara lain:

- Stable UUID/cross-device identifier.
- Local/server version atau revision.
- Sync state dan last-synced timestamp.
- Tombstone untuk delete.
- Conflict resolution rule.
- Migration seluruh row lokal yang sudah ada.

Autoincrement `id` version 1 hanya merupakan local primary key dan tidak boleh dikirim sebagai global identity.

### V0.4

Account/multi-user membutuhkan ownership relationship serta keputusan isolasi data. Jangan menambahkan nullable `user_id` pada MVP tanpa desain autentikasi dan migration yang lengkap.

## 26. Traceability

| Requirement | Data model support |
| --- | --- |
| US-01 / FR-01 | ExpenseDraft, validation, INSERT, persistence mapping. |
| US-02 / FR-03 | Expense entity, deterministic ordered query, index. |
| US-03 / FR-04 | ExpenseMonth, integer SUM, HomeSummary. |
| US-04 / FR-05 | Update lifecycle, immutable ID/createdAt. |
| US-05 / FR-06 | Permanent DELETE by ID. |
| FR-02 | Fixed ExpenseCategory codes and CHECK constraint. |
| FR-07 | SQLite internal storage and migration policy. |
| FR-08 | Validation matrix plus layered enforcement. |
| NFR-02 | Composite index, aggregate SQL, latest LIMIT. |
| NFR-03 | Constraint, strict mapper, atomic writes/migrations. |
| NFR-05 | Local-only boundary and data classification. |
| NFR-06 | Single entity/table and no speculative sync fields. |

## 27. Open Product Clarification

| Topik | Keputusan saat ini | Tindakan |
| --- | --- | --- |
| Maximum amount | Rp999.999.999.999 per transaksi | Ratifikasi pada revisi PRD sebelum release. |

Tidak ada keputusan data lain yang menghalangi implementasi MVP V0.1.

## 28. Data Definition of Done

- [ ] Domain model dan schema mengikuti field dictionary.
- [ ] Semua domain invariant diuji.
- [ ] Nominal tidak menggunakan floating-point.
- [ ] Transaction date tersimpan sebagai strict ISO date-only.
- [ ] Audit timestamp tersimpan sebagai UTC epoch milliseconds.
- [ ] Category menggunakan stable persistence code.
- [ ] Note blank menjadi null dan batas grapheme konsisten.
- [ ] Schema version dan migration path tersedia.
- [ ] Query all/latest/monthly menggunakan canonical SQL dan parameter binding.
- [ ] Urutan menggunakan tiga deterministic keys.
- [ ] Create/update/delete memverifikasi hasil write.
- [ ] Tidak ada row atau aggregate yang dikirim keluar perangkat.
- [ ] Repository dan SQLite integration tests lulus.
- [ ] Maximum amount telah diratifikasi sebelum release.
