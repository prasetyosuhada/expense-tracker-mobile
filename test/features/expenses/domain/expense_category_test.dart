import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/features/expenses/domain/expense_category.dart';

void main() {
  test('exposes the five canonical category codes in selection order', () {
    expect(ExpenseCategory.values.map((category) => category.persistenceCode), [
      'food',
      'transportation',
      'shopping',
      'bills',
      'other',
    ]);
  });
}
