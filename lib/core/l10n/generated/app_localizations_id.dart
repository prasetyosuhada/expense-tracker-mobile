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
  String get formAmountRequired => 'Nominal wajib diisi';

  @override
  String get formAmountZero => 'Nominal harus lebih besar dari 0';

  @override
  String get formAmountInvalid => 'Nominal tidak valid';

  @override
  String get formAmountTooLarge => 'Nominal terlalu besar';

  @override
  String get formCategoryRequired => 'Kategori wajib dipilih';

  @override
  String get formDateRequired => 'Tanggal wajib dipilih';

  @override
  String get formNoteTooLong => 'Catatan maksimal 100 karakter';
}
