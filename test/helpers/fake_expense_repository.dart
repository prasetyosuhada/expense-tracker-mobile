import 'dart:async';

import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/expense_validator.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';

/// An isolated in-memory implementation of [ExpenseRepository] for tests.
final class FakeExpenseRepository implements ExpenseRepository {
  /// Copies [initialExpenses] and allocates future IDs above their highest ID.
  FakeExpenseRepository({
    required this._clock,
    Iterable<Expense> initialExpenses = const <Expense>[],
  }) : _expenses = List<Expense>.of(initialExpenses) {
    final ids = <int>{};
    for (final expense in _expenses) {
      if (expense.id <= 0 || !ids.add(expense.id)) {
        throw ArgumentError.value(
          expense.id,
          'initialExpenses',
          'IDs must be unique and positive',
        );
      }
      if (expense.id >= _nextId) {
        _nextId = expense.id + 1;
      }
    }
  }

  final AppClock _clock;
  final List<Expense> _expenses;
  final StreamController<ExpenseChange> _changes =
      StreamController<ExpenseChange>.broadcast();
  final ExpenseValidator _validator = const ExpenseValidator();
  int _nextId = 1;
  bool _isDisposed = false;
  Future<void>? _disposeFuture;

  /// Failure thrown by [getHomeSummary] when set.
  AppFailure? getHomeSummaryFailure;

  /// Failure thrown by [getAll] when set.
  AppFailure? getAllFailure;

  /// Failure thrown by [create] when set, before changing stored data.
  AppFailure? createFailure;

  /// Failure thrown by [update] when set, before changing stored data.
  AppFailure? updateFailure;

  /// Failure thrown by [delete] when set, before changing stored data.
  AppFailure? deleteFailure;

  @override
  Stream<ExpenseChange> get changes => _changes.stream;

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) async {
    _checkAvailable();
    _requirePositive(latestLimit, 'latestLimit');
    final failure = getHomeSummaryFailure;
    if (failure != null) throw failure;

    final total = _expenses
        .where(
          (expense) =>
              expense.transactionDate.year == month.year &&
              expense.transactionDate.month == month.month,
        )
        .fold<int>(0, (sum, expense) => sum + expense.amount);
    return HomeSummary(
      month: month,
      monthlyTotal: total,
      latestExpenses: _ordered().take(latestLimit).toList(),
    );
  }

  @override
  Future<List<Expense>> getAll() async {
    _checkAvailable();
    final failure = getAllFailure;
    if (failure != null) throw failure;
    return _ordered();
  }

  @override
  Future<Expense> create(ExpenseDraft draft) async {
    _checkAvailable();
    final validated = _validator.validate(draft);
    final createdAt = _utcMilliseconds(_clock.now());
    final failure = createFailure;
    if (failure != null) throw failure;

    final expense = Expense(
      id: _nextId++,
      amount: validated.amount,
      category: validated.category,
      transactionDate: validated.transactionDate,
      note: validated.note,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    _expenses.add(expense);
    _changes.add(ExpenseChange.created);
    return expense;
  }

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) async {
    _checkAvailable();
    _requirePositive(id, 'id');
    final validated = _validator.validate(draft);
    final updatedAt = _utcMilliseconds(_clock.now());
    final failure = updateFailure;
    if (failure != null) throw failure;

    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) throw NotFoundFailure(id);
    final original = _expenses[index];
    final updated = Expense(
      id: original.id,
      amount: validated.amount,
      category: validated.category,
      transactionDate: validated.transactionDate,
      note: validated.note,
      createdAt: original.createdAt,
      updatedAt: updatedAt,
    );
    _expenses[index] = updated;
    _changes.add(ExpenseChange.updated);
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    _checkAvailable();
    _requirePositive(id, 'id');
    final failure = deleteFailure;
    if (failure != null) throw failure;

    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) throw NotFoundFailure(id);
    _expenses.removeAt(index);
    _changes.add(ExpenseChange.deleted);
  }

  /// Releases the broadcast stream; seeded and returned objects are immutable.
  Future<void> dispose() {
    _isDisposed = true;
    return _disposeFuture ??= _changes.close();
  }

  List<Expense> _ordered() {
    final sorted = List<Expense>.of(_expenses)..sort(_compareExpenses);
    return List<Expense>.unmodifiable(sorted);
  }

  static int _compareExpenses(Expense first, Expense second) {
    final byDate = second.transactionDate.toIsoString().compareTo(
      first.transactionDate.toIsoString(),
    );
    if (byDate != 0) return byDate;
    final byCreation = second.createdAt.compareTo(first.createdAt);
    if (byCreation != 0) return byCreation;
    return second.id.compareTo(first.id);
  }

  static DateTime _utcMilliseconds(DateTime value) =>
      DateTime.fromMillisecondsSinceEpoch(
        value.millisecondsSinceEpoch,
        isUtc: true,
      );

  static void _requirePositive(int value, String name) {
    if (value <= 0) {
      throw UnexpectedFailure(
        ArgumentError.value(value, name, 'Must be positive'),
      );
    }
  }

  void _checkAvailable() {
    if (_isDisposed) {
      throw UnexpectedFailure(StateError('Expense repository is disposed'));
    }
  }
}
