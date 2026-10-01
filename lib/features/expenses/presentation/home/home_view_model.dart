import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_state.dart';

/// Coordinates the current month's Home snapshot and repository changes.
final class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository, this._clock) {
    _changesSubscription = _repository.changes.listen((_) {
      unawaited(load());
    });
    _scheduleNextDayCheck();
  }

  final ExpenseRepository _repository;
  final AppClock _clock;
  late final StreamSubscription<ExpenseChange> _changesSubscription;
  Timer? _dayTimer;
  HomeState _state = const HomeInitial();
  HomeSummary? _snapshot;
  AppFailure? _refreshFailure;
  int _requestGeneration = 0;
  bool _isDisposed = false;
  bool _isForeground = true;

  HomeState get state => _state;

  /// The latest refresh failure, intended for one-time UI feedback.
  AppFailure? takeRefreshFailure() {
    final failure = _refreshFailure;
    _refreshFailure = null;
    return failure;
  }

  /// Loads Home, keeping any previously valid snapshot during refresh.
  Future<void> load() async {
    if (_isDisposed) return;

    final generation = ++_requestGeneration;
    final month = _currentMonth();
    final previous = _snapshot;
    _refreshFailure = null;
    _setState(
      previous == null ? const HomeLoading() : HomeRefreshing(previous),
    );

    try {
      final summary = await _repository.getHomeSummary(month: month);
      if (!_isCurrent(generation)) return;
      _snapshot = summary;
      _setState(HomeData(summary));
    } on AppFailure catch (failure) {
      _handleReadFailure(generation, failure);
    } on Object catch (error) {
      _handleReadFailure(generation, UnexpectedFailure(error));
    }
  }

  /// Rechecks the local month after the app returns to the foreground.
  Future<void> onResume() async {
    if (_isDisposed) return;
    _isForeground = true;
    _scheduleNextDayCheck();
    if (_snapshot == null ||
        _state is HomeError ||
        _snapshot?.month != _currentMonth()) {
      await load();
    }
  }

  /// Stops day-boundary checks while Home is in the background.
  void onPause() {
    if (_isDisposed) return;
    _isForeground = false;
    _dayTimer?.cancel();
    _dayTimer = null;
  }

  void _handleReadFailure(int generation, AppFailure failure) {
    if (!_isCurrent(generation)) return;
    if (failure is CorruptDataFailure) {
      _snapshot = null;
      _refreshFailure = null;
      _setState(HomeError(failure));
      return;
    }
    final previous = _snapshot;
    if (previous == null) {
      _setState(HomeError(failure));
      return;
    }
    _refreshFailure = failure;
    _setState(HomeData(previous));
  }

  bool _isCurrent(int generation) =>
      !_isDisposed && generation == _requestGeneration;

  ExpenseMonth _currentMonth() {
    final now = _clock.now();
    return ExpenseMonth(now.year, now.month);
  }

  void _scheduleNextDayCheck() {
    _dayTimer?.cancel();
    if (_isDisposed || !_isForeground) return;
    final now = _clock.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final delay = nextDay.difference(now);
    _dayTimer = Timer(delay, () {
      if (_isDisposed || !_isForeground) return;
      if (_snapshot?.month != _currentMonth()) {
        unawaited(load());
      }
      _scheduleNextDayCheck();
    });
  }

  void _setState(HomeState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _requestGeneration++;
    _dayTimer?.cancel();
    _dayTimer = null;
    unawaited(_changesSubscription.cancel());
    super.dispose();
  }
}
