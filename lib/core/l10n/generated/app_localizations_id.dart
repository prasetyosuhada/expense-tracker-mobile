// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get navigationHome => 'Beranda';

  @override
  String get navigationTransactions => 'Transaksi';

  @override
  String get addExpenseAction => 'Tambah';

  @override
  String get addExpenseTitle => 'Tambah Pengeluaran';

  @override
  String get addExpenseSemanticLabel => 'Tambah pengeluaran';

  @override
  String get homeTitle => 'Pengeluaran';

  @override
  String get homeTotalLabel => 'Total pengeluaran';

  @override
  String get homeRecentTransactions => 'Transaksi terbaru';

  @override
  String get homeViewAll => 'Lihat semua';

  @override
  String get homeEmptyTitle => 'Belum ada pengeluaran';

  @override
  String get homeEmptyDescription =>
      'Tambahkan pengeluaran pertamamu untuk mulai mencatat.';

  @override
  String get readErrorTitle => 'Data tidak dapat dimuat';

  @override
  String get readErrorDescription =>
      'Terjadi masalah saat membuka data pengeluaran.';

  @override
  String get retryAction => 'Coba Lagi';

  @override
  String get homeRefreshFailure =>
      'Data pengeluaran gagal diperbarui. Coba lagi.';

  @override
  String get transactionsTitle => 'Transaksi';

  @override
  String get transactionsEmptyTitle => 'Belum ada transaksi';

  @override
  String get transactionsEmptyDescription =>
      'Pengeluaran yang kamu tambahkan akan muncul di sini.';

  @override
  String get transactionsRefreshFailure =>
      'Data transaksi gagal diperbarui. Coba lagi.';

  @override
  String get categoryFood => 'Makanan';

  @override
  String get categoryTransportation => 'Transportasi';

  @override
  String get categoryShopping => 'Belanja';

  @override
  String get categoryBills => 'Tagihan';

  @override
  String get categoryOther => 'Lainnya';

  @override
  String get editExpenseTitle => 'Edit Pengeluaran';

  @override
  String get formSaveAction => 'Simpan';

  @override
  String get formSaveChangesAction => 'Simpan Perubahan';

  @override
  String get formAmountLabel => 'Nominal';

  @override
  String get formAmountPrefix => 'Rp';

  @override
  String get formAmountRequired => 'Nominal wajib diisi';

  @override
  String get formAmountZero => 'Nominal harus lebih besar dari 0';

  @override
  String get formAmountInvalid => 'Nominal tidak valid';

  @override
  String get formAmountTooLarge => 'Nominal terlalu besar';

  @override
  String get formCategoryLabel => 'Kategori';

  @override
  String get formCategoryPlaceholder => 'Pilih kategori';

  @override
  String get formCategoryPickerTitle => 'Pilih Kategori';

  @override
  String get formCategoryRequired => 'Kategori wajib dipilih';

  @override
  String get formDateLabel => 'Tanggal';

  @override
  String get formDateRequired => 'Tanggal wajib dipilih';

  @override
  String get formNoteLabel => 'Catatan';

  @override
  String get formNotePlaceholder => 'Contoh: Makan siang bersama teman';

  @override
  String get formNoteTooLong => 'Catatan maksimal 100 karakter';

  @override
  String expenseActionMenuSemanticLabel(String category, String amount) {
    return 'Tindakan transaksi $category $amount';
  }

  @override
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Hapus';

  @override
  String get discardChangesTitle => 'Buang perubahan?';

  @override
  String get discardChangesMessage =>
      'Perubahan yang belum disimpan akan hilang.';

  @override
  String get discardChangesStayAction => 'Tetap di sini';

  @override
  String get discardChangesDiscardAction => 'Buang';

  @override
  String get expenseAddedSuccess => 'Pengeluaran berhasil ditambahkan';

  @override
  String get expenseUpdatedSuccess => 'Pengeluaran berhasil diperbarui';

  @override
  String get expenseAddFailed => 'Pengeluaran gagal disimpan. Coba lagi.';

  @override
  String get expenseUpdateFailed => 'Perubahan gagal disimpan. Coba lagi.';
}
