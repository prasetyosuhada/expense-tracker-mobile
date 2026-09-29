import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:expensetracker/core/errors/app_failure.dart';

/// Opens the local SQLite database and owns its versioned schema.
final class ExpenseDatabase {
  /// Uses the app database directory, or an isolated [databasePath] in tests.
  ExpenseDatabase({this.databasePath});

  /// The production database file name.
  static const String fileName = 'expense_tracker.db';

  /// The current physical schema version.
  static const int schemaVersion = 1;

  /// An optional path override for isolated database tests.
  final String? databasePath;
  Future<Database>? _openFuture;

  /// Opens on first use and shares one pending or completed open per instance.
  ///
  /// A failed open is not cached, so a later call can retry.
  Future<Database> open() => _openFuture ??= _openAndCache();

  /// Closes this instance's connection and permits a later [open].
  Future<void> close() async {
    final openFuture = _openFuture;
    _openFuture = null;
    if (openFuture != null) {
      final database = await openFuture;
      await database.close();
    }
  }

  Future<Database> _openAndCache() async {
    try {
      final resolvedPath =
          databasePath ?? p.join(await getDatabasesPath(), fileName);
      return await openDatabase(
        resolvedPath,
        version: schemaVersion,
        singleInstance: true,
        onCreate: _createSchema,
        onUpgrade: _migrate,
        onDowngrade: _rejectDowngrade,
      );
    } on Object catch (error, stackTrace) {
      _openFuture = null;
      Error.throwWithStackTrace(StorageFailure(error), stackTrace);
    }
  }

  static Future<void> _createSchema(Database database, int version) async {
    // sqflite runs onCreate in one transaction; both statements commit together.
    await database.execute('''
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount INTEGER NOT NULL
    CHECK (amount > 0 AND amount <= 999999999999),
  category TEXT NOT NULL
    CHECK (category IN ('food', 'transportation', 'shopping', 'bills', 'other')),
  transaction_date TEXT NOT NULL
    CHECK (length(transaction_date) = 10),
  note TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''');
    await database.execute('''
CREATE INDEX idx_expenses_order
ON expenses (transaction_date DESC, created_at DESC, id DESC)
''');
  }

  static Future<void> _migrate(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // sqflite wraps the whole onUpgrade callback in one transaction.
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 1:
          // Fresh files use onCreate; this handles an existing version-0 file.
          await _createSchema(database, version);
          break;
        default:
          // Add an explicit case for each later schema version.
          throw StateError('Missing migration for schema version $version');
      }
    }
  }

  static Future<void> _rejectDowngrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    throw StateError(
      'Database downgrade from $oldVersion to $newVersion is not supported',
    );
  }
}
