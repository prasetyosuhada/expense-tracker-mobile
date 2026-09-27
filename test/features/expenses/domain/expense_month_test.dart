import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/features/expenses/domain/expense_month.dart';

void main() {
  group('ExpenseMonth', () {
    test('returns September 2026 boundaries', () {
      final month = ExpenseMonth(2026, 9);
      expect(month.startInclusive, '2026-09-01');
      expect(month.endExclusive, '2026-10-01');
    });

    test('rolls December into January of the next year', () {
      final month = ExpenseMonth(2026, 12);
      expect(month.startInclusive, '2026-12-01');
      expect(month.endExclusive, '2027-01-01');
    });

    test('uses month boundaries even during a leap year', () {
      final month = ExpenseMonth(2024, 2);
      expect(month.startInclusive, '2024-02-01');
      expect(month.endExclusive, '2024-03-01');
    });

    test('pads small years and supports the last representable boundary', () {
      expect(ExpenseMonth(1, 1).startInclusive, '0001-01-01');
      expect(ExpenseMonth(9999, 11).endExclusive, '9999-12-01');
    });

    for (final components in <List<int>>[
      [2026, 0],
      [2026, 13],
      [-1, 1],
      [10000, 1],
      [9999, 12],
    ]) {
      test('rejects invalid month or boundary $components', () {
        expect(
          () => ExpenseMonth(components[0], components[1]),
          throwsArgumentError,
        );
      });
    }

    test('compares year and month with value hashing', () {
      final month = ExpenseMonth(2026, 9);
      final sameMonth = ExpenseMonth(2026, 9);
      expect(month, sameMonth);
      expect(month.hashCode, sameMonth.hashCode);
      expect(<ExpenseMonth>{month, sameMonth}, hasLength(1));
      expect(month == ExpenseMonth(2025, 9), isFalse);
      expect(month == ExpenseMonth(2026, 8), isFalse);
      expect(month == Object(), isFalse);
    });
  });
}
