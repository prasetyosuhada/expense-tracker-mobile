import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';

/// Defines expense storage operations without exposing persistence details.
abstract interface class ExpenseRepository {
  /// Emits the kind of each successfully committed expense mutation.
  Stream<ExpenseChange> get changes;

  /// Loads the monthly total and latest expenses for [month].
  ///
  /// [latestLimit] defaults to five latest transactions.
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  });

  /// Loads all saved expenses in canonical order.
  Future<List<Expense>> getAll();

  /// Saves a new expense from a validated [draft].
  Future<Expense> create(ExpenseDraft draft);

  /// Replaces the expense identified by [id] with a validated [draft].
  Future<Expense> update({required int id, required ExpenseDraft draft});

  /// Deletes the expense identified by [id].
  Future<void> delete(int id);
}
