import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';

Expense expense({
  int id = 1,
  int amount = 25000,
  ExpenseCategory category = ExpenseCategory.food,
  ExpenseDate? transactionDate,
  String? note = 'Makan siang',
  DateTime? createdAt,
  DateTime? updatedAt,
}) => Expense(
  id: id,
  amount: amount,
  category: category,
  transactionDate: transactionDate ?? ExpenseDate(2026, 9, 8),
  note: note,
  createdAt: createdAt ?? DateTime.utc(2026, 9, 8, 1),
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 8, 2),
);

void main() {
  group('Expense', () {
    test('equal values compare equal and have matching hashes', () {
      final original = expense();
      final identicalValues = expense();
      expect(original, identicalValues);
      expect(original.hashCode, identicalValues.hashCode);
      expect(<Expense>{original, identicalValues}, hasLength(1));
    });

    test('each field participates in equality', () {
      final original = expense();
      final differentValues = <Expense>[
        expense(id: 2),
        expense(amount: 1),
        expense(category: ExpenseCategory.other),
        expense(transactionDate: ExpenseDate(2026, 9, 9)),
        expense(note: null),
        expense(createdAt: DateTime.utc(2026, 9, 7, 1)),
        expense(updatedAt: DateTime.utc(2026, 9, 9, 2)),
      ];
      for (final different in differentValues) {
        expect(original == different, isFalse);
      }
      expect(original == Object(), isFalse);
    });

    test('keeps the transaction date independent of UTC audit times', () {
      final transactionDate = ExpenseDate(2026, 9, 8);
      final value = expense(transactionDate: transactionDate, note: null);
      expect(value.transactionDate, transactionDate);
      expect(value.createdAt.isUtc, isTrue);
      expect(value.updatedAt.isUtc, isTrue);
      expect(value.note, isNull);
    });
  });
}
