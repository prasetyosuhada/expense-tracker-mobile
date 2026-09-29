import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';

/// Formats calendar dates and month headings in Indonesian.
final class IdDateFormatter {
  /// Registers bundled locale data and caches the three display patterns.
  IdDateFormatter() {
    // Bundled intl data registers synchronously before the returned Future.
    initializeDateFormatting('id_ID');
  }

  late final DateFormat _form = DateFormat('d MMMM yyyy', 'id_ID');
  late final DateFormat _listItem = DateFormat('d MMM yyyy', 'id_ID');
  late final DateFormat _monthHeader = DateFormat('MMMM yyyy', 'id_ID');

  /// Returns a transaction date for the form, e.g. 7 September 2026.
  String formatForm(ExpenseDate date) => _form.format(_calendarDate(date));

  /// Returns a compact transaction date, e.g. 7 Sep 2026.
  String formatListItem(ExpenseDate date) =>
      _listItem.format(_calendarDate(date));

  /// Returns a month title, e.g. September 2026.
  String formatMonthHeader(ExpenseMonth month) =>
      _monthHeader.format(DateTime.utc(month.year, month.month));

  static DateTime _calendarDate(ExpenseDate date) =>
      DateTime.utc(date.year, date.month, date.day);
}
