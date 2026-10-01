import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_state.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_view_model.dart';

import '../../../../helpers/fake_app_clock.dart';
import '../../../../helpers/fake_expense_repository.dart';

void main() {
  late FakeAppClock clock;
  late FakeExpenseRepository fake;
  HomeViewModel? model;

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 9, 8, 12));
    fake = FakeExpenseRepository(clock: clock);
  });

  tearDown(() async {
    model?.dispose();
    model = null;
    await fake.dispose();
  });

  test('initial load moves from loading to current-month data', () async {
    await fake.create(_draft(amount: 1200));
    await fake.create(_draft(amount: 3000, date: ExpenseDate(2026, 8, 31)));
    model = HomeViewModel(fake, clock);
    final states = <HomeState>[model!.state];
    model!.addListener(() => states.add(model!.state));

    await model!.load();

    expect(states.map((state) => state.runtimeType), <Type>[
      HomeInitial,
      HomeLoading,
      HomeData,
    ]);
    final summary = (model!.state as HomeData).summary;
    expect(summary.month, ExpenseMonth(2026, 9));
    expect(summary.monthlyTotal, 1200);
    expect(summary.latestExpenses.length, 2);
  });

  test('home keeps five latest expenses across all months', () async {
    for (var day = 1; day <= 6; day++) {
      await fake.create(_draft(amount: day, date: ExpenseDate(2026, 8, day)));
    }
    model = HomeViewModel(fake, clock);

    await model!.load();

    final summary = (model!.state as HomeData).summary;
    expect(summary.monthlyTotal, 0);
    expect(summary.latestExpenses.map((expense) => expense.amount), <int>[
      6,
      5,
      4,
      3,
      2,
    ]);
  });

  test('initial failure can be retried without inventing empty data', () async {
    const failure = StorageFailure(null);
    fake.getHomeSummaryFailure = failure;
    model = HomeViewModel(fake, clock);

    await model!.load();
    expect((model!.state as HomeError).failure, same(failure));
    fake.getHomeSummaryFailure = null;
    final retry = model!.load();
    expect(model!.state, isA<HomeLoading>());
    await retry;
    expect((model!.state as HomeData).summary.monthlyTotal, 0);
  });

  test(
    'repository change refreshes the snapshot while keeping old data',
    () async {
      model = HomeViewModel(fake, clock);
      await model!.load();
      final states = <HomeState>[];
      model!.addListener(() => states.add(model!.state));

      await fake.create(_draft(amount: 25000));
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<HomeRefreshing>());
      expect((states.first as HomeRefreshing).summary.monthlyTotal, 0);
      expect((model!.state as HomeData).summary.monthlyTotal, 25000);
      expect(states.last, isA<HomeData>());
    },
  );

  test('update and delete events refresh the monthly total', () async {
    final expense = await fake.create(_draft(amount: 100));
    model = HomeViewModel(fake, clock);
    await model!.load();

    await fake.update(id: expense.id, draft: _draft(amount: 250));
    await Future<void>.delayed(Duration.zero);
    expect((model!.state as HomeData).summary.monthlyTotal, 250);

    await fake.delete(expense.id);
    await Future<void>.delayed(Duration.zero);
    expect((model!.state as HomeData).summary.monthlyTotal, 0);
  });

  test(
    'refresh failure retains the snapshot and exposes one feedback event',
    () async {
      model = HomeViewModel(fake, clock);
      await model!.load();
      const failure = StorageFailure(null);
      fake.getHomeSummaryFailure = failure;

      await model!.load();

      expect((model!.state as HomeData).summary.monthlyTotal, 0);
      expect(model!.takeRefreshFailure(), same(failure));
      expect(model!.takeRefreshFailure(), isNull);
      fake.getHomeSummaryFailure = null;
      await model!.load();
      expect(model!.takeRefreshFailure(), isNull);
    },
  );

  test(
    'corrupt refresh becomes read error instead of showing old data',
    () async {
      model = HomeViewModel(fake, clock);
      await model!.load();
      const failure = CorruptDataFailure('invalid stored category');
      fake.getHomeSummaryFailure = failure;

      await model!.load();

      expect((model!.state as HomeError).failure, same(failure));
      expect(model!.takeRefreshFailure(), isNull);

      fake.getHomeSummaryFailure = null;
      final retry = model!.load();
      expect(model!.state, isA<HomeLoading>());
      await retry;
      expect(model!.state, isA<HomeData>());
    },
  );

  test('older success and failure cannot replace a newer result', () async {
    final controlled = _ControlledHomeRepository(fake);
    model = HomeViewModel(controlled, clock);
    final oldRequest = model!.load();
    final newRequest = model!.load();
    final newSummary = HomeSummary(
      month: ExpenseMonth(2026, 9),
      monthlyTotal: 42,
      latestExpenses: <Expense>[],
    );

    controlled.pending[1].complete(newSummary);
    await newRequest;
    controlled.pending[0].completeError(const StorageFailure(null));
    await oldRequest;

    expect((model!.state as HomeData).summary, same(newSummary));
    expect(model!.takeRefreshFailure(), isNull);

    final olderSuccess = model!.load();
    final newerSuccess = model!.load();
    controlled.pending[3].complete(newSummary);
    await newerSuccess;
    controlled.pending[2].complete(
      HomeSummary(
        month: ExpenseMonth(2026, 9),
        monthlyTotal: 99,
        latestExpenses: <Expense>[],
      ),
    );
    await olderSuccess;
    expect((model!.state as HomeData).summary, same(newSummary));
  });

  test('resume retries error and updates a changed local month', () async {
    await fake.create(_draft(amount: 500, date: ExpenseDate(2026, 10, 1)));
    model = HomeViewModel(fake, clock);
    fake.getHomeSummaryFailure = const StorageFailure(null);
    await model!.load();
    model!.onPause();
    fake.getHomeSummaryFailure = null;
    await model!.onResume();
    expect(model!.state, isA<HomeData>());

    model!.onPause();
    clock.currentTime = DateTime(2026, 10, 1, 8);
    await model!.onResume();
    final summary = (model!.state as HomeData).summary;
    expect(summary.month, ExpenseMonth(2026, 10));
    expect(summary.monthlyTotal, 500);
  });

  test('resume loads Home when no initial read has happened', () async {
    model = HomeViewModel(fake, clock);
    model!.onPause();

    await model!.onResume();

    expect(model!.state, isA<HomeData>());
  });

  testWidgets('day-boundary timer refreshes when the local month changes', (
    tester,
  ) async {
    clock.currentTime = DateTime(2026, 9, 30, 23, 59, 50);
    await fake.create(_draft(amount: 100, date: ExpenseDate(2026, 9, 30)));
    await fake.create(_draft(amount: 200, date: ExpenseDate(2026, 10, 1)));
    model = HomeViewModel(fake, clock);
    await model!.load();
    expect((model!.state as HomeData).summary.monthlyTotal, 100);

    clock.currentTime = DateTime(2026, 10, 1);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    final summary = (model!.state as HomeData).summary;
    expect(summary.month, ExpenseMonth(2026, 10));
    expect(summary.monthlyTotal, 200);
    model!.dispose();
    model = null;
  });

  testWidgets('dispose cancels the day-boundary timer', (tester) async {
    clock.currentTime = DateTime(2026, 9, 30, 23, 59, 50);
    final controlled = _ControlledHomeRepository(fake);
    model = HomeViewModel(controlled, clock);
    final initial = model!.load();
    controlled.pending.single.complete(
      HomeSummary(
        month: ExpenseMonth(2026, 9),
        monthlyTotal: 0,
        latestExpenses: <Expense>[],
      ),
    );
    await initial;
    model!.dispose();

    clock.currentTime = DateTime(2026, 10, 1);
    await tester.pump(const Duration(seconds: 10));

    expect(controlled.pending.length, 1);
    model = null;
  });

  test(
    'dispose ignores pending reads and cancels the change subscription',
    () async {
      final controlled = _ControlledHomeRepository(fake);
      model = HomeViewModel(controlled, clock);
      final pending = model!.load();
      expect(model!.state, isA<HomeLoading>());

      model!.dispose();
      controlled.pending.single.complete(
        HomeSummary(
          month: ExpenseMonth(2026, 9),
          monthlyTotal: 1,
          latestExpenses: <Expense>[],
        ),
      );
      await pending;
      await fake.create(_draft(amount: 1));
      await Future<void>.delayed(Duration.zero);

      expect(model!.state, isA<HomeLoading>());
      expect(controlled.pending.length, 1);
    },
  );
}

ExpenseDraft _draft({int amount = 1000, ExpenseDate? date}) => ExpenseDraft(
  amount: amount,
  category: ExpenseCategory.food,
  transactionDate: date ?? ExpenseDate(2026, 9, 8),
  note: null,
);

/// Delays only Home reads; all other behavior still comes from the shared fake.
final class _ControlledHomeRepository implements ExpenseRepository {
  _ControlledHomeRepository(this.delegate);

  final FakeExpenseRepository delegate;
  final List<Completer<HomeSummary>> pending = <Completer<HomeSummary>>[];

  @override
  Stream<ExpenseChange> get changes => delegate.changes;

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) {
    final completer = Completer<HomeSummary>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<List<Expense>> getAll() => delegate.getAll();

  @override
  Future<Expense> create(ExpenseDraft draft) => delegate.create(draft);

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) =>
      delegate.update(id: id, draft: draft);

  @override
  Future<void> delete(int id) => delegate.delete(id);
}
