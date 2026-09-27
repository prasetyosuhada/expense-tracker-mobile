import 'package:expensetracker/features/expenses/domain/expense_date.dart';

/// A calendar month with ISO boundaries for a half-open storage query.
final class ExpenseMonth {
  /// Creates a month whose start and exclusive end fit four-digit ISO years.
  ///
  /// Throws [ArgumentError] for invalid components or December 9999, whose
  /// exclusive boundary would require a five-digit year.
  ExpenseMonth(this.year, this.month) {
    ExpenseDate(year, month, 1);
    if (year == 9999 && month == 12) {
      throw ArgumentError('Exclusive month boundary exceeds ISO year range');
    }
  }

  /// The calendar year.
  final int year;

  /// The calendar month, from 1 through 12.
  final int month;

  /// The first day of this month, included in the query.
  String get startInclusive => ExpenseDate(year, month, 1).toIsoString();

  /// The first day of the following month, excluded from the query.
  String get endExclusive {
    final nextYear = month == 12 ? year + 1 : year;
    final nextMonth = month == 12 ? 1 : month + 1;
    return ExpenseDate(nextYear, nextMonth, 1).toIsoString();
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseMonth && year == other.year && month == other.month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}
