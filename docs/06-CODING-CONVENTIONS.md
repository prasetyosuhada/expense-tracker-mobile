# Coding Conventions

## Expense Tracker Android

| Informasi | Detail |
| --- | --- |
| Versi dokumen | 1.0 |
| Versi produk | MVP V0.1 |
| Platform | Android |
| Framework | Flutter |
| Bahasa pemrograman | Dart |
| Dokumen acuan | `docs/03-TECHNICAL-DESIGN.md` bagian 6, 22, dan 20.6 |
| Status | Siap digunakan sebagai acuan implementasi MVP |

## 1. Tujuan Dokumen

Dokumen ini mengumpulkan dan merinci seluruh konvensi penulisan kode untuk Expense Tracker MVP V0.1. Tujuannya:

- Menjaga konsistensi kode lintas seluruh file dan fitur.
- Mempercepat code review dengan acuan bersama.
- Mengurangi keputusan gaya yang berulang saat implementasi.
- Melengkapi aturan yang sudah tersirat di Technical Design menjadi panduan eksplisit.

Jika terdapat konflik dengan Technical Design, Technical Design menjadi sumber utama. Dokumen ini hanya mengatur *cara penulisan*, bukan arsitektur atau keputusan produk.

## 2. Tooling Wajib

### 2.1 Static Analysis

Gunakan `flutter_lints` sebagai baseline. Rules tambahan dicatat di `analysis_options.yaml`.

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Tambahkan rules proyek di sini.
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
    prefer_single_quotes: true
    sort_child_properties_last: true
    use_key_in_widget_constructors: true
    prefer_final_locals: true
    unnecessary_lambdas: true
    avoid_unnecessary_containers: true
```

Rules tidak boleh di-ignore menggunakan `// ignore:` kecuali ada alasan teknis spesifik yang didokumentasikan di baris yang sama.

### 2.2 Formatting

- Seluruh file harus lolos `dart format` tanpa perubahan.
- Maximum line length mengikuti default Dart (80 characters).
- Trailing comma digunakan pada parameter list yang multi-line agar auto-format menghasilkan bentuk vertikal yang konsisten.

### 2.3 Quality Gate

Sebelum commit, pastikan:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Build release dan integration test di-run sebelum merge/release sesuai Technical Design bagian 20.6.

## 3. Penamaan

### 3.1 Dart Identifiers

| Jenis | Konvensi | Contoh |
| --- | --- | --- |
| Class, enum, typedef, extension | `UpperCamelCase` | `ExpenseCategory`, `HomeSummary` |
| Variable, parameter, field | `lowerCamelCase` | `transactionDate`, `monthlyTotal` |
| Constant | `lowerCamelCase` | `maxAmount`, `defaultLatestLimit` |
| Private member | `_lowerCamelCase` | `_expenses`, `_isSubmitting` |
| Library/file | `snake_case` | `expense_form_view_model.dart` |
| Test file | `snake_case` + `_test` | `expense_validator_test.dart` |
| Named parameter | `lowerCamelCase`, deskriptif | `required ExpenseMonth month` |

Aturan tambahan:

- Nama boolean menggunakan prefix `is`, `has`, `can`, `should`. Contoh: `isDirty`, `hasSubmitted`, `isSubmitting`.
- Nama method yang mengembalikan `Future` tidak perlu suffix `Async`. Contoh: `create()`, bukan `createAsync()`.
- Nama factory constructor menggunakan `fromX`. Contoh: `ExpenseDate.fromDateTime(dt)`.
- Hindari singkatan kecuali yang sudah umum di Dart (`db`, `id`, `sql`, `utc`).

### 3.2 File dan Folder

File bernama sesuai class utama di dalamnya:

| Class | File |
| --- | --- |
| `ExpenseFormViewModel` | `expense_form_view_model.dart` |
| `SqliteExpenseRepository` | `sqlite_expense_repository.dart` |
| `IdrFormatter` | `idr_formatter.dart` |

Aturan:

- Satu file berisi satu class utama.
- Sealed state yang sangat terkait boleh satu file dengan class utamanya.
- File widget tidak menggunakan prefix `widget_`.
- File test berada pada path mirror. Contoh: `lib/features/expenses/domain/expense_validator.dart` → `test/features/expenses/domain/expense_validator_test.dart`.

### 3.3 Penamaan yang Dilarang

- Jangan menamai class production dengan nama merek sumber: `WiseButton`, `WiseCard`. Gunakan nama semantik: `PrimaryActionButton`, `ExpenseCard`.
- Jangan menggunakan `Manager`, `Helper`, `Util` sebagai nama class kecuali benar-benar tidak ada nama domain yang lebih tepat.
- Jangan menggunakan akronim penuh uppercase untuk nama class multi-kata: `IDRFormatter` → `IdrFormatter`.

## 4. Organisasi Kode

### 4.1 Struktur Feature-First

Ikuti struktur folder dari Technical Design bagian 6. Feature `expenses` memiliki sub-folder `domain/`, `data/`, dan `presentation/`. Kode bersama berada di `core/`.

Aturan placement:

| Kode | Lokasi | Alasan |
| --- | --- | --- |
| Domain model, validator | `features/expenses/domain/` | Milik fitur |
| Repository interface | `features/expenses/domain/` | Kontrak fitur |
| SQLite implementation | `features/expenses/data/` | Detail persistence |
| Screen, view model, state | `features/expenses/presentation/<screen>/` | Layar spesifik |
| Widget reusable lintas 3 layar | `features/expenses/presentation/widgets/` | Shared di fitur |
| Clock, formatter, theme, l10n | `core/<concern>/` | Shared lintas fitur |
| Composition root | `app/` | Bootstrap |

- Folder `core/` tidak boleh menjadi tempat pembuangan. Setiap sub-folder memiliki concern yang jelas.
- Helper yang hanya digunakan satu layar tetap di folder layar tersebut.
- Jangan membuat folder `utils/`, `common/`, atau `shared/` di root `lib/`.

### 4.2 Import

Urutan import mengikuti konvensi Dart:

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Package eksternal (alphabetical)
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

// 4. Package lokal (alphabetical)
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
```

Aturan:

- Pisahkan setiap grup dengan satu baris kosong.
- Gunakan absolute import (`package:expense_tracker/...`), bukan relative import (`../`).
- Jangan menggunakan `show` atau `hide` kecuali menyelesaikan name conflict.
- Jangan menggunakan wildcard `export` dari barrel file.
- Setiap file hanya meng-import apa yang digunakan.

## 5. Konvensi Dart

### 5.1 Immutability

- Domain model (`Expense`, `ExpenseDraft`, `ExpenseDate`, `HomeSummary`) menggunakan `final class` dengan field `final`.
- UI state class menggunakan field `final`.
- Gunakan `const` constructor kapan pun memungkinkan.
- Koleksi yang di-expose dari view model berupa `List.unmodifiable` atau `UnmodifiableListView`.
- Jangan meng-expose `List` mutable dari state.

### 5.2 Null Safety

- Null safety aktif; tidak ada `// @dart=2.x` override.
- Jangan menggunakan null assertion (`!`) untuk data database atau input pengguna. Parse dan tangani secara eksplisit.
- `String? note` bernilai `null` jika kosong setelah trim. Jangan gunakan empty string.
- Gunakan `?.` dan `??` secara bijak. Jangan chain lebih dari dua level `?.`.

### 5.3 Type Annotations

- Selalu tulis return type untuk method public dan function top-level.
- Variabel lokal boleh menggunakan `var` atau `final` jika tipe sudah jelas dari sisi kanan.
- Jangan menggunakan `dynamic` untuk row database atau domain data. Map segera ke tipe eksplisit.
- Generic type parameter pada koleksi selalu eksplisit: `List<Expense>`, bukan `List`.

### 5.4 Async

- Semua `Future` yang memengaruhi state harus di-`await` dan error-nya ditangani.
- Jangan menggunakan `.then()` chain; gunakan `async/await`.
- `StreamSubscription` selalu dibatalkan di `dispose()`.
- Jangan memanggil `setState()` setelah widget di-dispose. Periksa `mounted` jika menggunakan StatefulWidget, atau gunakan guard pada view model.

### 5.5 Enum

- Kategori menggunakan enum Dart standar.
- Kode persistence stabil berbahasa Inggris (`food`, `transportation`, bukan `makanan`).
- Enum tidak menggunakan `index` untuk persistence; gunakan string code mapping.
- Setiap penambahan/perubahan enum value membutuhkan migration consideration.

### 5.6 Error Handling

- Data layer memetakan exception ke typed application failure (`StorageFailure`, `NotFoundFailure`, dll.).
- Jangan membiarkan exception plugin bocor ke UI.
- Jangan menggunakan `try/catch (e) {}` tanpa penanganan.
- Gunakan satu pola error secara konsisten (typed exception). Jangan mencampur exception dan sealed result pada kontrak yang sama.
- `catch (Object e)` lebih diutamakan daripada `catch (e)` untuk explicitness.

## 6. Konvensi Flutter Widget

### 6.1 Widget Structure

Urutan member dalam widget dan state:

```dart
class ExampleScreen extends StatefulWidget {
  // 1. Constructor
  const ExampleScreen({super.key, required this.repository});

  // 2. Final fields (dependencies)
  final ExpenseRepository repository;

  // 3. createState
  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  // 1. Late/final fields (controllers, subscriptions)
  // 2. Lifecycle: initState, didChangeDependencies, dispose
  // 3. Private methods (event handlers, builders)
  // 4. build
}
```

### 6.2 Build Method

- Jangan menulis method `build()` yang panjang. Ekstrak widget atau method berdasarkan tanggung jawab.
- Jangan menjalankan query, parsing berat, atau format di method `build()`.
- `ListenableBuilder` atau `AnimatedBuilder` membatasi rebuild ke subtree yang relevan.
- Gunakan `const` widget kapan pun memungkinkan untuk menghindari rebuild yang tidak perlu.

### 6.3 Key dan Widget Identity

- Gunakan `super.key` pada constructor widget.
- `ValueKey` digunakan pada list item yang memiliki identity (`ValueKey(expense.id)`).
- Jangan menggunakan `GlobalKey` kecuali benar-benar diperlukan (form validation, navigator).

### 6.4 Layout

- Gunakan `SafeArea` dan tangani keyboard/view insets.
- `ListView.builder` untuk daftar panjang (Transactions).
- Jangan menggunakan `Expanded` di dalam `SingleChildScrollView`.
- Layout diuji pada lebar 320dp dan font size terbesar.

## 7. Konvensi Theme dan Styling

### 7.1 Gunakan Theme, Bukan Magic Values

```dart
// ✅ Benar
final color = Theme.of(context).colorScheme.primary;
final textStyle = Theme.of(context).textTheme.bodyLarge;
final spacing = AppSpacing.md;

// ❌ Salah
final color = Color(0xFF9FE870);
final textStyle = TextStyle(fontSize: 16, fontFamily: 'Inter');
final spacing = 16.0;
```

Aturan:

- Feature widget tidak boleh menggunakan raw `Color(...)`, radius, font family, atau animation duration yang sudah memiliki semantic token.
- Constant UI token ditempatkan pada `core/theme/`, bukan tersebar sebagai magic value.
- Fixture test boleh menggunakan raw value untuk readability.

### 7.2 Component Theme

- Gunakan built-in theme API (`FilledButtonThemeData`, `InputDecorationTheme`, dll.) untuk komponen standar.
- `ThemeExtension` hanya untuk token yang tidak memiliki slot semantik di `ColorScheme` (category colors, summary-card colors).
- Wrapper widget kecil (`ExpenseCard`, `PrimaryActionButton`) boleh ada, tapi tidak boleh menduplikasi token dari theme.

### 7.3 Spacing dan Sizing

- Gunakan constant dari `AppSpacing` untuk padding, margin, dan gap.
- Jangan menggunakan angka literal untuk spacing di widget tree.
- Gunakan `SizedBox` untuk spacing antar-elemen, bukan `Padding` yang membungkus `Container` kosong.

## 8. Konvensi Database dan Data Layer

### 8.1 SQL

- SQL dan nama column hanya berada di `data/` layer.
- Nilai user tidak pernah digabungkan langsung ke string SQL; selalu gunakan parameter binding (`?`).
- Query menggunakan column name eksplisit, bukan `SELECT *` untuk production (kecuali saat ini MVP sederhana sesuai Technical Design).
- Nama tabel dan column menggunakan `snake_case`.

### 8.2 Mapper

- `ExpenseMapper` adalah satu-satunya komponen yang mengubah row database ke domain model dan sebaliknya.
- Database row (`Map<String, Object?>`) tidak boleh dikirim ke UI.
- Mapper memvalidasi data yang dibaca dan menghasilkan `CorruptDataFailure` untuk data tidak valid, bukan diam-diam mengkonversi.

### 8.3 Repository

- Repository mematuhi interface yang didefinisikan di domain.
- Satu pola error konsisten pada seluruh method.
- Change event hanya dipublikasikan setelah write berhasil di-commit.
- Method repository memvalidasi ulang data sebelum write; tidak hanya mengandalkan constraint database.

## 9. Konvensi Test

### 9.1 Penamaan Test

```dart
// Pattern: <kondisi> <aksi/subjek> <expected result>
test('returns ValidationFailure when amount is zero', () { ... });
test('emits created change after successful insert', () { ... });

// Group berdasarkan unit yang diuji
group('ExpenseValidator', () {
  group('validateAmount', () {
    test('rejects zero', () { ... });
    test('rejects amount above maximum', () { ... });
    test('accepts minimum valid amount', () { ... });
  });
});
```

### 9.2 Struktur Test

- Gunakan pola Arrange-Act-Assert atau Given-When-Then.
- Satu assertion logical per test. Beberapa `expect()` untuk satu konsep boleh, tapi jangan menguji concern yang berbeda.
- Setup yang dipakai banyak test ditempatkan di `setUp()` atau helper function.
- Jangan menguji implementation detail (misal: berapa kali method internal dipanggil).

### 9.3 Fakes vs Mocks

- MVP menggunakan handwritten fakes, bukan mocking framework.
- `FakeExpenseRepository` dan `FakeAppClock` berada di `test/helpers/`.
- Fake mengimplementasikan kontrak dan aturan urutan yang sama dengan production.
- Fake dapat dikonfigurasi untuk menghasilkan failure.

### 9.4 Isolasi

- Setiap test berdiri sendiri dan tidak bergantung pada urutan eksekusi.
- Database integration test menggunakan path terisolasi dan dibersihkan per skenario.
- Test tidak menulis ke database development.

## 10. Konvensi Version Control

### 10.1 Commit Message

Format commit message:

```
<type>(<scope>): <deskripsi singkat>

<body opsional: penjelasan lebih lanjut>
```

Type yang tersedia:

| Type | Penggunaan |
| --- | --- |
| `feat` | Fitur baru atau perubahan fungsional |
| `fix` | Perbaikan bug |
| `refactor` | Perubahan kode tanpa mengubah perilaku |
| `style` | Formatting, missing semicolons (bukan CSS) |
| `test` | Menambah atau memperbaiki test |
| `docs` | Perubahan dokumentasi |
| `chore` | Build, tooling, dependency |

Scope mengikuti area kode: `domain`, `data`, `home`, `transactions`, `form`, `theme`, `core`, `db`.

Contoh:

```
feat(form): add grapheme-based character counter for note field

Uses 'characters' package to count user-perceived characters
instead of String.length to handle emoji correctly.
```

### 10.2 Branch

- Branch fitur: `feat/<deskripsi-singkat>`
- Branch fix: `fix/<deskripsi-singkat>`
- Nama branch menggunakan `kebab-case`.

### 10.3 File yang Di-commit dan Di-ignore

Di-commit:

- `pubspec.lock` — wajib karena proyek ini adalah aplikasi, bukan package library.
- `analysis_options.yaml`
- Generated localization files (setelah stabil).
- Font assets dan file lisensinya.

Di-ignore (`.gitignore`):

- `.dart_tool/`
- `build/`
- File signing property yang berisi secret.
- `.env` atau file konfigurasi lokal yang berisi credential.

## 11. Konvensi Komentar dan Dokumentasi

### 11.1 Kapan Menulis Komentar

- Komentar menjelaskan *alasan* atau *constraint*, bukan mengulang kode.
- Tulis komentar ketika keputusan teknis tidak obvious dari kode saja.
- Tulis `// TODO:` untuk pekerjaan yang direncanakan, disertai konteks. Contoh: `// TODO: Evaluate pagination when list exceeds 10k items.`

### 11.2 Doc Comments

- Class public dan method public di domain layer wajib memiliki `///` doc comment.
- Widget screen wajib memiliki doc comment singkat yang menjelaskan tujuannya.
- Private method tidak wajib doc comment jika nama sudah deskriptif.

### 11.3 Yang Tidak Boleh

- Jangan meninggalkan kode yang di-comment (`// oldFunction()`). Hapus dan andalkan version control.
- Jangan menulis komentar yang menjadi stale. Jika mengubah kode, periksa komentar terkait.
- Jangan menulis jurnal perubahan di dalam file source. Gunakan commit history.

## 12. Konvensi Localization

- Semua user-facing strings ditempatkan pada ARB (`app_id.arb`), termasuk validasi dan error message.
- Jangan menulis string UI langsung di repository, database service, atau domain layer.
- Key ARB menggunakan `lowerCamelCase` yang deskriptif. Contoh: `formAmountRequired`, `snackbarExpenseCreated`.
- Placeholder di ARB menggunakan nama parameter yang jelas.
- Generated localization files tidak diedit manual.

## 13. Checklist Review Cepat

Gunakan checklist ini saat code review atau self-review:

- [ ] `dart format` dan `flutter analyze` bersih.
- [ ] Nama class/file mengikuti konvensi bagian 3.
- [ ] Import terurut sesuai bagian 4.2.
- [ ] Tidak ada raw color, radius, font, atau spacing literal di feature widget.
- [ ] Tidak ada `dynamic` untuk data domain atau database.
- [ ] Semua `Future` yang memengaruhi state di-`await` dengan error handling.
- [ ] Tidak ada null assertion (`!`) untuk data dari luar (database/user input).
- [ ] Test menggunakan fake, bukan mock framework.
- [ ] User-facing string ada di ARB.
- [ ] Komentar menjelaskan *alasan*, bukan mengulang kode.
- [ ] Commit message mengikuti format konvensional.
