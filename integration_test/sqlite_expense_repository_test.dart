import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/data/expense_database.dart';
import 'package:expensetracker/features/expenses/data/sqlite_expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  var nextDatabaseId = 0;
  late String testPath;
  late ExpenseDatabase service;
  late SqliteExpenseRepository repository;
  late _RepositoryTestClock clock;
  late List<ExpenseChange> events;
  late StreamSubscription<ExpenseChange> subscription;

  setUp(() async {
    final databasesPath = await getDatabasesPath();
    testPath = p.join(
      databasesPath,
      'p1_008_${DateTime.now().microsecondsSinceEpoch}_${nextDatabaseId++}.db',
    );
    expect(await databaseExists(testPath), isFalse);
    service = ExpenseDatabase(databasePath: testPath);
    clock = _RepositoryTestClock(DateTime(2026, 9, 8, 8, 30, 0, 123, 456));
    repository = SqliteExpenseRepository(database: service, clock: clock);
    events = <ExpenseChange>[];
    subscription = repository.changes.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await repository.dispose();
    await service.close();
    if (await databaseExists(testPath)) {
      await deleteDatabase(testPath);
    }
  });

  testWidgets('opens lazily and returns immutable empty snapshots', (
    tester,
  ) async {
    expect(await databaseExists(testPath), isFalse);
    final expenses = await repository.getAll();
    final month = ExpenseMonth(2026, 9);
    final summary = await repository.getHomeSummary(month: month);
    expect(expenses, isEmpty);
    expect(expenses.clear, throwsUnsupportedError);
    expect(summary.month, month);
    expect(summary.monthlyTotal, 0);
    expect(summary.latestExpenses, isEmpty);
    expect(summary.latestExpenses.clear, throwsUnsupportedError);
    expect(clock.calls, 0);
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('create normalizes and round-trips using one clock read', (
    tester,
  ) async {
    final expense = await repository.create(
      _draft(note: "  O'Brien; --\nmakan siang  "),
    );
    final expectedTime = DateTime.fromMillisecondsSinceEpoch(
      clock.value.millisecondsSinceEpoch,
      isUtc: true,
    );
    expect(expense.id, greaterThan(0));
    expect(expense.createdAt, expectedTime);
    expect(expense.updatedAt, expectedTime);
    expect(expense.createdAt.isUtc, isTrue);
    expect(expense.updatedAt.isUtc, isTrue);
    expect(expense.transactionDate, ExpenseDate(2026, 9, 8));
    expect(expense.note, "O'Brien; --\nmakan siang");
    expect(clock.calls, 1);
    final expenses = await repository.getAll();
    expect(expenses, <Expense>[expense]);
    expect(() => expenses.add(expense), throwsUnsupportedError);
    final database = await service.open();
    final row = (await database.query('expenses')).single;
    expect(row['amount'], 25_000);
    expect(row['category'], 'food');
    expect(row['transaction_date'], '2026-09-08');
    expect(row['created_at'], expectedTime.millisecondsSinceEpoch);
  });

  testWidgets('saved expenses survive closing and reopening the database', (
    tester,
  ) async {
    final original = await repository.create(_draft());
    await service.close();
    expect(await repository.getAll(), <Expense>[original]);
  });

  testWidgets(
    'update changes editable fields and preserves creation identity',
    (tester) async {
      final original = await repository.create(_draft());
      final untouched = await repository.create(_draft(amount: 1));
      clock.value = DateTime.utc(2026, 9, 9);
      final updated = await repository.update(
        id: original.id,
        draft: _draft(
          amount: 999_999_999_999,
          category: ExpenseCategory.bills,
          date: ExpenseDate(2026, 10, 1),
          note: '  ',
        ),
      );
      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, clock.value);
      expect(updated.amount, 999_999_999_999);
      expect(updated.category, ExpenseCategory.bills);
      expect(updated.transactionDate, ExpenseDate(2026, 10, 1));
      expect(updated.note, isNull);
      expect(clock.calls, 3);
      expect(await repository.getAll(), <Expense>[updated, untouched]);
    },
  );

  testWidgets(
    'delete removes only the requested expense without reading clock',
    (tester) async {
      final first = await repository.create(_draft());
      final second = await repository.create(_draft());
      await repository.delete(first.id);
      expect(await repository.getAll(), <Expense>[second]);
      expect(clock.calls, 2);
    },
  );

  testWidgets(
    'missing update and delete return NotFoundFailure without events',
    (tester) async {
      final failure = throwsA(
        isA<NotFoundFailure>().having((value) => value.id, 'id', 99),
      );
      await expectLater(repository.update(id: 99, draft: _draft()), failure);
      await expectLater(repository.delete(99), failure);
      expect(await repository.getAll(), isEmpty);
      await tester.pump();
      expect(events, isEmpty);
    },
  );

  testWidgets('invalid drafts are rejected before opening storage or clock', (
    tester,
  ) async {
    for (final draft in <ExpenseDraft>[
      _draft(amount: 0),
      _draft(amount: -1),
      _draft(amount: 1_000_000_000_000),
      _draft(note: List<String>.filled(101, '👨‍👩‍👧‍👦').join()),
    ]) {
      await expectLater(
        repository.create(draft),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        repository.update(id: 1, draft: draft),
        throwsA(isA<ValidationFailure>()),
      );
    }
    expect(await databaseExists(testPath), isFalse);
    expect(clock.calls, 0);
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('nonpositive ids and limits are typed caller errors', (
    tester,
  ) async {
    final failure = throwsA(
      isA<UnexpectedFailure>().having(
        (value) => value.cause,
        'cause',
        isA<ArgumentError>(),
      ),
    );
    for (final value in <int>[0, -1]) {
      await expectLater(repository.delete(value), failure);
      await expectLater(repository.update(id: value, draft: _draft()), failure);
      await expectLater(
        repository.getHomeSummary(
          month: ExpenseMonth(2026, 9),
          latestLimit: value,
        ),
        failure,
      );
    }
    expect(await databaseExists(testPath), isFalse);
    expect(clock.calls, 0);
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('canonical order handles timestamp ties and a backwards clock', (
    tester,
  ) async {
    clock.value = DateTime.utc(2026, 9, 8, 10);
    final first = await repository.create(_draft());
    clock.value = DateTime.utc(2026, 9, 8, 11);
    final second = await repository.create(_draft());
    final tied = await repository.create(_draft());
    clock.value = DateTime.utc(2026, 9, 8, 9);
    final backwards = await repository.create(_draft());
    final newerDate = await repository.create(
      _draft(date: ExpenseDate(2026, 9, 9)),
    );
    clock.value = DateTime.utc(2026, 9, 8, 12);
    final olderDate = await repository.create(
      _draft(date: ExpenseDate(2026, 9, 7)),
    );
    final expectedIds = <int>[
      newerDate.id,
      tied.id,
      second.id,
      first.id,
      backwards.id,
      olderDate.id,
    ];
    expect((await repository.getAll()).map((item) => item.id), expectedIds);
    clock.value = DateTime.utc(2026, 9, 10);
    await repository.update(id: first.id, draft: _draft(amount: 2));
    expect((await repository.getAll()).map((item) => item.id), expectedIds);
  });

  testWidgets('Home uses half-open month boundaries and latest five globally', (
    tester,
  ) async {
    final dates = <ExpenseDate>[
      ExpenseDate(2025, 9, 8),
      ExpenseDate(2026, 8, 31),
      ExpenseDate(2026, 9, 1),
      ExpenseDate(2026, 9, 8),
      ExpenseDate(2026, 9, 30),
      ExpenseDate(2026, 10, 1),
      ExpenseDate(2027, 9, 8),
    ];
    final inserted = <Expense>[];
    for (final date in dates) {
      inserted.add(
        await repository.create(_draft(amount: 999_999_999_999, date: date)),
      );
    }
    final summary = await repository.getHomeSummary(
      month: ExpenseMonth(2026, 9),
    );
    expect(summary.monthlyTotal, 2_999_999_999_997);
    expect(summary.latestExpenses, inserted.reversed.take(5).toList());
    expect(summary.latestExpenses.clear, throwsUnsupportedError);
    final limited = await repository.getHomeSummary(
      month: ExpenseMonth(2026, 9),
      latestLimit: 2,
    );
    expect(limited.latestExpenses, inserted.reversed.take(2).toList());
    expect(limited.monthlyTotal, summary.monthlyTotal);
    final emptyMonth = await repository.getHomeSummary(
      month: ExpenseMonth(2026, 12),
    );
    expect(emptyMonth.monthlyTotal, 0);
    expect(emptyMonth.latestExpenses, summary.latestExpenses);
  });

  testWidgets('monthly total handles the December to January boundary', (
    tester,
  ) async {
    for (final date in <ExpenseDate>[
      ExpenseDate(2026, 11, 30),
      ExpenseDate(2026, 12, 1),
      ExpenseDate(2026, 12, 31),
      ExpenseDate(2027, 1, 1),
    ]) {
      await repository.create(_draft(amount: 10, date: date));
    }
    final summary = await repository.getHomeSummary(
      month: ExpenseMonth(2026, 12),
    );
    expect(summary.monthlyTotal, 20);
  });

  testWidgets(
    'broadcast events follow successful writes and expose saved state',
    (tester) async {
      final secondEvents = <ExpenseChange>[];
      final second = repository.changes.listen(secondEvents.add);
      addTearDown(second.cancel);
      expect(repository.changes.isBroadcast, isTrue);

      final database = await service.open();
      final entered = Completer<void>();
      final release = Completer<void>();
      final blocker = database.transaction((transaction) async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final createdEvent = repository.changes.first;
      final pendingCreate = repository.create(_draft());
      try {
        await tester.pump();
        expect(events, isEmpty);
      } finally {
        release.complete();
      }
      await blocker;
      expect(await createdEvent, ExpenseChange.created);
      final created = await pendingCreate;
      expect(await repository.getAll(), <Expense>[created]);

      final updatedEvent = repository.changes.first;
      final updated = await repository.update(
        id: created.id,
        draft: _draft(amount: 1),
      );
      expect(await updatedEvent, ExpenseChange.updated);
      expect(await repository.getAll(), <Expense>[updated]);

      final deletedEvent = repository.changes.first;
      await repository.delete(created.id);
      expect(await deletedEvent, ExpenseChange.deleted);
      expect(await repository.getAll(), isEmpty);
      await tester.pump();
      expect(events, <ExpenseChange>[
        ExpenseChange.created,
        ExpenseChange.updated,
        ExpenseChange.deleted,
      ]);
      expect(secondEvents, events);
    },
  );

  testWidgets('Home keeps one snapshot when a write is queued concurrently', (
    tester,
  ) async {
    final original = await repository.create(_draft(amount: 10));
    final database = await service.open();
    final entered = Completer<void>();
    final release = Completer<void>();
    final blocker = database.transaction((transaction) async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final pendingSummary = repository.getHomeSummary(
      month: ExpenseMonth(2026, 9),
    );
    final pendingWrite = repository.create(_draft(amount: 20));
    try {
      await tester.pump();
    } finally {
      release.complete();
    }
    await blocker;
    final summary = await pendingSummary;
    final inserted = await pendingWrite;
    expect(summary.latestExpenses, <Expense>[original]);
    expect(summary.monthlyTotal, 10);
    final after = await repository.getHomeSummary(month: ExpenseMonth(2026, 9));
    expect(after.latestExpenses, <Expense>[inserted, original]);
    expect(after.monthlyTotal, 30);
  });

  testWidgets('failed SQLite writes preserve data and emit no change', (
    tester,
  ) async {
    final original = await repository.create(_draft());
    await tester.pump();
    events.clear();
    final database = await service.open();
    for (final operation in <String>['INSERT', 'UPDATE', 'DELETE']) {
      // Only fixture-controlled SQL identifiers are interpolated here.
      await database.execute('''
CREATE TRIGGER reject_${operation.toLowerCase()} BEFORE $operation ON expenses
BEGIN SELECT RAISE(ABORT, 'fixture write failure'); END
''');
    }
    final failure = throwsA(
      isA<StorageFailure>().having(
        (value) => value.cause,
        'cause',
        isA<DatabaseException>(),
      ),
    );
    await expectLater(repository.create(_draft()), failure);
    await expectLater(
      repository.update(id: original.id, draft: _draft(amount: 1)),
      failure,
    );
    await expectLater(repository.delete(original.id), failure);
    expect(await repository.getAll(), <Expense>[original]);
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('read failures stay typed and never reset the database', (
    tester,
  ) async {
    await repository.create(_draft());
    final database = await service.open();
    await database.execute('ALTER TABLE expenses RENAME TO fixture_expenses');
    await expectLater(repository.getAll(), throwsA(isA<StorageFailure>()));
    await expectLater(
      repository.getHomeSummary(month: ExpenseMonth(2026, 9)),
      throwsA(isA<StorageFailure>()),
    );
    expect(await database.query('fixture_expenses'), hasLength(1));
  });

  testWidgets('corrupt rows fail reads without being skipped or removed', (
    tester,
  ) async {
    final original = await repository.create(_draft());
    final database = await service.open();
    await database.update(
      'expenses',
      <String, Object?>{'transaction_date': '2026-02-29'},
      where: 'id = ?',
      whereArgs: <Object?>[original.id],
    );
    await expectLater(repository.getAll(), throwsA(isA<CorruptDataFailure>()));
    await expectLater(
      repository.getHomeSummary(month: ExpenseMonth(2026, 2)),
      throwsA(isA<CorruptDataFailure>()),
    );
    expect(await database.query('expenses'), hasLength(1));
  });

  testWidgets('read-back mapping failures roll back writes without events', (
    tester,
  ) async {
    final original = await repository.create(_draft());
    await tester.pump();
    events.clear();
    final database = await service.open();
    await database.execute('''
CREATE TRIGGER corrupt_insert AFTER INSERT ON expenses
BEGIN UPDATE expenses SET transaction_date = '2026-02-29' WHERE id = NEW.id; END
''');
    await expectLater(
      repository.create(_draft()),
      throwsA(isA<CorruptDataFailure>()),
    );
    expect(await repository.getAll(), <Expense>[original]);

    await database.update(
      'expenses',
      <String, Object?>{'created_at': 'broken'},
      where: 'id = ?',
      whereArgs: <Object?>[original.id],
    );
    await expectLater(
      repository.update(id: original.id, draft: _draft(amount: 1)),
      throwsA(isA<CorruptDataFailure>()),
    );
    expect(
      (await database.query('expenses')).single['amount'],
      original.amount,
    );
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('unexpected clock failures are wrapped before any write', (
    tester,
  ) async {
    clock.failure = StateError('fixture clock failure');
    await expectLater(
      repository.create(_draft()),
      throwsA(
        isA<UnexpectedFailure>().having(
          (value) => value.cause,
          'cause',
          same(clock.failure),
        ),
      ),
    );
    expect(await databaseExists(testPath), isFalse);
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('dispose drains a pending write before closing its stream', (
    tester,
  ) async {
    final database = await service.open();
    final entered = Completer<void>();
    final release = Completer<void>();
    final done = Completer<void>();
    final listener = repository.changes.listen(
      (event) {},
      onDone: done.complete,
    );
    addTearDown(listener.cancel);
    final blocker = database.transaction((transaction) async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final pendingWrite = repository.create(_draft());
    final disposal = repository.dispose();
    try {
      await expectLater(repository.getAll(), throwsA(isA<UnexpectedFailure>()));
      expect(done.isCompleted, isFalse);
    } finally {
      release.complete();
    }
    await blocker;
    final expense = await pendingWrite;
    await disposal;
    await done.future;
    await repository.dispose();
    expect(events, <ExpenseChange>[ExpenseChange.created]);
    expect((await database.query('expenses')).single['id'], expense.id);
  });
}

ExpenseDraft _draft({
  int amount = 25_000,
  ExpenseCategory category = ExpenseCategory.food,
  ExpenseDate? date,
  String? note,
}) => ExpenseDraft(
  amount: amount,
  category: category,
  transactionDate: date ?? ExpenseDate(2026, 9, 8),
  note: note,
);

// Local fixture for repository integration tests; shared fakes are P1-009.
final class _RepositoryTestClock implements AppClock {
  _RepositoryTestClock(this.value);

  DateTime value;
  int calls = 0;
  Object? failure;

  @override
  DateTime now() {
    calls++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return value;
  }
}
