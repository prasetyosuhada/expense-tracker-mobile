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
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_state.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';

import '../../../../helpers/fake_app_clock.dart';
import '../../../../helpers/fake_expense_repository.dart';

void main() {
  late FakeAppClock clock;
  late FakeExpenseRepository fake;
  late _ControlledTransactionsRepository controlled;
  late TransactionsViewModel model;

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 10, 2, 12));
    fake = FakeExpenseRepository(clock: clock);
    controlled = _ControlledTransactionsRepository(fake);
    model = TransactionsViewModel(controlled);
  });

  tearDown(() async {
    model.dispose();
    await fake.dispose();
  });

  group('load and refresh', () {
    test(
      'initial load stays loading until an empty snapshot arrives',
      () async {
        controlled.delayReads = true;
        final states = <TransactionsState>[model.state];
        model.addListener(() => states.add(model.state));

        final load = model.load();
        expect(model.state, isA<TransactionsLoading>());
        controlled.pendingReads.single.complete(<Expense>[]);
        await load;

        expect(states.map((state) => state.runtimeType), <Type>[
          TransactionsInitial,
          TransactionsLoading,
          TransactionsData,
        ]);
        expect((model.state as TransactionsData).expenses, isEmpty);
      },
    );

    test('loads all transactions in canonical order across months', () async {
      final older = await fake.create(_draft(date: ExpenseDate(2026, 9, 30)));
      for (var index = 0; index < 6; index++) {
        await fake.create(_draft(amount: index + 1));
      }
      clock.currentTime = clock.currentTime.add(const Duration(seconds: 1));
      final newer = await fake.create(_draft(amount: 7));
      await _flushEvents();

      await model.load();

      final expenses = (model.state as TransactionsData).expenses;
      expect(expenses.length, 8);
      expect(expenses.map((expense) => expense.id), <int>[
        newer.id,
        7,
        6,
        5,
        4,
        3,
        2,
        older.id,
      ]);
    });

    test('initial failure retries through loading to data', () async {
      const failure = StorageFailure(null);
      fake.getAllFailure = failure;

      await model.load();

      expect((model.state as TransactionsError).failure, same(failure));
      expect(model.takeRefreshFailure(), isNull);
      fake.getAllFailure = null;
      final retry = model.load();
      expect(model.state, isA<TransactionsLoading>());
      await retry;
      expect((model.state as TransactionsData).expenses, isEmpty);
    });

    test(
      'create and update events refresh while keeping the snapshot',
      () async {
        await model.load();
        final states = <TransactionsState>[];
        model.addListener(() => states.add(model.state));

        final expense = await fake.create(_draft(amount: 25000));
        await _flushEvents();

        expect((states.first as TransactionsRefreshing).expenses, isEmpty);
        expect((model.state as TransactionsData).expenses, <Expense>[expense]);

        states.clear();
        final updated = await fake.update(
          id: expense.id,
          draft: _draft(amount: 30000, date: ExpenseDate(2026, 9, 1)),
        );
        await _flushEvents();

        expect((states.first as TransactionsRefreshing).expenses, <Expense>[
          expense,
        ]);
        expect((model.state as TransactionsData).expenses, <Expense>[updated]);
      },
    );

    test('refresh failure keeps data and supplies feedback once', () async {
      final expense = await fake.create(_draft());
      await _flushEvents();
      await model.load();
      const failure = StorageFailure(null);
      fake.getAllFailure = failure;

      await model.load();

      expect((model.state as TransactionsData).expenses, <Expense>[expense]);
      expect(model.takeRefreshFailure(), same(failure));
      expect(model.takeRefreshFailure(), isNull);
      fake.getAllFailure = null;
      await model.load();
      expect(model.takeRefreshFailure(), isNull);
    });

    test(
      'corrupt refresh becomes a read error and clears the snapshot',
      () async {
        await model.load();
        const failure = CorruptDataFailure('invalid stored category');
        fake.getAllFailure = failure;

        await model.load();

        expect((model.state as TransactionsError).failure, same(failure));
        expect(model.takeRefreshFailure(), isNull);
        fake.getAllFailure = null;
        final retry = model.load();
        expect(model.state, isA<TransactionsLoading>());
        await retry;
        expect(model.state, isA<TransactionsData>());
      },
    );

    test('unexpected read errors become typed application failures', () async {
      final error = StateError('unmapped read error');
      controlled.readError = error;

      await model.load();

      final failure = (model.state as TransactionsError).failure;
      expect(failure, isA<UnexpectedFailure>());
      expect((failure as UnexpectedFailure).cause, same(error));
    });

    test('older failures and successes cannot replace newer data', () async {
      final expense = await fake.create(_draft());
      await _flushEvents();
      controlled.delayReads = true;
      final oldFailure = model.load();
      final newRead = model.load();
      controlled.pendingReads[1].complete(<Expense>[expense]);
      await newRead;
      controlled.pendingReads[0].completeError(
        const CorruptDataFailure('obsolete response'),
      );
      await oldFailure;
      expect((model.state as TransactionsData).expenses, <Expense>[expense]);
      expect(model.takeRefreshFailure(), isNull);

      final oldSuccess = model.load();
      final latest = model.load();
      controlled.pendingReads[3].complete(<Expense>[expense]);
      await latest;
      controlled.pendingReads[2].complete(<Expense>[]);
      await oldSuccess;
      expect((model.state as TransactionsData).expenses, <Expense>[expense]);
    });

    test(
      'an event invalidates a pending read with an older snapshot',
      () async {
        await model.load();
        controlled.delayReads = true;
        final oldRead = model.load();
        final expense = await fake.create(_draft());
        await _flushEvents();

        controlled.pendingReads[1].complete(<Expense>[expense]);
        await _flushEvents();
        controlled.pendingReads[0].complete(<Expense>[]);
        await oldRead;

        expect((model.state as TransactionsData).expenses, <Expense>[expense]);
      },
    );

    test('resume loads initial state and retries an initial error', () async {
      fake.getAllFailure = const StorageFailure(null);
      await model.onResume();
      expect(model.state, isA<TransactionsError>());

      fake.getAllFailure = null;
      await model.onResume();
      expect(model.state, isA<TransactionsData>());
      final reads = controlled.readCount;
      await model.onResume();
      expect(controlled.readCount, reads);
    });

    test('data and refreshing states copy and protect their lists', () async {
      final expense = await fake.create(_draft());
      await _flushEvents();
      final source = <Expense>[expense];
      final data = TransactionsData(source);
      final refreshing = TransactionsRefreshing(source);
      source.clear();

      expect(data.expenses, <Expense>[expense]);
      expect(refreshing.expenses, <Expense>[expense]);
      expect(data.expenses.clear, throwsUnsupportedError);
      expect(refreshing.expenses.clear, throwsUnsupportedError);
    });
  });

  group('deleteExpense', () {
    late Expense first;
    late Expense second;

    setUp(() async {
      first = await fake.create(_draft());
      second = await fake.create(_draft(amount: 2000));
      await _flushEvents();
      await model.load();
      controlled.delayDeletes = true;
    });

    test(
      'only the selected ID is loading and duplicate calls are ignored',
      () async {
        final snapshots = <Set<int>>[];
        model.addListener(() => snapshots.add(model.deletingIds));
        final deletion = model.deleteExpense(first.id);

        expect(model.isDeleting(first.id), isTrue);
        expect(model.isDeleting(second.id), isFalse);
        expect(await model.deleteExpense(first.id), isFalse);
        expect(controlled.deleteIds, <int>[first.id]);
        final inFlight = model.deletingIds;
        expect(inFlight.clear, throwsUnsupportedError);
        expect((model.state as TransactionsData).expenses.length, 2);

        controlled.pendingDeletes[first.id]!.complete();
        expect(await deletion, isTrue);
        await _flushEvents();

        expect(inFlight, <int>{first.id});
        expect(model.deletingIds, isEmpty);
        expect(snapshots.first, <int>{first.id});
        expect(snapshots.last, isEmpty);
        expect((model.state as TransactionsData).expenses, <Expense>[second]);
        expect(model.takeDeleteFailure(first.id), isNull);
      },
    );

    test('different IDs can be deleted independently', () async {
      final deleteFirst = model.deleteExpense(first.id);
      final deleteSecond = model.deleteExpense(second.id);
      expect(model.deletingIds, <int>{first.id, second.id});

      controlled.pendingDeletes[first.id]!.complete();
      expect(await deleteFirst, isTrue);
      await _flushEvents();
      expect(model.deletingIds, <int>{second.id});
      expect((model.state as TransactionsData).expenses, <Expense>[second]);

      controlled.pendingDeletes[second.id]!.complete();
      expect(await deleteSecond, isTrue);
      await _flushEvents();
      expect(model.deletingIds, isEmpty);
      expect((model.state as TransactionsData).expenses, isEmpty);
    });

    test(
      'failure clears item loading, preserves data, and allows retry',
      () async {
        const failure = StorageFailure(null);
        final before = (model.state as TransactionsData).expenses;
        final deletion = model.deleteExpense(first.id);
        controlled.pendingDeletes[first.id]!.completeError(failure);

        expect(await deletion, isFalse);
        expect(model.deletingIds, isEmpty);
        expect((model.state as TransactionsData).expenses, same(before));
        expect(await fake.getAll(), before);
        expect(model.takeDeleteFailure(first.id), same(failure));
        expect(model.takeDeleteFailure(first.id), isNull);

        final retry = model.deleteExpense(first.id);
        controlled.pendingDeletes[first.id]!.complete();
        expect(await retry, isTrue);
        await _flushEvents();
        expect((model.state as TransactionsData).expenses, <Expense>[second]);
      },
    );

    test('feedback for failed deletions is isolated by ID', () async {
      const firstFailure = StorageFailure(null);
      final secondError = StateError('unmapped delete error');
      final deleteFirst = model.deleteExpense(first.id);
      final deleteSecond = model.deleteExpense(second.id);
      controlled.pendingDeletes[first.id]!.completeError(firstFailure);
      controlled.pendingDeletes[second.id]!.completeError(secondError);

      expect(await deleteFirst, isFalse);
      expect(await deleteSecond, isFalse);
      expect(model.takeDeleteFailure(first.id), same(firstFailure));
      final failure = model.takeDeleteFailure(second.id);
      expect(failure, isA<UnexpectedFailure>());
      expect((failure as UnexpectedFailure).cause, same(secondError));
      expect(model.deletingIds, isEmpty);
      expect((model.state as TransactionsData).expenses.length, 2);
    });

    test('retry clears unread failure feedback for that item', () async {
      final deletion = model.deleteExpense(first.id);
      controlled.pendingDeletes[first.id]!.completeError(
        const StorageFailure(null),
      );
      expect(await deletion, isFalse);

      final retry = model.deleteExpense(first.id);
      expect(model.takeDeleteFailure(first.id), isNull);
      controlled.pendingDeletes[first.id]!.complete();
      expect(await retry, isTrue);
      await _flushEvents();
    });

    test(
      'missing ID supplies failure feedback and reloads the snapshot',
      () async {
        final reads = controlled.readCount;
        const missingId = 999;
        final deletion = model.deleteExpense(missingId);
        controlled.pendingDeletes[missingId]!.complete();

        expect(await deletion, isFalse);
        await _flushEvents();

        expect(model.takeDeleteFailure(missingId), isA<NotFoundFailure>());
        expect(controlled.readCount, reads + 1);
        expect((model.state as TransactionsData).expenses.length, 2);
        expect(model.isDeleting(missingId), isFalse);
      },
    );

    test(
      'committed delete stays successful when the subsequent refresh fails',
      () async {
        const failure = StorageFailure(null);
        fake.getAllFailure = failure;
        final before = (model.state as TransactionsData).expenses;
        final deletion = model.deleteExpense(first.id);
        controlled.pendingDeletes[first.id]!.complete();

        expect(await deletion, isTrue);
        await _flushEvents();

        expect(model.takeDeleteFailure(first.id), isNull);
        expect(model.takeRefreshFailure(), same(failure));
        expect((model.state as TransactionsData).expenses, before);
        fake.getAllFailure = null;
        expect(await fake.getAll(), <Expense>[second]);
        await model.load();
        expect((model.state as TransactionsData).expenses, <Expense>[second]);
      },
    );

    for (final shouldFail in <bool>[false, true]) {
      test(
        'dispose ignores pending deletion ${shouldFail ? 'failure' : 'success'}',
        () async {
          var notifications = 0;
          model.addListener(() => notifications++);
          final deletion = model.deleteExpense(first.id);
          final before = notifications;
          model.dispose();
          if (shouldFail) {
            controlled.pendingDeletes[first.id]!.completeError(
              const StorageFailure(null),
            );
          } else {
            controlled.pendingDeletes[first.id]!.complete();
          }

          expect(await deletion, !shouldFail);
          await _flushEvents();

          expect(notifications, before);
          expect(model.deletingIds, isEmpty);
          expect(model.takeDeleteFailure(first.id), isNull);
          expect(await model.deleteExpense(second.id), isFalse);
          expect(controlled.deleteIds, <int>[first.id]);
        },
      );
    }
  });

  test(
    'dispose cancels events and ignores pending reads and later calls',
    () async {
      controlled.delayReads = true;
      var notifications = 0;
      model.addListener(() => notifications++);
      final pending = model.load();
      final before = notifications;
      model.dispose();
      controlled.pendingReads.single.completeError(const StorageFailure(null));
      await pending;
      await fake.create(_draft());
      await _flushEvents();
      await model.load();
      await model.onResume();

      expect(notifications, before);
      expect(controlled.pendingReads.length, 1);
      expect(model.state, isA<TransactionsLoading>());
    },
  );
}

ExpenseDraft _draft({int amount = 1000, ExpenseDate? date}) => ExpenseDraft(
  amount: amount,
  category: ExpenseCategory.food,
  transactionDate: date ?? ExpenseDate(2026, 10, 2),
  note: null,
);

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

/// Controls scheduling and fault injection while retaining shared fake behavior.
final class _ControlledTransactionsRepository implements ExpenseRepository {
  _ControlledTransactionsRepository(this.delegate);

  final FakeExpenseRepository delegate;
  final List<Completer<List<Expense>>> pendingReads =
      <Completer<List<Expense>>>[];
  final Map<int, Completer<void>> pendingDeletes = <int, Completer<void>>{};
  final List<int> deleteIds = <int>[];
  bool delayReads = false;
  bool delayDeletes = false;
  int readCount = 0;
  Object? readError;

  @override
  Stream<ExpenseChange> get changes => delegate.changes;

  @override
  Future<List<Expense>> getAll() async {
    readCount++;
    final error = readError;
    if (error != null) throw error;
    if (!delayReads) return delegate.getAll();
    final completer = Completer<List<Expense>>();
    pendingReads.add(completer);
    return completer.future;
  }

  @override
  Future<void> delete(int id) async {
    deleteIds.add(id);
    if (delayDeletes) {
      final completer = Completer<void>();
      pendingDeletes[id] = completer;
      await completer.future;
    }
    await delegate.delete(id);
  }

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) => delegate.getHomeSummary(month: month, latestLimit: latestLimit);

  @override
  Future<Expense> create(ExpenseDraft draft) => delegate.create(draft);

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) =>
      delegate.update(id: id, draft: draft);
}
