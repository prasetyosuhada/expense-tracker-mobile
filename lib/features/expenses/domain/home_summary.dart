import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';

/// A snapshot of a month's total and the latest expenses across all months.
final class HomeSummary {
  /// Copies [latestExpenses] so later changes to the input cannot alter this snapshot.
  HomeSummary({
    required this.month,
    required this.monthlyTotal,
    required List<Expense> latestExpenses,
  }) : latestExpenses = List<Expense>.unmodifiable(latestExpenses) {
    if (monthlyTotal < 0) {
      throw RangeError.value(
        monthlyTotal,
        'monthlyTotal',
        'Must be nonnegative',
      );
    }
  }

  /// The month used to calculate [monthlyTotal].
  final ExpenseMonth month;

  /// The total in whole Rupiah for [month].
  final int monthlyTotal;

  /// An unmodifiable snapshot of the globally latest expenses.
  final List<Expense> latestExpenses;
}
