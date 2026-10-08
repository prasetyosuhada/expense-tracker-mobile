import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/app/app.dart';
import 'package:expensetracker/app/app_shell.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_state.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_state.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_state.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';

import '../helpers/fake_app_clock.dart';
import '../helpers/fake_expense_repository.dart';

void main() {
  late FakeAppClock clock;
  late FakeExpenseRepository repository;

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 10, 2, 12));
    repository = FakeExpenseRepository(clock: clock);
  });

  tearDown(() async {
    await repository.dispose();
  });

  testWidgets('app starts on Home with theme and Indonesian localization', (
    tester,
  ) async {
    await tester.pumpWidget(MainApp(clock: clock, repository: repository));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppShell));
    final theme = Theme.of(context);
    expect(_selectedIndex(tester), 0);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
    expect(Localizations.localeOf(context), const Locale('id', 'ID'));
    expect(AppLocalizations.of(context)?.navigationHome, 'Beranda');
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.extension<CategoryColors>(), CategoryColors.light);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tab changes preserve scroll and mounted state in both tabs', (
    tester,
  ) async {
    final homeScroll = ScrollController();
    final transactionsScroll = ScrollController();
    addTearDown(homeScroll.dispose);
    addTearDown(transactionsScroll.dispose);
    late HomeViewModel home;
    late TransactionsViewModel transactions;
    await _pumpShell(
      tester,
      AppShell(
        clock: clock,
        repository: repository,
        homeBuilder: (context, model) {
          home = model;
          return _scrollDestination(homeScroll, 'home');
        },
        transactionsBuilder: (context, model) {
          transactions = model;
          return _scrollDestination(transactionsScroll, 'transactions');
        },
      ),
    );
    final initialHome = home;
    final initialTransactions = transactions;
    final homeElement = tester.element(find.byKey(const ValueKey('home')));
    homeScroll.jumpTo(400);
    await tester.pump();

    await _selectTransactions(tester);
    expect(_selectedIndex(tester), 1);
    expect(find.byKey(const ValueKey('home')), findsNothing);
    expect(find.byKey(const ValueKey('transactions')), findsOneWidget);
    transactionsScroll.jumpTo(300);
    await tester.pump();
    await _selectHome(tester);

    expect(homeScroll.offset, 400);
    expect(
      tester.element(find.byKey(const ValueKey('home'))),
      same(homeElement),
    );
    expect(home, same(initialHome));
    expect(transactions, same(initialTransactions));
    await _selectTransactions(tester);
    expect(transactionsScroll.offset, 300);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Back on Transactions selects Home without exiting', (
    tester,
  ) async {
    final platformCalls = _capturePlatformCalls(tester);
    await _pumpShell(tester, AppShell(clock: clock, repository: repository));
    await _selectTransactions(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(_selectedIndex(tester), 0);
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(find.text('Pengeluaran'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Back on Home follows the default platform exit behavior', (
    tester,
  ) async {
    final platformCalls = _capturePlatformCalls(tester);
    await _pumpShell(tester, AppShell(clock: clock, repository: repository));

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(platformCalls, contains('SystemNavigator.pop'));
    expect(_selectedIndex(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final tab in [0, 1]) {
    testWidgets('FAB on tab $tab opens fresh add mode and returns to its tab', (
      tester,
    ) async {
      late ExpenseFormViewModel form;
      ModalRoute<Object?>? route;
      await _pumpShell(
        tester,
        AppShell(
          clock: clock,
          repository: repository,
          addExpenseBuilder: (context, model) {
            form = model;
            route = ModalRoute.of(context);
            return Scaffold(appBar: AppBar(title: const Text('form fixture')));
          },
        ),
      );
      if (tab == 1) await _selectTransactions(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(route, isA<MaterialPageRoute<ExpenseFormResult>>());
      expect(find.text('form fixture'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(form.isEditing, isFalse);
      expect(form.state.amountText, isEmpty);
      expect(form.state.selectedCategory, isNull);
      expect(form.state.selectedDate, ExpenseDate(2026, 10, 2));
      expect(form.state.noteText, isEmpty);
      expect(form.state.isDirty, isFalse);
      final originalForm = form;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_selectedIndex(tester), tab);
      expect(() => originalForm.addListener(_noop), throwsFlutterError);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(form, isNot(same(originalForm)));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), tab);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('FAB on tab $tab exposes an accessible labeled tap action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpShell(
          tester,
          AppShell(clock: clock, repository: repository),
        );
        if (tab == 1) await _selectTransactions(tester);

        final fab = find.bySemanticsLabel('Tambah pengeluaran');
        expect(fab, findsOneWidget);
        final data = tester.getSemantics(fab).getSemanticsData();
        expect(data.label, 'Tambah pengeluaran');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(
          find.descendant(
            of: find.byType(FloatingActionButton),
            matching: find.text('Tambah'),
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  testWidgets('default add route has a localized title and app-bar Back', (
    tester,
  ) async {
    await _pumpShell(tester, AppShell(clock: clock, repository: repository));
    await _selectTransactions(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Pengeluaran'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(_selectedIndex(tester), 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('repeated FAB taps push only one add route', (tester) async {
    final forms = <ExpenseFormViewModel>{};
    await _pumpShell(
      tester,
      AppShell(
        clock: clock,
        repository: repository,
        addExpenseBuilder: (context, model) {
          forms.add(model);
          return Scaffold(appBar: AppBar(title: const Text('form fixture')));
        },
      ),
    );
    final fab = find.byType(FloatingActionButton);
    final onPressed = tester.widget<FloatingActionButton>(fab).onPressed!;
    await tester.tap(fab);
    onPressed();
    await tester.pumpAndSettle();

    expect(forms.length, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shell rebuilds retain view models and selected destination', (
    tester,
  ) async {
    late HomeViewModel home;
    late TransactionsViewModel transactions;
    AppShell shell() => AppShell(
      clock: clock,
      repository: repository,
      homeBuilder: (context, model) {
        home = model;
        return const SizedBox.expand();
      },
      transactionsBuilder: (context, model) {
        transactions = model;
        return const SizedBox.expand();
      },
    );
    await _pumpShell(tester, shell());
    final originalHome = home;
    final originalTransactions = transactions;
    await _selectTransactions(tester);

    await _pumpShell(tester, shell());

    expect(home, same(originalHome));
    expect(transactions, same(originalTransactions));
    expect(home.state, isA<HomeData>());
    expect(transactions.state, isA<TransactionsData>());
    expect(_selectedIndex(tester), 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'dependency replacement disposes models and loads new snapshots',
    (tester) async {
      late HomeViewModel home;
      late TransactionsViewModel transactions;
      AppShell shell(FakeExpenseRepository source, FakeAppClock appClock) =>
          AppShell(
            clock: appClock,
            repository: source,
            homeBuilder: (context, model) {
              home = model;
              return const SizedBox.expand();
            },
            transactionsBuilder: (context, model) {
              transactions = model;
              return const SizedBox.expand();
            },
          );
      await _pumpShell(tester, shell(repository, clock));
      final originalHome = home;
      final originalTransactions = transactions;
      final replacementClock = FakeAppClock(DateTime(2026, 11, 2));
      final replacement = FakeExpenseRepository(clock: replacementClock);
      addTearDown(replacement.dispose);
      await replacement.create(_draft(ExpenseDate(2026, 11, 2)));

      await _pumpShell(tester, shell(replacement, replacementClock));

      expect(() => originalHome.addListener(_noop), throwsFlutterError);
      expect(() => originalTransactions.addListener(_noop), throwsFlutterError);
      expect((home.state as HomeData).summary.month, ExpenseMonth(2026, 11));
      expect((home.state as HomeData).summary.monthlyTotal, 25000);
      expect((transactions.state as TransactionsData).expenses, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('resume rechecks Home month while Transactions is active', (
    tester,
  ) async {
    late HomeViewModel home;
    await _pumpShell(
      tester,
      AppShell(
        clock: clock,
        repository: repository,
        homeBuilder: (context, model) {
          home = model;
          return const SizedBox.expand();
        },
      ),
    );
    await _selectTransactions(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.currentTime = DateTime(2026, 11, 1, 9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect((home.state as HomeData).summary.month, ExpenseMonth(2026, 11));
    expect(_selectedIndex(tester), 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'initial read failures stay typed and resume retries both models',
    (tester) async {
      const failure = StorageFailure(null);
      repository.getHomeSummaryFailure = failure;
      repository.getAllFailure = failure;
      late HomeViewModel home;
      late TransactionsViewModel transactions;
      await _pumpShell(
        tester,
        AppShell(
          clock: clock,
          repository: repository,
          homeBuilder: (context, model) {
            home = model;
            return const SizedBox.expand();
          },
          transactionsBuilder: (context, model) {
            transactions = model;
            return const SizedBox.expand();
          },
        ),
      );
      expect((home.state as HomeError).failure, same(failure));
      expect((transactions.state as TransactionsError).failure, same(failure));
      repository.getHomeSummaryFailure = null;
      repository.getAllFailure = null;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(home.state, isA<HomeData>());
      expect(transactions.state, isA<TransactionsData>());
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'shell disposal releases models while keeping repository usable',
    (tester) async {
      late HomeViewModel home;
      late TransactionsViewModel transactions;
      await _pumpShell(
        tester,
        AppShell(
          clock: clock,
          repository: repository,
          homeBuilder: (context, model) {
            home = model;
            return const SizedBox.expand();
          },
          transactionsBuilder: (context, model) {
            transactions = model;
            return const SizedBox.expand();
          },
        ),
      );
      final homeState = home.state;
      final transactionsState = transactions.state;

      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => home.addListener(_noop), throwsFlutterError);
      expect(() => transactions.addListener(_noop), throwsFlutterError);
      await repository.create(_draft(ExpenseDate(2026, 10, 2)));
      await tester.pump();

      expect(home.state, same(homeState));
      expect(transactions.state, same(transactionsState));
      expect(await repository.getAll(), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpShell(WidgetTester tester, AppShell shell) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: shell,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _scrollDestination(ScrollController controller, String name) => ListView(
  key: ValueKey(name),
  controller: controller,
  children: List<Widget>.generate(
    40,
    (index) => SizedBox(height: 80, child: Text('$name $index')),
  ),
);

int _selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> _selectTransactions(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Transaksi'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectHome(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Beranda'),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _capturePlatformCalls(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      calls.add(call.method);
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  return calls;
}

ExpenseDraft _draft(ExpenseDate date) => ExpenseDraft(
  amount: 25000,
  category: ExpenseCategory.food,
  transactionDate: date,
  note: null,
);

void _noop() {}
