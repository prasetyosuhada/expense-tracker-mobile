import 'dart:async';

import 'package:flutter/services.dart';

import 'package:sqflite/sqflite.dart';

import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/data/expense_database.dart';
import 'package:expensetracker/features/expenses/data/expense_mapper.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/expense_validator.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';

/// Persists expenses atomically and publishes changes after successful commits.
final class SqliteExpenseRepository implements ExpenseRepository {
  /// Borrows [database]; its owner remains responsible for closing it.
  SqliteExpenseRepository({
    required this._database,
    required this._clock,
    this._mapper = const ExpenseMapper(),
    this._validator = const ExpenseValidator(),
  });

  static const String _table = 'expenses';
  static const List<String> _columns = <String>[
    'id',
    'amount',
    'category',
    'transaction_date',
    'note',
    'created_at',
    'updated_at',
  ];
  static const String _order =
      'transaction_date DESC, created_at DESC, id DESC';

  final ExpenseDatabase _database;
  final AppClock _clock;
  final ExpenseMapper _mapper;
  final ExpenseValidator _validator;
  final StreamController<ExpenseChange> _changes =
      StreamController<ExpenseChange>.broadcast();
  bool _isDisposed = false;
  int _activeOperations = 0;
  Completer<void>? _idle;
  Future<void>? _disposeFuture;

  @override
  Stream<ExpenseChange> get changes => _changes.stream;

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) => _run(() async {
    _requirePositive(latestLimit, 'latestLimit');
    final database = await _database.open();
    return database.transaction((transaction) async {
      final latestRows = await transaction.query(
        _table,
        columns: _columns,
        orderBy: _order,
        limit: latestLimit,
      );
      final totals = await transaction.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
        'WHERE transaction_date >= ? AND transaction_date < ?',
        <Object?>[month.startInclusive, month.endExclusive],
      );
      if (totals.length != 1) {
        throw const CorruptDataFailure('Expected one monthly total');
      }
      final total = totals.single['total'];
      if (total is! int || total < 0) {
        throw const CorruptDataFailure('Invalid monthly total');
      }
      return HomeSummary(
        month: month,
        monthlyTotal: total,
        latestExpenses: _mapRows(latestRows),
      );
    }, exclusive: false);
  });

  @override
  Future<List<Expense>> getAll() => _run(() async {
    final database = await _database.open();
    final rows = await database.query(
      _table,
      columns: _columns,
      orderBy: _order,
    );
    return _mapRows(rows);
  });

  @override
  Future<Expense> create(ExpenseDraft draft) => _run(() async {
    final validated = _validator.validate(draft);
    final createdAt = _clock.now().toUtc();
    final values = _mapper.domainToInsertMap(validated, createdAt);
    final database = await _database.open();
    final expense = await database.transaction((transaction) async {
      final id = await transaction.insert(_table, values);
      return _readOne(transaction, id);
    });
    _changes.add(ExpenseChange.created);
    return expense;
  });

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) =>
      _run(() async {
        _requirePositive(id, 'id');
        final validated = _validator.validate(draft);
        final updatedAt = _clock.now().toUtc();
        final values = _mapper.domainToUpdateMap(validated, updatedAt);
        final database = await _database.open();
        final expense = await database.transaction((transaction) async {
          final affected = await transaction.update(
            _table,
            values,
            where: 'id = ?',
            whereArgs: <Object?>[id],
          );
          _requireOneAffected(affected, id);
          return _readOne(transaction, id);
        });
        _changes.add(ExpenseChange.updated);
        return expense;
      });

  @override
  Future<void> delete(int id) => _run(() async {
    _requirePositive(id, 'id');
    final database = await _database.open();
    await database.transaction((transaction) async {
      final affected = await transaction.delete(
        _table,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      _requireOneAffected(affected, id);
    });
    _changes.add(ExpenseChange.deleted);
  });

  /// Stops new operations, drains in-flight work, and closes the change stream.
  ///
  /// Subscribers should cancel their subscriptions before disposing the owner.
  /// The borrowed database remains open.
  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    _isDisposed = true;
    if (_activeOperations > 0) {
      final idle = Completer<void>();
      _idle = idle;
      await idle.future;
    }
    await _changes.close();
  }

  List<Expense> _mapRows(List<Map<String, Object?>> rows) =>
      List<Expense>.unmodifiable(rows.map(_mapper.rowToDomain));

  Future<Expense> _readOne(Transaction transaction, int id) async {
    final rows = await transaction.query(
      _table,
      columns: _columns,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    if (rows.length != 1) {
      throw const CorruptDataFailure('Written expense could not be read back');
    }
    return _mapper.rowToDomain(rows.single);
  }

  static void _requireOneAffected(int affected, int id) {
    if (affected == 0) {
      throw NotFoundFailure(id);
    }
    if (affected != 1) {
      throw const CorruptDataFailure('Expected exactly one affected expense');
    }
  }

  static void _requirePositive(int value, String name) {
    // Invalid repository arguments indicate caller misuse, not a form error.
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'Must be positive');
    }
  }

  Future<T> _run<T>(Future<T> Function() operation) async {
    if (_isDisposed) {
      throw UnexpectedFailure(StateError('Expense repository is disposed'));
    }
    _activeOperations++;
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } on Object catch (error, stackTrace) {
      final AppFailure failure;
      if (error is DatabaseException ||
          error is PlatformException ||
          error is MissingPluginException) {
        failure = StorageFailure(error);
      } else {
        failure = UnexpectedFailure(error);
      }
      Error.throwWithStackTrace(failure, stackTrace);
    } finally {
      _activeOperations--;
      if (_isDisposed && _activeOperations == 0) {
        _idle?.complete();
      }
    }
  }
}
