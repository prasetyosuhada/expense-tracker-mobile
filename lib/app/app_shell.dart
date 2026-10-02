import 'dart:async';

import 'package:flutter/material.dart';

import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_state.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';

typedef HomeDestinationBuilder = Widget Function(
  BuildContext context,
  HomeViewModel viewModel,
);
typedef TransactionsDestinationBuilder = Widget Function(
  BuildContext context,
  TransactionsViewModel viewModel,
);
typedef AddExpenseBuilder = Widget Function(
  BuildContext context,
  ExpenseFormViewModel viewModel,
);

/// Owns the two persistent destinations and opens add mode above either tab.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.clock,
    required this.repository,
    this.homeBuilder,
    this.transactionsBuilder,
    this.addExpenseBuilder,
  });

  final AppClock clock;
  final ExpenseRepository repository;

  // Screen contents are supplied as their P3 tasks land. Builders also let
  // navigation tests exercise scroll and lifecycle without implementing them.
  final HomeDestinationBuilder? homeBuilder;
  final TransactionsDestinationBuilder? transactionsBuilder;
  final AddExpenseBuilder? addExpenseBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late HomeViewModel _homeViewModel;
  late TransactionsViewModel _transactionsViewModel;
  int _selectedIndex = 0;
  bool _isFormOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createViewModels();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.clock != widget.clock) {
      _disposeViewModels();
      _createViewModels();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_homeViewModel.onResume());
      unawaited(_transactionsViewModel.onResume());
    } else {
      _homeViewModel.onPause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeViewModels();
    super.dispose();
  }

  void _createViewModels() {
    _homeViewModel = HomeViewModel(widget.repository, widget.clock);
    _transactionsViewModel = TransactionsViewModel(widget.repository);
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _homeViewModel.onPause();
    }
    unawaited(_homeViewModel.load());
    unawaited(_transactionsViewModel.load());
  }

  void _disposeViewModels() {
    _homeViewModel.dispose();
    _transactionsViewModel.dispose();
  }

  void _selectDestination(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _openAddExpense() async {
    if (_isFormOpen) return;
    _isFormOpen = true;
    try {
      await Navigator.of(context).push<ExpenseFormResult>(
        MaterialPageRoute<ExpenseFormResult>(
          builder: (context) => _AddExpenseRoute(
            clock: widget.clock,
            repository: widget.repository,
            builder: widget.addExpenseBuilder,
          ),
        ),
      );
    } finally {
      _isFormOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope<Object?>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) _selectDestination(0);
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              widget.homeBuilder?.call(context, _homeViewModel) ??
                  _DestinationFrame(title: l10n.appTitle),
              widget.transactionsBuilder?.call(
                    context,
                    _transactionsViewModel,
                  ) ??
                  _DestinationFrame(title: l10n.navigationTransactions),
            ],
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: AppShapes.hairlineWidth,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.navigationHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: l10n.navigationTransactions,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: MergeSemantics(
          child: Semantics(
            label: l10n.addExpenseSemanticLabel,
            child: FloatingActionButton.extended(
              onPressed: _openAddExpense,
              icon: const Icon(Icons.add),
              label: ExcludeSemantics(child: Text(l10n.addExpenseAction)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddExpenseRoute extends StatefulWidget {
  const _AddExpenseRoute({
    required this.clock,
    required this.repository,
    required this.builder,
  });

  final AppClock clock;
  final ExpenseRepository repository;
  final AddExpenseBuilder? builder;

  @override
  State<_AddExpenseRoute> createState() => _AddExpenseRouteState();
}

class _AddExpenseRouteState extends State<_AddExpenseRoute> {
  late final ExpenseFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExpenseFormViewModel(widget.repository, widget.clock);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder?.call(context, _viewModel) ??
        _DestinationFrame(title: AppLocalizations.of(context)!.addExpenseTitle);
  }
}

// P3-003/P3-008 and P3-005 onward supply the actual screen contents.
class _DestinationFrame extends StatelessWidget {
  const _DestinationFrame({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SafeArea(child: SizedBox.expand()),
    );
  }
}
