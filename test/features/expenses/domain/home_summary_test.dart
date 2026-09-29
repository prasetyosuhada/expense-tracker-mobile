import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';

void main() {
  group('HomeSummary', () {
    final expense = Expense(
      id: 1,
      amount: 25000,
      category: ExpenseCategory.food,
      transactionDate: ExpenseDate(2026, 9, 8),
      note: null,
      createdAt: DateTime.utc(2026, 9, 8),
      updatedAt: DateTime.utc(2026, 9, 8),
    );

    test('retains the requested month, total, and latest expense', () {
      final month = ExpenseMonth(2026, 9);
      final summary = HomeSummary(
        month: month,
        monthlyTotal: 25000,
        latestExpenses: [expense],
      );

      expect(summary.month, month);
      expect(summary.monthlyTotal, 25000);
      expect(summary.latestExpenses, [expense]);
    });

    test('does not change when the input list changes afterward', () {
      final input = <Expense>[expense];
      final summary = HomeSummary(
        month: ExpenseMonth(2026, 9),
        monthlyTotal: 25000,
        latestExpenses: input,
      );

      input.clear();

      expect(summary.latestExpenses, [expense]);
    });

    test('does not allow consumers to modify latest expenses', () {
      final summary = HomeSummary(
        month: ExpenseMonth(2026, 9),
        monthlyTotal: 25000,
        latestExpenses: [expense],
      );

      expect(() => summary.latestExpenses.add(expense), throwsUnsupportedError);
      expect(() => summary.latestExpenses[0] = expense, throwsUnsupportedError);
      expect(summary.latestExpenses.clear, throwsUnsupportedError);
    });

    test('allows an empty snapshot with zero total', () {
      final summary = HomeSummary(
        month: ExpenseMonth(2026, 9),
        monthlyTotal: 0,
        latestExpenses: const <Expense>[],
      );

      expect(summary.monthlyTotal, 0);
      expect(summary.latestExpenses, isEmpty);
    });

    test('rejects a negative monthly total', () {
      expect(
        () => HomeSummary(
          month: ExpenseMonth(2026, 9),
          monthlyTotal: -1,
          latestExpenses: const <Expense>[],
        ),
        throwsRangeError,
      );
    });
  });
}
