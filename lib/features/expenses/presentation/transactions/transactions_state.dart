import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';

/// The immutable state currently presented by Transactions.
sealed class TransactionsState {
  const TransactionsState();
}

final class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

final class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

/// All transactions in repository order, protected from external mutation.
final class TransactionsData extends TransactionsState {
  TransactionsData(List<Expense> expenses)
    : expenses = List<Expense>.unmodifiable(expenses);

  final List<Expense> expenses;
}

/// The last valid snapshot remains visible while a new read is pending.
final class TransactionsRefreshing extends TransactionsState {
  TransactionsRefreshing(List<Expense> expenses)
    : expenses = List<Expense>.unmodifiable(expenses);

  final List<Expense> expenses;
}

final class TransactionsError extends TransactionsState {
  const TransactionsError(this.failure);

  final AppFailure failure;
}
