import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';

/// Validated expense input without a persistence ID or audit timestamps.
final class ExpenseDraft {
  /// Carries values already validated and normalized by the domain validator.
  const ExpenseDraft({
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.note,
  });

  /// The amount in whole Rupiah.
  final int amount;

  /// The selected fixed category.
  final ExpenseCategory category;

  /// The calendar date without a time or timezone.
  final ExpenseDate transactionDate;

  /// The normalized optional note; blank input is represented by null.
  final String? note;
}
