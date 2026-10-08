import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// No description provided for @navigationHome.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navigationHome;

  /// No description provided for @navigationTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get navigationTransactions;

  /// No description provided for @addExpenseAction.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get addExpenseAction;

  /// No description provided for @addExpenseTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Pengeluaran'**
  String get addExpenseTitle;

  /// No description provided for @addExpenseSemanticLabel.
  ///
  /// In id, this message translates to:
  /// **'Tambah pengeluaran'**
  String get addExpenseSemanticLabel;

  /// No description provided for @homeTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get homeTitle;

  /// No description provided for @homeTotalLabel.
  ///
  /// In id, this message translates to:
  /// **'Total pengeluaran'**
  String get homeTotalLabel;

  /// No description provided for @homeRecentTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi terbaru'**
  String get homeRecentTransactions;

  /// No description provided for @homeViewAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get homeViewAll;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pengeluaran'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDescription.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan pengeluaran pertamamu untuk mulai mencatat.'**
  String get homeEmptyDescription;

  /// No description provided for @readErrorTitle.
  ///
  /// In id, this message translates to:
  /// **'Data tidak dapat dimuat'**
  String get readErrorTitle;

  /// No description provided for @readErrorDescription.
  ///
  /// In id, this message translates to:
  /// **'Terjadi masalah saat membuka data pengeluaran.'**
  String get readErrorDescription;

  /// No description provided for @retryAction.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get retryAction;

  /// No description provided for @homeRefreshFailure.
  ///
  /// In id, this message translates to:
  /// **'Data pengeluaran gagal diperbarui. Coba lagi.'**
  String get homeRefreshFailure;

  /// No description provided for @categoryFood.
  ///
  /// In id, this message translates to:
  /// **'Makanan'**
  String get categoryFood;

  /// No description provided for @categoryTransportation.
  ///
  /// In id, this message translates to:
  /// **'Transportasi'**
  String get categoryTransportation;

  /// No description provided for @categoryShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja'**
  String get categoryShopping;

  /// No description provided for @categoryBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get categoryBills;

  /// No description provided for @categoryOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get categoryOther;

  /// No description provided for @editExpenseTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Pengeluaran'**
  String get editExpenseTitle;

  /// No description provided for @formSaveAction.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get formSaveAction;

  /// No description provided for @formSaveChangesAction.
  ///
  /// In id, this message translates to:
  /// **'Simpan Perubahan'**
  String get formSaveChangesAction;

  /// No description provided for @formAmountLabel.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get formAmountLabel;

  /// No description provided for @formAmountPrefix.
  ///
  /// In id, this message translates to:
  /// **'Rp'**
  String get formAmountPrefix;

  /// No description provided for @formAmountRequired.
  ///
  /// In id, this message translates to:
  /// **'Nominal wajib diisi'**
  String get formAmountRequired;

  /// No description provided for @formAmountZero.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih besar dari 0'**
  String get formAmountZero;

  /// No description provided for @formAmountInvalid.
  ///
  /// In id, this message translates to:
  /// **'Nominal tidak valid'**
  String get formAmountInvalid;

  /// No description provided for @formAmountTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Nominal terlalu besar'**
  String get formAmountTooLarge;

  /// No description provided for @formCategoryLabel.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get formCategoryLabel;

  /// No description provided for @formCategoryPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori'**
  String get formCategoryPlaceholder;

  /// No description provided for @formCategoryPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kategori'**
  String get formCategoryPickerTitle;

  /// No description provided for @formCategoryRequired.
  ///
  /// In id, this message translates to:
  /// **'Kategori wajib dipilih'**
  String get formCategoryRequired;

  /// No description provided for @formDateRequired.
  ///
  /// In id, this message translates to:
  /// **'Tanggal wajib dipilih'**
  String get formDateRequired;

  /// No description provided for @formNoteTooLong.
  ///
  /// In id, this message translates to:
  /// **'Catatan maksimal 100 karakter'**
  String get formNoteTooLong;

  /// Label semantik untuk menu tindakan transaksi
  ///
  /// In id, this message translates to:
  /// **'Tindakan transaksi {category} {amount}'**
  String expenseActionMenuSemanticLabel(String category, String amount);

  /// No description provided for @editAction.
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get deleteAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
