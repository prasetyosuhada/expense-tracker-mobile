import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:expensetracker/core/formatting/id_date_formatter.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';

void main() {
  group('IdDateFormatter', () {
    test('formats form date with an Indonesian full month name', () {
      final formatter = IdDateFormatter();
      expect(formatter.formatForm(ExpenseDate(2026, 9, 7)), '7 September 2026');
    });

    test('formats list item with an Indonesian abbreviated month', () {
      final formatter = IdDateFormatter();
      expect(formatter.formatListItem(ExpenseDate(2026, 9, 7)), '7 Sep 2026');
    });

    test('formats month header with the full Indonesian month name', () {
      final formatter = IdDateFormatter();
      expect(
        formatter.formatMonthHeader(ExpenseMonth(2026, 9)),
        'September 2026',
      );
    });

    test(
      'keeps civil dates unchanged across month and leap-day boundaries',
      () {
        final formatter = IdDateFormatter();
        expect(
          formatter.formatForm(ExpenseDate(2024, 2, 29)),
          '29 Februari 2024',
        );
        expect(
          formatter.formatListItem(ExpenseDate(2026, 12, 31)),
          '31 Des 2026',
        );
        expect(
          formatter.formatMonthHeader(ExpenseMonth(2027, 1)),
          'Januari 2027',
        );
      },
    );

    test('uses Indonesian month names despite a different ambient locale', () {
      final formatter = IdDateFormatter();
      final result = Intl.withLocale('en_US', () {
        return <String>[
          formatter.formatForm(ExpenseDate(2026, 9, 7)),
          formatter.formatListItem(ExpenseDate(2026, 9, 7)),
          formatter.formatMonthHeader(ExpenseMonth(2026, 9)),
        ];
      });
      expect(result, <String>[
        '7 September 2026',
        '7 Sep 2026',
        'September 2026',
      ]);
    });
  });
}
