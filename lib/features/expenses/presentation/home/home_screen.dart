import 'dart:async';

import 'package:flutter/material.dart';

import 'package:expensetracker/core/formatting/id_date_formatter.dart';
import 'package:expensetracker/core/formatting/idr_formatter.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_state.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/home/monthly_summary_card.dart';

/// Presents the monthly summary, latest expenses, and Home read states.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.onViewAll,
    required this.onAddExpense,
    this.isActive = true,
  });

  final HomeViewModel viewModel;
  final VoidCallback onViewAll;
  final VoidCallback onAddExpense;
  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IdrFormatter _amountFormatter = IdrFormatter();
  final IdDateFormatter _dateFormatter = IdDateFormatter();
  HomeSummary? _summary;
  String _monthLabel = '';
  String _formattedTotal = '';
  List<_RecentExpensePresentation> _recentExpenses =
      const <_RecentExpensePresentation>[];
  bool _hasRefreshFailure = false;
  bool _isFeedbackScheduled = false;

  @override
  void initState() {
    super.initState();
    _attachViewModel();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      _summary = null;
      _hasRefreshFailure = false;
      _attachViewModel();
    }
    _scheduleFeedback();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _attachViewModel() {
    widget.viewModel.addListener(_onViewModelChanged);
    _onViewModelChanged();
    if (widget.viewModel.state is HomeInitial) {
      unawaited(widget.viewModel.load());
    }
  }

  void _onViewModelChanged() {
    final summary = switch (widget.viewModel.state) {
      HomeData(:final summary) || HomeRefreshing(:final summary) => summary,
      _ => null,
    };
    // Cache formatting outside build; refresh keeps the same visible snapshot.
    if (summary != null && !identical(summary, _summary)) {
      _summary = summary;
      _monthLabel = _dateFormatter.formatMonthHeader(summary.month);
      _formattedTotal = _amountFormatter.formatDisplay(summary.monthlyTotal);
      _recentExpenses = summary.latestExpenses
          .take(5)
          .map((expense) {
            return _RecentExpensePresentation(
              expense,
              _amountFormatter.formatDisplay(expense.amount),
              _dateFormatter.formatListItem(expense.transactionDate),
            );
          })
          .toList(growable: false);
    }
    if (widget.viewModel.takeRefreshFailure() != null) {
      _hasRefreshFailure = true;
    }
    _scheduleFeedback();
  }

  void _scheduleFeedback() {
    if (!_hasRefreshFailure || !widget.isActive || _isFeedbackScheduled) return;
    _isFeedbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFeedbackScheduled = false;
      if (!mounted || !widget.isActive || !_hasRefreshFailure) return;
      _hasRefreshFailure = false;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.homeRefreshFailure),
          action: SnackBarAction(label: l10n.retryAction, onPressed: _retry),
        ),
      );
    });
  }

  void _retry() => unawaited(widget.viewModel.load());

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        AppSpacing.primaryButtonHeight + AppSpacing.sectionGap,
      ),
      children: [
        MonthlySummaryCard(
          monthLabel: _monthLabel,
          formattedTotal: _formattedTotal,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.homeRecentTransactions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: widget.onViewAll,
              child: Text(l10n.homeViewAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_recentExpenses.isEmpty)
          _HomeMessage(
            icon: Icons.receipt_long_outlined,
            title: l10n.homeEmptyTitle,
            description: l10n.homeEmptyDescription,
            actionLabel: l10n.addExpenseTitle,
            onPressed: widget.onAddExpense,
          )
        else
          for (final item in _recentExpenses) ...[
            _RecentExpenseCard(key: ValueKey(item.expense.id), item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _HomeMessage(
          icon: Icons.error_outline,
          title: l10n.readErrorTitle,
          description: l10n.readErrorDescription,
          actionLabel: l10n.retryAction,
          onPressed: _retry,
          isError: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.homeTitle),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, child) => switch (widget.viewModel.state) {
            HomeInitial() ||
            HomeLoading() => const Center(child: CircularProgressIndicator()),
            HomeData() || HomeRefreshing() => _buildContent(),
            HomeError() => _buildError(),
          },
        ),
      ),
    );
  }
}

class _RecentExpensePresentation {
  const _RecentExpensePresentation(this.expense, this.amount, this.date);

  final Expense expense;
  final String amount;
  final String date;
}

// Read-only preview for Home; shared item actions belong to P3-004.
class _RecentExpenseCard extends StatelessWidget {
  const _RecentExpenseCard({super.key, required this.item});

  final _RecentExpensePresentation item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CategoryColors>()!;
    final category = item.expense.category;
    final l10n = AppLocalizations.of(context)!;
    final label = switch (category) {
      ExpenseCategory.food => l10n.categoryFood,
      ExpenseCategory.transportation => l10n.categoryTransportation,
      ExpenseCategory.shopping => l10n.categoryShopping,
      ExpenseCategory.bills => l10n.categoryBills,
      ExpenseCategory.other => l10n.categoryOther,
    };
    final icon = switch (category) {
      ExpenseCategory.food => Icons.restaurant,
      ExpenseCategory.transportation => Icons.directions_car,
      ExpenseCategory.shopping => Icons.shopping_bag,
      ExpenseCategory.bills => Icons.receipt_long,
      ExpenseCategory.other => Icons.more_horiz,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: AppSpacing.categoryCircle,
                height: AppSpacing.categoryCircle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.backgroundFor(category),
                ),
                child: Icon(icon, color: colors.foregroundFor(category)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(label, style: theme.textTheme.titleSmall),
                        Text(item.amount, style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(item.date, style: theme.textTheme.bodyMedium),
                  if (item.expense.note case final note?) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isError ? theme.colorScheme.onErrorContainer : null;
    return Card(
      color: isError ? theme.colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.summaryPadding),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: AppSpacing.touchTarget,
                color: foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: foreground),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
