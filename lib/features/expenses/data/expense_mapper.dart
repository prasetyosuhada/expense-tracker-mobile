import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_validator.dart';

/// Converts between canonical SQLite values and immutable expense models.
final class ExpenseMapper {
  /// Creates a stateless mapper.
  const ExpenseMapper();

  static const List<String> _requiredColumns = <String>[
    'id',
    'amount',
    'category',
    'transaction_date',
    'note',
    'created_at',
    'updated_at',
  ];

  /// Reads one complete row, rejecting any value outside the domain contract.
  Expense rowToDomain(Map<String, Object?> row) {
    for (final column in _requiredColumns) {
      if (!row.containsKey(column) ||
          (column != 'note' && row[column] == null)) {
        throw CorruptDataFailure('Missing required column: $column');
      }
    }

    final id = _requiredInt(row, 'id');
    final amount = _requiredInt(row, 'amount');
    final createdAtMillis = _requiredInt(row, 'created_at');
    final updatedAtMillis = _requiredInt(row, 'updated_at');

    if (id <= 0) {
      throw const CorruptDataFailure('id must be positive');
    }
    if (amount < 1 || amount > ExpenseValidator.maxAmount) {
      throw const CorruptDataFailure('amount is outside the allowed range');
    }

    final categoryCode = _requiredString(row, 'category');
    ExpenseCategory? category;
    for (final candidate in ExpenseCategory.values) {
      if (candidate.persistenceCode == categoryCode) {
        category = candidate;
        break;
      }
    }
    if (category == null) {
      throw const CorruptDataFailure('Unknown category code');
    }

    final dateCode = _requiredString(row, 'transaction_date');
    final ExpenseDate transactionDate;
    try {
      transactionDate = ExpenseDate.fromIsoString(dateCode);
    } on FormatException {
      throw const CorruptDataFailure('Invalid transaction_date');
    }

    final noteValue = row['note'];
    if (noteValue != null && noteValue is! String) {
      throw const CorruptDataFailure('note must be text or null');
    }
    final String? normalizedNote;
    try {
      normalizedNote = const ExpenseValidator().normalizeNote(
        noteValue as String?,
      );
    } on ValidationFailure {
      throw const CorruptDataFailure('note exceeds the grapheme limit');
    }
    if (normalizedNote != noteValue) {
      throw const CorruptDataFailure('note is not normalized');
    }

    final DateTime createdAt;
    final DateTime updatedAt;
    try {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        createdAtMillis,
        isUtc: true,
      );
      updatedAt = DateTime.fromMillisecondsSinceEpoch(
        updatedAtMillis,
        isUtc: true,
      );
    } on RangeError {
      throw const CorruptDataFailure('Invalid audit timestamp');
    }

    return Expense(
      id: id,
      amount: amount,
      category: category,
      transactionDate: transactionDate,
      note: normalizedNote,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Produces an INSERT payload without the database-generated ID.
  Map<String, Object?> domainToInsertMap(
    ExpenseDraft draft,
    DateTime createdAt,
  ) {
    return <String, Object?>{
      ..._draftColumns(draft),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Produces an UPDATE payload without changing ID or creation time.
  Map<String, Object?> domainToUpdateMap(
    ExpenseDraft draft,
    DateTime updatedAt,
  ) {
    return <String, Object?>{
      ..._draftColumns(draft),
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Map<String, Object?> _draftColumns(ExpenseDraft draft) {
    return <String, Object?>{
      'amount': draft.amount,
      'category': draft.category.persistenceCode,
      'transaction_date': draft.transactionDate.toIsoString(),
      'note': draft.note,
    };
  }

  static int _requiredInt(Map<String, Object?> row, String column) {
    final value = row[column];
    if (value is! int) {
      throw CorruptDataFailure('$column must be an integer');
    }
    return value;
  }

  static String _requiredString(Map<String, Object?> row, String column) {
    final value = row[column];
    if (value is! String) {
      throw CorruptDataFailure('$column must be text');
    }
    return value;
  }
}
