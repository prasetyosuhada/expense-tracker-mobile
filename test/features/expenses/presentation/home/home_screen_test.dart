import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/app/app_shell.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_screen.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/home/monthly_summary_card.dart';

import '../../../../helpers/fake_app_clock.dart';
import '../../../../helpers/fake_expense_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAppClock clock;
  late FakeExpenseRepository fake;
  final models = <HomeViewModel>[];

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 9, 20, 12));
    fake = FakeExpenseRepository(clock: clock);
  });

  tearDown(() async {
    for (final model in models) {
      model.dispose();
    }
    models.clear();
    await fake.dispose();
  });

  HomeViewModel createModel(ExpenseRepository repository) {
    final model = HomeViewModel(repository, clock)..onPause();
    models.add(model);
    return model;
  }

  testWidgets('initial read displays loading without a false empty state', (
    tester,
  ) async {
    final controlled = _ControlledHomeRepository(fake)..delayReads = true;
    final model = createModel(controlled);
    await _pumpHome(tester, model);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ListenableBuilder && identical(widget.listenable, model),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MonthlySummaryCard), findsNothing);
    expect(find.text('Belum ada pengeluaran'), findsNothing);
    expect(find.byType(BackButton), findsNothing);

    controlled.pending.single.complete(
      await fake.getHomeSummary(month: _month),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty Home renders summary tokens and both navigation actions', (
    tester,
  ) async {
    final model = createModel(fake);
    var additions = 0;
    var viewAll = 0;
    await _pumpHome(
      tester,
      model,
      onAddExpense: () => additions++,
      onViewAll: () => viewAll++,
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Total pengeluaran'), findsOneWidget);
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.text('Transaksi terbaru'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran'), findsOneWidget);
    expect(
      find.text('Tambahkan pengeluaran pertamamu untuk mulai mencatat.'),
      findsOneWidget,
    );
    final summary = find.byType(MonthlySummaryCard);
    final card = tester.widget<Card>(
      find.descendant(of: summary, matching: find.byType(Card)),
    );
    expect(card.color, AppColors.primary);
    expect(
      (card.shape as RoundedRectangleBorder).borderRadius,
      AppShapes.cardRadius,
    );
    final padding = card.child! as Padding;
    expect(padding.padding, const EdgeInsets.all(AppSpacing.summaryPadding));
    final total = tester.widget<Text>(find.text('Rp0'));
    expect(total.style?.fontFamily, 'Geist');
    expect(total.style?.fontWeight, FontWeight.w900);
    expect(total.style?.color, AppColors.onPrimary);

    await tester.tap(find.text('Lihat semua'));
    await tester.tap(find.text('Tambah Pengeluaran'));
    expect(viewAll, 1);
    expect(additions, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('F-MIX displays monthly total and five latest global expenses', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 1200));
    final mixed = FakeExpenseRepository(
      clock: clock,
      initialExpenses: _mixedExpenses(),
    );
    addTearDown(mixed.dispose);
    await _pumpHome(tester, createModel(mixed));
    await tester.pumpAndSettle();

    expect(find.text('Rp145.000'), findsOneWidget);
    for (final id in <int>[7, 6, 5, 4, 3]) {
      expect(find.byKey(ValueKey(id)), findsOneWidget);
    }
    for (final id in <int>[2, 1, 8]) {
      expect(find.byKey(ValueKey(id)), findsNothing);
    }
    expect(find.text('1 Okt 2026'), findsOneWidget);
    expect(find.text('Rp70.000'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran'), findsNothing);
    expect(find.text('Transportasi'), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Tagihan'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);
    expect(find.text('Belanja kebutuhan'), findsOneWidget);
    final note = tester.widget<Text>(find.text('Belanja kebutuhan'));
    expect(note.maxLines, 2);
    expect(note.overflow, TextOverflow.ellipsis);
    final positions = <double>[
      for (final id in <int>[7, 6, 5, 4, 3])
        tester.getTopLeft(find.byKey(ValueKey(id))).dy,
    ];
    expect(positions, orderedEquals(List<double>.of(positions)..sort()));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('other-month expenses keep the latest list with a zero total', (
    tester,
  ) async {
    final otherMonth = FakeExpenseRepository(
      clock: clock,
      initialExpenses: [_mixedExpenses().first],
    );
    addTearDown(otherMonth.dispose);
    await _pumpHome(tester, createModel(otherMonth));
    await tester.pumpAndSettle();

    expect(find.text('Rp0'), findsOneWidget);
    expect(find.text('Rp10.000'), findsOneWidget);
    expect(find.text('31 Agu 2026'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final failure in <AppFailure>[
    const StorageFailure(null),
    const CorruptDataFailure('technical stored row details'),
    const UnexpectedFailure('technical plugin details'),
  ]) {
    testWidgets(
      '${failure.runtimeType} renders read error and supports retry',
      (tester) async {
        fake.getHomeSummaryFailure = failure;
        await _pumpHome(tester, createModel(fake));
        await tester.pumpAndSettle();

        expect(find.text('Data tidak dapat dimuat'), findsOneWidget);
        expect(
          find.text('Terjadi masalah saat membuka data pengeluaran.'),
          findsOneWidget,
        );
        expect(find.text('Coba Lagi'), findsOneWidget);
        expect(find.byType(MonthlySummaryCard), findsNothing);
        expect(find.text('Rp0'), findsNothing);
        expect(find.textContaining('technical'), findsNothing);

        fake.getHomeSummaryFailure = null;
        await tester.tap(find.text('Coba Lagi'));
        await tester.pumpAndSettle();
        expect(find.text('Data tidak dapat dimuat'), findsNothing);
        expect(find.text('Rp0'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('refresh keeps old data until a new snapshot arrives', (
    tester,
  ) async {
    final controlled = _ControlledHomeRepository(fake);
    final model = createModel(controlled);
    await _pumpHome(tester, model);
    await tester.pumpAndSettle();
    controlled.delayReads = true;

    await fake.create(_draft());
    await tester.pump();
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    controlled.pending.single.complete(
      await fake.getHomeSummary(month: _month),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp25.000'), findsNWidgets(2));
    expect(find.text('Makan siang'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'failed refresh retains data and offers one snackbar with retry',
    (tester) async {
      final model = createModel(fake);
      await _pumpHome(tester, model);
      await tester.pumpAndSettle();
      fake.getHomeSummaryFailure = const StorageFailure(null);
      await model.load();
      await tester.pump();
      await tester.pump();

      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text('Data tidak dapat dimuat'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Data pengeluaran gagal diperbarui. Coba lagi.'),
        findsOneWidget,
      );

      fake.getHomeSummaryFailure = null;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await _pumpHome(tester, model);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('inactive Home defers refresh feedback until it becomes active', (
    tester,
  ) async {
    final model = createModel(fake);
    await _pumpHome(tester, model, isActive: false);
    await tester.pumpAndSettle();
    fake.getHomeSummaryFailure = const StorageFailure(null);
    await model.load();
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);

    await _pumpHome(tester, model);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('replacing the view model detaches old snapshots and listeners', (
    tester,
  ) async {
    final first = createModel(fake);
    await _pumpHome(tester, first);
    await tester.pumpAndSettle();
    final replacement = FakeExpenseRepository(
      clock: clock,
      initialExpenses: [_mixedExpenses()[3]],
    );
    addTearDown(replacement.dispose);
    await _pumpHome(tester, createModel(replacement));
    await tester.pumpAndSettle();

    expect(find.text('Rp40.000'), findsNWidgets(2));
    fake.getHomeSummaryFailure = const StorageFailure(null);
    await first.load();
    await tester.pumpAndSettle();
    expect(find.text('Rp40.000'), findsNWidgets(2));
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unmount safely discards pending refresh feedback', (
    tester,
  ) async {
    final model = createModel(fake);
    await _pumpHome(tester, model);
    await tester.pumpAndSettle();
    fake.getHomeSummaryFailure = const StorageFailure(null);
    await model.load();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long totals and notes remain usable at 320dp with text scale 2',
    (tester) async {
      _setViewport(tester, const Size(320, 640));
      final expense = Expense(
        id: 1,
        amount: 999999999999,
        category: ExpenseCategory.transportation,
        transactionDate: ExpenseDate(2026, 9, 20),
        note: List<String>.filled(20, 'jalan').join(),
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );
      final controlled = _ControlledHomeRepository(fake)
        ..summary = HomeSummary(
          month: _month,
          monthlyTotal: 9999999999990000,
          latestExpenses: [expense],
        );
      await _pumpHome(tester, createModel(controlled), textScale: 2);
      await tester.pumpAndSettle();

      expect(find.text('Rp9.999.999.999.990.000'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Rp9.999.999.999.990.000')).maxLines,
        isNull,
      );
      await tester.scrollUntilVisible(find.byKey(const ValueKey(1)), 200);
      expect(find.text('Rp999.999.999.999'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Home actions integrate with the existing shell destinations', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        AppShell(
          clock: clock,
          repository: fake,
          addExpenseBuilder: (context, model) =>
              Scaffold(appBar: AppBar(title: const Text('add route fixture'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat semua'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tambah Pengeluaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Pengeluaran'));
    await tester.pumpAndSettle();
    expect(find.text('add route fixture'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('Home goldens', () {
    setUpAll(() async {
      final geist = FontLoader('Geist')
        ..addFont(rootBundle.load('assets/fonts/geist/Geist-Bold.ttf'))
        ..addFont(rootBundle.load('assets/fonts/geist/Geist-Black.ttf'));
      final inter = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/inter/Inter-SemiBold.ttf'));
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await geist.load();
      await inter.load();
      await icons.load();
    });

    for (final hasData in <bool>[false, true]) {
      testWidgets('matches ${hasData ? 'F-MIX' : 'empty'} Home baseline', (
        tester,
      ) async {
        _setViewport(tester, const Size(390, 844));
        final repository = FakeExpenseRepository(
          clock: clock,
          initialExpenses: hasData ? _mixedExpenses() : const <Expense>[],
        );
        addTearDown(repository.dispose);
        await tester.pumpWidget(
          _app(
            RepaintBoundary(
              key: const ValueKey('home-golden'),
              child: AppShell(clock: clock, repository: repository),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await expectLater(
          find.byKey(const ValueKey('home-golden')),
          matchesGoldenFile('goldens/home_${hasData ? 'data' : 'empty'}.png'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}

final _month = ExpenseMonth(2026, 9);

Future<void> _pumpHome(
  WidgetTester tester,
  HomeViewModel model, {
  VoidCallback onAddExpense = _noop,
  VoidCallback onViewAll = _noop,
  bool isActive = true,
  double textScale = 1,
}) => tester.pumpWidget(
  _app(
    HomeScreen(
      viewModel: model,
      onAddExpense: onAddExpense,
      onViewAll: onViewAll,
      isActive: isActive,
    ),
    textScale: textScale,
  ),
);

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
  locale: const Locale('id', 'ID'),
  supportedLocales: const [Locale('id', 'ID')],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void _noop() {}

ExpenseDraft _draft() => ExpenseDraft(
  amount: 25000,
  category: ExpenseCategory.food,
  transactionDate: ExpenseDate(2026, 9, 20),
  note: 'Makan siang',
);

List<Expense> _mixedExpenses() {
  final dates = <ExpenseDate>[
    ExpenseDate(2026, 8, 31),
    ExpenseDate(2026, 9, 1),
    ExpenseDate(2026, 9, 19),
    ExpenseDate(2026, 9, 20),
    ExpenseDate(2026, 9, 20),
    ExpenseDate(2026, 9, 30),
    ExpenseDate(2026, 10, 1),
    ExpenseDate(2025, 9, 20),
  ];
  final amounts = <int>[10000, 25000, 15000, 40000, 60000, 5000, 70000, 80000];
  final categories = <ExpenseCategory>[
    ExpenseCategory.food,
    ExpenseCategory.transportation,
    ExpenseCategory.shopping,
    ExpenseCategory.bills,
    ExpenseCategory.other,
    ExpenseCategory.food,
    ExpenseCategory.transportation,
    ExpenseCategory.shopping,
  ];
  return <Expense>[
    for (var index = 0; index < dates.length; index++)
      Expense(
        id: index + 1,
        amount: amounts[index],
        category: categories[index],
        transactionDate: dates[index],
        note: index == 2 ? 'Belanja kebutuhan' : null,
        createdAt: DateTime.utc(2026, 9, 20, 1, index == 4 ? 3 : index),
        updatedAt: DateTime.utc(2026, 9, 20, 1, index == 4 ? 3 : index),
      ),
  ];
}

final class _ControlledHomeRepository implements ExpenseRepository {
  _ControlledHomeRepository(this.delegate);

  final FakeExpenseRepository delegate;
  final List<Completer<HomeSummary>> pending = <Completer<HomeSummary>>[];
  bool delayReads = false;
  HomeSummary? summary;

  @override
  Stream<ExpenseChange> get changes => delegate.changes;

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) {
    if (delayReads) {
      final completer = Completer<HomeSummary>();
      pending.add(completer);
      return completer.future;
    }
    final result = summary;
    if (result != null) return Future<HomeSummary>.value(result);
    return delegate.getHomeSummary(month: month, latestLimit: latestLimit);
  }

  @override
  Future<List<Expense>> getAll() => delegate.getAll();

  @override
  Future<Expense> create(ExpenseDraft draft) => delegate.create(draft);

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) =>
      delegate.update(id: id, draft: draft);

  @override
  Future<void> delete(int id) => delegate.delete(id);
}
