import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/data/expense_mapper.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';

void main() {
  const mapper = ExpenseMapper();
  final createdAt = DateTime.utc(2026, 9, 8, 1, 2, 3, 4);
  const note = 'O\'Brien; --\nsiang';
  final draft = ExpenseDraft(
    amount: 25_000,
    category: ExpenseCategory.food,
    transactionDate: ExpenseDate(2026, 9, 8),
    note: note,
  );

  Map<String, Object?> validRow() => <String, Object?>{
    'id': 7,
    ...mapper.domainToInsertMap(draft, createdAt),
  };

  group('ExpenseMapper', () {
    test('insert map round-trips to an immutable Expense', () {
      final insertMap = mapper.domainToInsertMap(draft, createdAt);
      expect(insertMap, <String, Object?>{
        'amount': 25_000,
        'category': 'food',
        'transaction_date': '2026-09-08',
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': createdAt.millisecondsSinceEpoch,
      });
      expect(
        mapper.rowToDomain(<String, Object?>{'id': 7, ...insertMap}),
        Expense(
          id: 7,
          amount: draft.amount,
          category: draft.category,
          transactionDate: draft.transactionDate,
          note: draft.note,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    });

    test('all five category codes round-trip without a UI label', () {
      for (final category in ExpenseCategory.values) {
        final categoryDraft = ExpenseDraft(
          amount: 1,
          category: category,
          transactionDate: ExpenseDate(2026, 9, 8),
          note: null,
        );
        final row = <String, Object?>{
          'id': 1,
          ...mapper.domainToInsertMap(categoryDraft, createdAt),
        };
        expect(row['category'], category.persistenceCode);
        expect(mapper.rowToDomain(row).category, category);
        expect(mapper.rowToDomain(row).note, isNull);
      }
    });

    test('update map excludes id and created_at and stores UTC epoch', () {
      final localTime = DateTime.fromMillisecondsSinceEpoch(
        createdAt.millisecondsSinceEpoch + 1000,
      );
      expect(mapper.domainToUpdateMap(draft, localTime), <String, Object?>{
        'amount': 25_000,
        'category': 'food',
        'transaction_date': '2026-09-08',
        'note': note,
        'updated_at': createdAt.millisecondsSinceEpoch + 1000,
      });
    });

    test('audit timestamps are read as UTC without changing calendar date', () {
      final expense = mapper.rowToDomain(validRow());
      expect(expense.createdAt, createdAt);
      expect(expense.updatedAt, createdAt);
      expect(expense.createdAt.isUtc, isTrue);
      expect(expense.updatedAt.isUtc, isTrue);
      expect(expense.transactionDate, ExpenseDate(2026, 9, 8));
    });

    test('missing and null required columns are corrupt', () {
      for (final column in <String>[
        'id',
        'amount',
        'category',
        'transaction_date',
        'note',
        'created_at',
        'updated_at',
      ]) {
        final missing = validRow()..remove(column);
        expect(
          () => mapper.rowToDomain(missing),
          throwsA(isA<CorruptDataFailure>()),
          reason: 'missing $column',
        );
        if (column != 'note') {
          final nullValue = validRow()..[column] = null;
          expect(
            () => mapper.rowToDomain(nullValue),
            throwsA(isA<CorruptDataFailure>()),
            reason: 'null $column',
          );
        }
      }
    });

    test('wrong SQLite types are corrupt', () {
      for (final column in <String>[
        'id',
        'amount',
        'created_at',
        'updated_at',
      ]) {
        final row = validRow()..[column] = '1';
        expect(
          () => mapper.rowToDomain(row),
          throwsA(isA<CorruptDataFailure>()),
          reason: column,
        );
      }
      for (final column in <String>['category', 'transaction_date', 'note']) {
        final row = validRow()..[column] = 123;
        expect(
          () => mapper.rowToDomain(row),
          throwsA(isA<CorruptDataFailure>()),
          reason: column,
        );
      }
    });

    test('nonpositive id and out-of-range amount are corrupt', () {
      for (final id in <int>[0, -1]) {
        expect(
          () => mapper.rowToDomain(validRow()..['id'] = id),
          throwsA(isA<CorruptDataFailure>()),
        );
      }
      for (final amount in <int>[0, -1, 1_000_000_000_000]) {
        expect(
          () => mapper.rowToDomain(validRow()..['amount'] = amount),
          throwsA(isA<CorruptDataFailure>()),
        );
      }
      expect(
        mapper.rowToDomain(validRow()..['amount'] = 999_999_999_999).amount,
        999_999_999_999,
      );
    });

    test('unknown category code never falls back to other', () {
      final row = validRow()..['category'] = 'makanan';
      expect(() => mapper.rowToDomain(row), throwsA(isA<CorruptDataFailure>()));
    });

    test('invalid or noncanonical transaction_date is corrupt', () {
      for (final date in <String>[
        '2026-02-29',
        '2026-13-01',
        '08-09-2026',
        '2026-9-08',
      ]) {
        final row = validRow()..['transaction_date'] = date;
        expect(
          () => mapper.rowToDomain(row),
          throwsA(isA<CorruptDataFailure>()),
          reason: date,
        );
      }
    });

    test('note must be normalized and within 100 graphemes', () {
      for (final invalidNote in <String>[
        '',
        '  ',
        ' makan',
        'makan ',
        List<String>.filled(101, '👨‍👩‍👧‍👦').join(),
      ]) {
        final row = validRow()..['note'] = invalidNote;
        expect(
          () => mapper.rowToDomain(row),
          throwsA(isA<CorruptDataFailure>()),
          reason: invalidNote,
        );
      }
      final validNote = List<String>.filled(100, '👨‍👩‍👧‍👦').join();
      expect(
        mapper.rowToDomain(validRow()..['note'] = validNote).note,
        validNote,
      );
    });

    test('unrepresentable audit timestamps are corrupt', () {
      final row = validRow()..['created_at'] = 9_223_372_036_854_775_807;
      expect(() => mapper.rowToDomain(row), throwsA(isA<CorruptDataFailure>()));
    });
  });
}
