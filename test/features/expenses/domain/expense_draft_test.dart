import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';

void main() {
  test('carries validated values without persistence metadata', () {
    final date = ExpenseDate(2026, 9, 8);
    final draft = ExpenseDraft(
      amount: 25000,
      category: ExpenseCategory.food,
      transactionDate: date,
      note: 'Makan siang',
    );
    expect(draft.amount, 25000);
    expect(draft.category, ExpenseCategory.food);
    expect(draft.transactionDate, date);
    expect(draft.note, 'Makan siang');
  });

  test('accepts a null optional note', () {
    final draft = ExpenseDraft(
      amount: 1,
      category: ExpenseCategory.other,
      transactionDate: ExpenseDate(2026, 9, 8),
      note: null,
    );
    expect(draft.note, isNull);
  });
}
