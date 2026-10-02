import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_state.dart';

/// Coordinates transaction snapshots and independently pending deletions.
final class TransactionsViewModel extends ChangeNotifier {
  TransactionsViewModel(this._repository) {
    _changesSubscription = _repository.changes.listen((_) {
      unawaited(load());
    });
  }

  final ExpenseRepository _repository;
  late final StreamSubscription<ExpenseChange> _changesSubscription;
  final Set<int> _deletingIds = <int>{};
  final Map<int, AppFailure> _deleteFailures = <int, AppFailure>{};
  TransactionsState _state = const TransactionsInitial();
  List<Expense>? _snapshot;
  AppFailure? _refreshFailure;
  int _requestGeneration = 0;
  bool _isDisposed = false;

  TransactionsState get state => _state;

  Set<int> get deletingIds => Set<int>.unmodifiable(_deletingIds);

  bool isDeleting(int id) => _deletingIds.contains(id);

  /// Consumes feedback for the latest failed refresh once.
  AppFailure? takeRefreshFailure() {
    final failure = _refreshFailure;
    _refreshFailure = null;
    return failure;
  }

  /// Consumes failed-delete feedback for one item without affecting others.
  AppFailure? takeDeleteFailure(int id) => _deleteFailures.remove(id);

  Future<void> load() async {
    if (_isDisposed) return;

    final generation = ++_requestGeneration;
    final previous = _snapshot;
    _refreshFailure = null;
    _setState(
      previous == null
          ? const TransactionsLoading()
          : TransactionsRefreshing(previous),
    );

    try {
      final expenses = await _repository.getAll();
      if (!_isCurrent(generation)) return;
      final data = TransactionsData(expenses);
      _snapshot = data.expenses;
      _setState(data);
    } on AppFailure catch (failure) {
      _handleReadFailure(generation, failure);
    } on Object catch (error) {
      _handleReadFailure(generation, UnexpectedFailure(error));
    }
  }

  /// Retries reads that have not yet produced a valid snapshot.
  Future<void> onResume() async {
    if (_isDisposed) return;
    if (_snapshot == null || _state is TransactionsError) {
      await load();
    }
  }

  /// Returns true only when deletion commits successfully.
  ///
  /// Failed, duplicate, and disposed calls return false. Failures can be read
  /// through [takeDeleteFailure]; committed changes refresh via the repository.
  Future<bool> deleteExpense(int id) async {
    if (_isDisposed || !_deletingIds.add(id)) return false;
    _deleteFailures.remove(id);
    notifyListeners();

    try {
      await _repository.delete(id);
      return true;
    } on AppFailure catch (failure) {
      _handleDeleteFailure(id, failure);
      return false;
    } on Object catch (error) {
      _handleDeleteFailure(id, UnexpectedFailure(error));
      return false;
    } finally {
      _deletingIds.remove(id);
      if (!_isDisposed) notifyListeners();
    }
  }

  void _handleDeleteFailure(int id, AppFailure failure) {
    if (_isDisposed) return;
    _deleteFailures[id] = failure;
    // A missing row cannot emit a write event; reconcile the stale snapshot.
    if (failure is NotFoundFailure) unawaited(load());
  }

  void _handleReadFailure(int generation, AppFailure failure) {
    if (!_isCurrent(generation)) return;
    if (failure is CorruptDataFailure) {
      _snapshot = null;
      _refreshFailure = null;
      _setState(TransactionsError(failure));
      return;
    }
    final previous = _snapshot;
    if (previous == null) {
      _setState(TransactionsError(failure));
      return;
    }
    _refreshFailure = failure;
    _setState(TransactionsData(previous));
  }

  bool _isCurrent(int generation) =>
      !_isDisposed && generation == _requestGeneration;

  void _setState(TransactionsState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _requestGeneration++;
    _deleteFailures.clear();
    _deletingIds.clear();
    unawaited(_changesSubscription.cancel());
    super.dispose();
  }
}
