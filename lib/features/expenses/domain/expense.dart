import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';

/// An immutable persisted expense with validated values and UTC audit times.
final class Expense {
  /// Carries validated persistence values supplied by the repository.
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The positive database identifier.
  final int id;

  /// The amount in whole Rupiah.
  final int amount;

  /// The fixed expense category.
  final ExpenseCategory category;

  /// The calendar date without a time or timezone.
  final ExpenseDate transactionDate;

  /// The normalized optional note.
  final String? note;

  /// The creation instant in UTC.
  final DateTime createdAt;

  /// The last update instant in UTC.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is Expense &&
        id == other.id &&
        amount == other.amount &&
        category == other.category &&
        transactionDate == other.transactionDate &&
        note == other.note &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    category,
    transactionDate,
    note,
    createdAt,
    updatedAt,
  );
}
