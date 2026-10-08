import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
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
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_screen.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_state.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/widgets/expense_list_item.dart';

import '../../../../helpers/fake_app_clock.dart';
import '../../../../helpers/fake_expense_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAppClock clock;
  late FakeExpenseRepository fake;
  final models = <TransactionsViewModel>[];

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 10, 2, 12));
    fake = FakeExpenseRepository(clock: clock);
  });

  tearDown(() async {
    for (final model in models) {
      model.dispose();
    }
    models.clear();
    await fake.dispose();
  });

  TransactionsViewModel createModel(ExpenseRepository repository) {
    final model = TransactionsViewModel(repository);
    models.add(model);
    return model;
  }

  Widget buildApp(
    Widget child, {
    TransactionsViewModel? viewModel,
    VoidCallback? onAddExpense,
    ValueChanged<Expense>? onTapExpense,
    ValueChanged<Expense>? onEditExpense,
    ValueChanged<Expense>? onDeleteExpense,
    ScrollController? scrollController,
    bool isActive = true,
  }) {
    return MaterialApp(
      theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    );
  }

  Future<void> pumpTransactions(
    WidgetTester tester,
    TransactionsViewModel viewModel, {
    VoidCallback? onAddExpense,
    ValueChanged<Expense>? onTapExpense,
    ValueChanged<Expense>? onEditExpense,
    ValueChanged<Expense>? onDeleteExpense,
    ScrollController? scrollController,
    bool isActive = true,
  }) async {
    await tester.pumpWidget(
      buildApp(
        TransactionsScreen(
          viewModel: viewModel,
          onAddExpense: onAddExpense ?? () {},
          onTapExpense: onTapExpense,
          onEditExpense: onEditExpense,
          onDeleteExpense: onDeleteExpense,
          scrollController: scrollController,
          isActive: isActive,
        ),
      ),
    );
  }

  testWidgets('initial read displays loading without a false empty state', (
    tester,
  ) async {
    final controlled = _ControlledTransactionsRepository(fake)
      ..delayReads = true;
    final model = createModel(controlled);
    await pumpTransactions(tester, model);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Belum ada transaksi'), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Transaksi'), findsOneWidget);

    controlled.pendingReads.single.complete(<Expense>[]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Belum ada transaksi'), findsOneWidget);
  });

  testWidgets(
    'empty Transactions renders empty title, description, and Tambah button',
    (tester) async {
      final model = createModel(fake);
      var additions = 0;
      await pumpTransactions(tester, model, onAddExpense: () => additions++);
      await tester.pumpAndSettle();

      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Belum ada transaksi'), findsOneWidget);
      expect(
        find.text('Pengeluaran yang kamu tambahkan akan muncul di sini.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

      final addButton = find.widgetWithText(FilledButton, 'Tambah Pengeluaran');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      expect(additions, 1);
    },
  );

  testWidgets(
    'data state renders all transactions in canonical order using ListView.builder',
    (tester) async {
      await fake.create(
        ExpenseDraft(
          amount: 25000,
          category: ExpenseCategory.food,
          transactionDate: ExpenseDate(2026, 10, 1),
          note: 'Makan siang',
        ),
      );
      await fake.create(
        ExpenseDraft(
          amount: 50000,
          category: ExpenseCategory.transportation,
          transactionDate: ExpenseDate(2026, 10, 2),
          note: null,
        ),
      );
      await fake.create(
        ExpenseDraft(
          amount: 100000,
          category: ExpenseCategory.shopping,
          transactionDate: ExpenseDate(2026, 9, 28),
          note: 'Baju baru',
        ),
      );

      final model = createModel(fake);
      await pumpTransactions(tester, model);
      await tester.pumpAndSettle();

      // Verify ListView uses SliverChildBuilderDelegate (lazy ListView.builder)
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.childrenDelegate, isA<SliverChildBuilderDelegate>());

      // Verify padding has bottom room for FAB
      final padding = listView.padding as EdgeInsets;
      expect(
        padding.bottom,
        AppSpacing.primaryButtonHeight + AppSpacing.sectionGap,
      );

      // Verify items are rendered in canonical order:
      // Oct 2 (transportation) first, then Oct 1 (food), then Sep 28 (shopping)
      final itemWidgets = tester
          .widgetList<ExpenseListItem>(find.byType(ExpenseListItem))
          .toList();
      expect(itemWidgets, hasLength(3));
      expect(itemWidgets[0].expense.category, ExpenseCategory.transportation);
      expect(itemWidgets[0].expense.amount, 50000);
      expect(itemWidgets[1].expense.category, ExpenseCategory.food);
      expect(itemWidgets[1].expense.amount, 25000);
      expect(itemWidgets[2].expense.category, ExpenseCategory.shopping);
      expect(itemWidgets[2].expense.amount, 100000);

      // Verify notes rendered
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Baju baru'), findsOneWidget);

      // Verify NO swipe-to-delete (Dismissible) is present
      expect(find.byType(Dismissible), findsNothing);
    },
  );

  testWidgets('error state renders danger card with retry button', (
    tester,
  ) async {
    final controlled = _ControlledTransactionsRepository(fake)
      ..readError = const StorageFailure('disk full');
    final model = createModel(controlled);
    await pumpTransactions(tester, model);
    await tester.pumpAndSettle();

    expect(find.text('Data tidak dapat dimuat'), findsOneWidget);
    expect(
      find.text('Terjadi masalah saat membuka data pengeluaran.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    final retryButton = find.widgetWithText(FilledButton, 'Coba Lagi');
    expect(retryButton, findsOneWidget);

    // Resolve read error and tap retry
    controlled.readError = null;
    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(find.text('Data tidak dapat dimuat'), findsNothing);
    expect(find.text('Belum ada transaksi'), findsOneWidget);
  });

  testWidgets('refreshing state preserves visible list while read is pending', (
    tester,
  ) async {
    await fake.create(
      ExpenseDraft(
        amount: 25000,
        category: ExpenseCategory.food,
        transactionDate: ExpenseDate(2026, 10, 1),
        note: null,
      ),
    );

    final controlled = _ControlledTransactionsRepository(fake);
    final model = createModel(controlled);
    await pumpTransactions(tester, model);
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseListItem), findsOneWidget);

    // Delay subsequent reads
    controlled.delayReads = true;
    final loadFuture = model.load();
    await tester.pump();

    // Verify list is still displayed and no full screen spinner replaces it
    expect(model.state, isA<TransactionsRefreshing>());
    expect(find.byType(ExpenseListItem), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    controlled.pendingReads.single.complete(await fake.getAll());
    await loadFuture;
    await tester.pumpAndSettle();

    expect(model.state, isA<TransactionsData>());
    expect(find.byType(ExpenseListItem), findsOneWidget);
  });

  testWidgets('refresh failure displays snackbar with retry action', (
    tester,
  ) async {
    await fake.create(
      ExpenseDraft(
        amount: 25000,
        category: ExpenseCategory.food,
        transactionDate: ExpenseDate(2026, 10, 1),
        note: null,
      ),
    );

    final controlled = _ControlledTransactionsRepository(fake);
    final model = createModel(controlled);
    await pumpTransactions(tester, model);
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseListItem), findsOneWidget);

    // Inject failure on refresh
    controlled.readError = const StorageFailure('refresh failed');
    await model.load();
    await tester.pumpAndSettle();

    // Verify snackbar is shown
    expect(
      find.text('Data transaksi gagal diperbarui. Coba lagi.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SnackBarAction, 'Coba Lagi'), findsOneWidget);

    // Tap retry
    controlled.readError = null;
    await tester.tap(find.widgetWithText(SnackBarAction, 'Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(ExpenseListItem), findsOneWidget);
  });

  testWidgets(
    'scroll position resets to top on successful refresh after write',
    (tester) async {
      // Seed 20 items so the list is scrollable
      for (var i = 1; i <= 20; i++) {
        await fake.create(
          ExpenseDraft(
            amount: i * 10000,
            category: ExpenseCategory.food,
            transactionDate: ExpenseDate(2026, 10, i > 28 ? 28 : i),
            note: 'Item $i',
          ),
        );
      }

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final model = createModel(fake);
      await pumpTransactions(tester, model, scrollController: scrollController);
      await tester.pumpAndSettle();

      // Scroll down
      scrollController.jumpTo(300);
      await tester.pump();
      expect(scrollController.offset, 300);

      // Mutate repository (simulating write commit)
      await fake.create(
        ExpenseDraft(
          amount: 99000,
          category: ExpenseCategory.bills,
          transactionDate: ExpenseDate(2026, 10, 2),
          note: 'New write',
        ),
      );

      // Repository change triggers model.load() which refreshes and commits new data
      await tester.pumpAndSettle();

      // Verify scroll offset returned to top
      expect(scrollController.offset, 0.0);
    },
  );

  testWidgets(
    'item callbacks: tap triggers onTapExpense, popup menu triggers edit and delete',
    (tester) async {
      final created = await fake.create(
        ExpenseDraft(
          amount: 25000,
          category: ExpenseCategory.food,
          transactionDate: ExpenseDate(2026, 10, 1),
          note: null,
        ),
      );

      Expense? tappedExpense;
      Expense? editedExpense;
      Expense? deletedExpense;

      final model = createModel(fake);
      await pumpTransactions(
        tester,
        model,
        onTapExpense: (e) => tappedExpense = e,
        onEditExpense: (e) => editedExpense = e,
        onDeleteExpense: (e) => deletedExpense = e,
      );
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byType(ExpenseListItem));
      expect(tappedExpense?.id, created.id);

      // Open popup menu and select Edit
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(editedExpense?.id, created.id);

      // Open popup menu and select Delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(deletedExpense?.id, created.id);
    },
  );
}

final class _ControlledTransactionsRepository implements ExpenseRepository {
  _ControlledTransactionsRepository(this.delegate);

  final FakeExpenseRepository delegate;
  final List<Completer<List<Expense>>> pendingReads =
      <Completer<List<Expense>>>[];
  bool delayReads = false;
  Object? readError;

  @override
  Stream<ExpenseChange> get changes => delegate.changes;

  @override
  Future<List<Expense>> getAll() async {
    final error = readError;
    if (error != null) throw error;
    if (!delayReads) return delegate.getAll();
    final completer = Completer<List<Expense>>();
    pendingReads.add(completer);
    return completer.future;
  }

  @override
  Future<void> delete(int id) => delegate.delete(id);

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) => delegate.getHomeSummary(month: month, latestLimit: latestLimit);

  @override
  Future<Expense> create(ExpenseDraft draft) => delegate.create(draft);

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) =>
      delegate.update(id: id, draft: draft);
}
