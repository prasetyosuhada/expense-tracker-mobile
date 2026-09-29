import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/data/expense_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  var nextDatabaseId = 0;
  late String testPath;
  late List<ExpenseDatabase> services;

  setUp(() async {
    final databasesPath = await getDatabasesPath();
    final uniqueName =
        'p1_006_${DateTime.now().microsecondsSinceEpoch}_${nextDatabaseId++}.db';
    testPath = p.join(databasesPath, uniqueName);
    services = <ExpenseDatabase>[];
    expect(await databaseExists(testPath), isFalse);
  });

  tearDown(() async {
    for (final service in services.reversed) {
      await service.close();
    }
    final testDirectory = Directory(testPath);
    if (await testDirectory.exists()) {
      await testDirectory.delete();
    } else if (await databaseExists(testPath)) {
      await deleteDatabase(testPath);
    }
  });

  ExpenseDatabase createService() {
    final service = ExpenseDatabase(databasePath: testPath);
    services.add(service);
    return service;
  }

  testWidgets('lazily creates the complete version 1 schema and order index', (
    tester,
  ) async {
    final service = createService();
    expect(await databaseExists(testPath), isFalse);

    final database = await service.open();
    expect(await databaseExists(testPath), isTrue);
    expect(await database.getVersion(), ExpenseDatabase.schemaVersion);

    final columns = await database.rawQuery('PRAGMA table_info(expenses)');
    expect(columns.map((column) => column['name']), <String>[
      'id',
      'amount',
      'category',
      'transaction_date',
      'note',
      'created_at',
      'updated_at',
    ]);
    final byName = <String, Map<String, Object?>>{
      for (final column in columns) column['name'] as String: column,
    };
    expect(byName['id']?['pk'], 1);
    expect(byName['id']?['type'], 'INTEGER');
    for (final requiredColumn in <String>[
      'amount',
      'category',
      'transaction_date',
      'created_at',
      'updated_at',
    ]) {
      expect(byName[requiredColumn]?['notnull'], 1);
    }
    expect(byName['note']?['notnull'], 0);

    final indexRows = await database.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'index' "
      "AND name = 'idx_expenses_order'",
    );
    expect(indexRows, hasLength(1));
    expect(
      indexRows.single['sql'],
      contains('(transaction_date DESC, created_at DESC, id DESC)'),
    );
  });

  testWidgets(
    'rejects invalid amount, category, date length, and null fields',
    (tester) async {
      final database = await createService().open();
      final validRow = <String, Object?>{
        'amount': 1,
        'category': 'food',
        'transaction_date': '2026-09-08',
        'note': null,
        'created_at': 1,
        'updated_at': 1,
      };
      await database.insert('expenses', validRow);

      for (final invalidValues in <Map<String, Object?>>[
        <String, Object?>{'amount': 0},
        <String, Object?>{'amount': -1},
        <String, Object?>{'amount': 1000000000000},
        <String, Object?>{'category': 'unknown'},
        <String, Object?>{'transaction_date': '2026-9-8'},
        <String, Object?>{'amount': null},
        <String, Object?>{'category': null},
        <String, Object?>{'transaction_date': null},
        <String, Object?>{'created_at': null},
        <String, Object?>{'updated_at': null},
      ]) {
        await expectLater(
          database.insert('expenses', <String, Object?>{
            ...validRow,
            ...invalidValues,
          }),
          throwsA(isA<DatabaseException>()),
        );
      }
      expect(await database.query('expenses'), hasLength(1));
    },
  );

  testWidgets('reopens the same file without recreating the schema', (
    tester,
  ) async {
    final service = createService();
    final first = await service.open();
    expect(identical(await service.open(), first), isTrue);
    await first.insert('expenses', <String, Object?>{
      'amount': 25000,
      'category': 'food',
      'transaction_date': '2026-09-08',
      'note': null,
      'created_at': 1,
      'updated_at': 1,
    });
    await service.close();

    final reopened = await createService().open();
    expect(await reopened.getVersion(), 1);
    expect(await reopened.query('expenses'), hasLength(1));
  });

  testWidgets('retries after an isolated path stops blocking the first open', (
    tester,
  ) async {
    final blockingDirectory = Directory(testPath);
    await blockingDirectory.create();
    final service = createService();

    await expectLater(service.open(), throwsA(isA<StorageFailure>()));

    await blockingDirectory.delete();
    final database = await service.open();
    expect(await database.getVersion(), 1);
    expect(await databaseExists(testPath), isTrue);
  });
}
