import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';

import 'fake_app_clock.dart';
import 'fake_expense_repository.dart';

void main() {
  late FakeAppClock clock;
  late FakeExpenseRepository fake;

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 9, 8, 8, 30, 0, 123, 456));
    fake = FakeExpenseRepository(clock: clock);
  });

  tearDown(() async {
    await fake.dispose();
  });

  test(
    'implements every repository method with empty immutable results',
    () async {
      final ExpenseRepository repository = fake;
      final all = await repository.getAll();
      final summary = await repository.getHomeSummary(
        month: ExpenseMonth(2026, 9),
      );
      expect(repository.changes.isBroadcast, isTrue);
      expect(all, isEmpty);
      expect(all.clear, throwsUnsupportedError);
      expect(summary.monthlyTotal, 0);
      expect(summary.latestExpenses, isEmpty);
      expect(summary.latestExpenses.clear, throwsUnsupportedError);
    },
  );

  test('create uses normalized draft and millisecond UTC timestamps', () async {
    final created = await fake.create(_draft(note: '  Makan siang  '));
    final expectedAt = DateTime.fromMillisecondsSinceEpoch(
      clock.currentTime.millisecondsSinceEpoch,
      isUtc: true,
    );
    expect(created.id, 1);
    expect(created.amount, 25_000);
    expect(created.note, 'Makan siang');
    expect(created.createdAt, expectedAt);
    expect(created.updatedAt, expectedAt);
    expect(created.createdAt.isUtc, isTrue);
    expect(await fake.getAll(), <Expense>[created]);
  });

  test(
    'seed data is copied and new IDs stay above the highest seed ID',
    () async {
      final seed = <Expense>[_expense(id: 3), _expense(id: 9)];
      await fake.dispose();
      fake = FakeExpenseRepository(clock: clock, initialExpenses: seed);
      seed.clear();

      final created = await fake.create(_draft());
      expect(created.id, 10);
      expect((await fake.getAll()).map((item) => item.id), <int>[10, 9, 3]);
      await fake.delete(10);
      expect((await fake.create(_draft())).id, 11);
    },
  );

  test('rejects duplicate or nonpositive seed identifiers', () {
    expect(
      () => FakeExpenseRepository(
        clock: clock,
        initialExpenses: <Expense>[_expense(id: 1), _expense(id: 1)],
      ),
      throwsArgumentError,
    );
    expect(
      () => FakeExpenseRepository(
        clock: clock,
        initialExpenses: <Expense>[_expense(id: 0)],
      ),
      throwsArgumentError,
    );
  });

  test(
    'orders by date, creation instant, then ID even if clock moves back',
    () async {
      final seed = <Expense>[
        _expense(id: 1, createdAt: DateTime.utc(2026, 9, 8, 10)),
        _expense(id: 2, createdAt: DateTime.utc(2026, 9, 8, 11)),
        _expense(id: 3, createdAt: DateTime.utc(2026, 9, 8, 11)),
        _expense(id: 4, createdAt: DateTime.utc(2026, 9, 8, 9)),
        _expense(
          id: 5,
          date: ExpenseDate(2026, 9, 9),
          createdAt: DateTime.utc(2026, 9, 8, 9),
        ),
        _expense(
          id: 6,
          date: ExpenseDate(2026, 9, 7),
          createdAt: DateTime.utc(2026, 9, 8, 12),
        ),
      ];
      await fake.dispose();
      fake = FakeExpenseRepository(clock: clock, initialExpenses: seed);

      final expected = <int>[5, 3, 2, 1, 4, 6];
      expect((await fake.getAll()).map((item) => item.id), expected);
      clock.currentTime = DateTime.utc(2026, 9, 10);
      await fake.update(id: 1, draft: _draft(amount: 100));
      expect((await fake.getAll()).map((item) => item.id), expected);
    },
  );

  test(
    'Home total uses month boundaries while latest list stays global',
    () async {
      for (final date in <ExpenseDate>[
        ExpenseDate(2025, 9, 8),
        ExpenseDate(2026, 8, 31),
        ExpenseDate(2026, 9, 1),
        ExpenseDate(2026, 9, 8),
        ExpenseDate(2026, 9, 30),
        ExpenseDate(2026, 10, 1),
        ExpenseDate(2027, 9, 8),
      ]) {
        await fake.create(_draft(amount: 999_999_999_999, date: date));
      }
      final all = await fake.getAll();
      final summary = await fake.getHomeSummary(month: ExpenseMonth(2026, 9));
      expect(summary.monthlyTotal, 2_999_999_999_997);
      expect(summary.latestExpenses, all.take(5).toList());
      expect(summary.latestExpenses.clear, throwsUnsupportedError);
      final limited = await fake.getHomeSummary(
        month: ExpenseMonth(2026, 9),
        latestLimit: 2,
      );
      expect(limited.latestExpenses, all.take(2).toList());
      final emptyMonth = await fake.getHomeSummary(
        month: ExpenseMonth(2026, 12),
      );
      expect(emptyMonth.monthlyTotal, 0);
      expect(emptyMonth.latestExpenses, summary.latestExpenses);
    },
  );

  test(
    'update preserves ID and creation time and changes only one item',
    () async {
      final first = await fake.create(_draft());
      final other = await fake.create(_draft(amount: 1));
      clock.currentTime = DateTime.utc(2026, 9, 9);
      final changed = await fake.update(
        id: first.id,
        draft: _draft(
          amount: 200,
          category: ExpenseCategory.bills,
          date: ExpenseDate(2026, 10, 1),
          note: ' ',
        ),
      );
      expect(changed.id, first.id);
      expect(changed.createdAt, first.createdAt);
      expect(changed.updatedAt, clock.currentTime);
      expect(changed.amount, 200);
      expect(changed.category, ExpenseCategory.bills);
      expect(changed.transactionDate, ExpenseDate(2026, 10, 1));
      expect(changed.note, isNull);
      expect(await fake.getAll(), <Expense>[changed, other]);
    },
  );

  test('delete removes only the selected item', () async {
    final first = await fake.create(_draft());
    final second = await fake.create(_draft());
    await fake.delete(first.id);
    expect(await fake.getAll(), <Expense>[second]);
  });

  test('broadcast changes reflect completed mutations and no reads', () async {
    final firstEvents = <ExpenseChange>[];
    final secondEvents = <ExpenseChange>[];
    final first = fake.changes.listen(firstEvents.add);
    final second = fake.changes.listen(secondEvents.add);
    try {
      final created = await fake.create(_draft());
      await fake.getAll();
      await fake.getHomeSummary(month: ExpenseMonth(2026, 9));
      await fake.update(id: created.id, draft: _draft(amount: 1));
      await fake.delete(created.id);
      await Future<void>.delayed(Duration.zero);
      expect(firstEvents, <ExpenseChange>[
        ExpenseChange.created,
        ExpenseChange.updated,
        ExpenseChange.deleted,
      ]);
      expect(secondEvents, firstEvents);
      expect(await fake.getAll(), isEmpty);
    } finally {
      await first.cancel();
      await second.cancel();
    }
  });

  test(
    'each method can inject a typed failure without changing data',
    () async {
      final original = await fake.create(_draft());
      const failure = StorageFailure('fixture failure');
      final received = <ExpenseChange>[];
      final subscription = fake.changes.listen(received.add);
      try {
        fake.getAllFailure = failure;
        await expectLater(fake.getAll(), throwsA(same(failure)));
        fake.getAllFailure = null;

        fake.getHomeSummaryFailure = failure;
        await expectLater(
          fake.getHomeSummary(month: ExpenseMonth(2026, 9)),
          throwsA(same(failure)),
        );
        fake.getHomeSummaryFailure = null;

        fake.createFailure = failure;
        await expectLater(fake.create(_draft()), throwsA(same(failure)));
        fake.createFailure = null;

        fake.updateFailure = failure;
        await expectLater(
          fake.update(id: original.id, draft: _draft(amount: 1)),
          throwsA(same(failure)),
        );
        fake.updateFailure = null;

        fake.deleteFailure = failure;
        await expectLater(fake.delete(original.id), throwsA(same(failure)));
        fake.deleteFailure = null;

        expect(await fake.getAll(), <Expense>[original]);
        expect((await fake.create(_draft())).id, original.id + 1);
        await Future<void>.delayed(Duration.zero);
        expect(received, <ExpenseChange>[ExpenseChange.created]);
      } finally {
        await subscription.cancel();
      }
    },
  );

  test('invalid drafts and IDs match production failure behavior', () async {
    final original = await fake.create(_draft());
    final received = <ExpenseChange>[];
    final subscription = fake.changes.listen(received.add);
    try {
      await expectLater(
        fake.create(_draft(amount: 0)),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        fake.update(id: original.id, draft: _draft(amount: 1_000_000_000_000)),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        fake.getHomeSummary(month: ExpenseMonth(2026, 9), latestLimit: 0),
        throwsA(isA<UnexpectedFailure>()),
      );
      await expectLater(
        fake.update(id: 0, draft: _draft()),
        throwsA(isA<UnexpectedFailure>()),
      );
      await expectLater(fake.delete(0), throwsA(isA<UnexpectedFailure>()));
      await expectLater(
        fake.update(id: 99, draft: _draft()),
        throwsA(isA<NotFoundFailure>().having((value) => value.id, 'id', 99)),
      );
      await expectLater(
        fake.delete(99),
        throwsA(isA<NotFoundFailure>().having((value) => value.id, 'id', 99)),
      );
      expect(await fake.getAll(), <Expense>[original]);
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);
    } finally {
      await subscription.cancel();
    }
  });

  test('dispose rejects further operations', () async {
    await fake.dispose();
    await expectLater(fake.getAll(), throwsA(isA<UnexpectedFailure>()));
    await expectLater(fake.create(_draft()), throwsA(isA<UnexpectedFailure>()));
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

Expense _expense({required int id, ExpenseDate? date, DateTime? createdAt}) =>
    Expense(
      id: id,
      amount: 25_000,
      category: ExpenseCategory.food,
      transactionDate: date ?? ExpenseDate(2026, 9, 8),
      note: null,
      createdAt: createdAt ?? DateTime.utc(2026, 9, 8),
      updatedAt: createdAt ?? DateTime.utc(2026, 9, 8),
    );
