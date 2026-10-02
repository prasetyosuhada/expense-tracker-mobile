import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite/sqflite.dart';

import 'package:expensetracker/app/app_bootstrap.dart';
import 'package:expensetracker/core/clock/system_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/features/expenses/data/sqlite_expense_repository.dart';
import 'package:expensetracker/main.dart' as app;

import '../helpers/fake_app_clock.dart';
import '../helpers/fake_expense_repository.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.tekartik.sqflite');
  late List<String> storageCalls;
  late DatabaseFactory? previousFactory;

  setUp(() {
    storageCalls = <String>[];
    // Desktop host tests need the plugin factory to reach the mocked channel.
    previousFactory = databaseFactoryOrNull;
    databaseFactoryOrNull = databaseFactorySqflitePlugin;
    // Fail at the platform boundary; these tests never create a SQLite file.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) {
      storageCalls.add(call.method);
      throw PlatformException(code: 'storage_unavailable');
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    databaseFactoryOrNull = previousFactory;
  });

  test(
    'bootstrap creates independent repositories without opening storage',
    () async {
      final first = AppBootstrap();
      final second = AppBootstrap();
      addTearDown(first.database.close);
      addTearDown(first.repository.dispose);
      addTearDown(second.database.close);
      addTearDown(second.repository.dispose);

      expect(first.clock, isA<SystemClock>());
      expect(second.repository, isNot(same(first.repository)));
      expect(second.database, isNot(same(first.database)));
      await Future<void>.delayed(Duration.zero);
      expect(storageCalls, isEmpty);
    },
  );

  testWidgets('main launches before storage access and defers open failures', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    final root = tester.widget<app.MainApp>(find.byType(app.MainApp));
    final repository = root.repository as SqliteExpenseRepository;
    addTearDown(repository.dispose);

    expect(root.clock, isA<SystemClock>());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(storageCalls, isEmpty);
    expect(tester.takeException(), isNull);

    // Only a read after launch reaches the unavailable platform plugin.
    await expectLater(repository.getAll(), throwsA(isA<StorageFailure>()));
    expect(storageCalls, isNotEmpty);
  });

  testWidgets(
    'app accepts fake dependencies and keeps Indonesian localization',
    (tester) async {
      final clock = FakeAppClock(DateTime(2026, 10, 2));
      final repository = FakeExpenseRepository(clock: clock);
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        app.MainApp(clock: clock, repository: repository),
      );
      await tester.pumpAndSettle();
      final root = tester.widget<app.MainApp>(find.byType(app.MainApp));
      final context = tester.element(find.byType(Scaffold));

      expect(root.clock, same(clock));
      expect(root.repository, same(repository));
      expect(Localizations.localeOf(context), const Locale('id', 'ID'));
      expect(AppLocalizations.of(context), isNotNull);
      expect(storageCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
