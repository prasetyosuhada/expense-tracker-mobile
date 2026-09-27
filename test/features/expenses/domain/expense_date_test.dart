import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/features/expenses/domain/expense_date.dart';

void main() {
  group('ExpenseDate', () {
    group('constructor', () {
      for (final components in <List<int>>[
        [2026, 2, 30],
        [2026, 13, 1],
        [2026, 0, 1],
        [2026, 1, 0],
        [2026, 1, -1],
        [2026, 4, 31],
        [-1, 1, 1],
        [10000, 1, 1],
      ]) {
        test('rejects invalid components $components', () {
          expect(
            () => ExpenseDate(components[0], components[1], components[2]),
            throwsArgumentError,
          );
        });
      }

      for (final year in <int>[2024, 2000]) {
        test('accepts leap day in $year', () {
          expect(ExpenseDate(year, 2, 29).day, 29);
        });
      }

      for (final year in <int>[2025, 2026, 1900, 2100]) {
        test('rejects leap day in $year', () {
          expect(() => ExpenseDate(year, 2, 29), throwsArgumentError);
        });
      }
    });

    group('ISO serialization', () {
      for (final iso in <String>[
        '0000-01-01',
        '0001-01-09',
        '1900-02-28',
        '2000-02-29',
        '2024-02-29',
        '2026-09-08',
        '9999-12-31',
      ]) {
        test('round-trips $iso', () {
          expect(ExpenseDate.fromIsoString(iso).toIsoString(), iso);
        });
      }

      for (final iso in <String>[
        '',
        '2026-2-01',
        '2026-02-1',
        '26-02-01',
        '10000-01-01',
        '08-09-2026',
        '2026/09/08',
        '2026-02-30',
        '2026-02-29',
        '2026-13-01',
        '2026-00-01',
        '2026-01-00',
        '2026-09-08T00:00:00',
        '2026-09-08Z',
        '2026-09-08+07:00',
        ' 2026-09-08',
        '2026-09-08 ',
        '2026-09-08\n',
        '２０２６-０９-０８',
      ]) {
        test('rejects malformed or invalid ISO ${iso.trim()}', () {
          expect(() => ExpenseDate.fromIsoString(iso), throwsFormatException);
        });
      }
    });

    group('fromDateTime', () {
      test('preserves local date near midnight without conversion to UTC', () {
        final localDate = DateTime(2026, 9, 8, 0, 15);

        expect(ExpenseDate.fromDateTime(localDate), ExpenseDate(2026, 9, 8));
      });

      test('preserves supplied UTC components without conversion to local', () {
        final utcDate = DateTime.utc(2026, 9, 8, 23, 45);

        expect(ExpenseDate.fromDateTime(utcDate), ExpenseDate(2026, 9, 8));
      });
    });

    group('equality', () {
      test('compares all date components and respects value hashing', () {
        final date = ExpenseDate(2026, 9, 8);
        final equalDate = ExpenseDate.fromIsoString('2026-09-08');

        expect(date, equalDate);
        expect(date.hashCode, equalDate.hashCode);
        expect(<ExpenseDate>{date, equalDate}, hasLength(1));
        expect(date == ExpenseDate(2025, 9, 8), isFalse);
        expect(date == ExpenseDate(2026, 8, 8), isFalse);
        expect(date == ExpenseDate(2026, 9, 7), isFalse);
        expect(date == Object(), isFalse);
      });
    });
  });
}
