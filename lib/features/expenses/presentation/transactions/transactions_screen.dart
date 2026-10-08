import 'dart:async';

import 'package:flutter/material.dart';

import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_state.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/widgets/expense_list_item.dart';

/// Presents the full transaction history with lazy rendering and state feedback.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.viewModel,
    required this.onAddExpense,
    this.onTapExpense,
    this.onEditExpense,
    this.onDeleteExpense,
    this.scrollController,
    this.isActive = true,
  });

  final TransactionsViewModel viewModel;
  final VoidCallback onAddExpense;
  final ValueChanged<Expense>? onTapExpense;
  final ValueChanged<Expense>? onEditExpense;
  final ValueChanged<Expense>? onDeleteExpense;
  final ScrollController? scrollController;
  final bool isActive;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  ScrollController? _internalScrollController;
  TransactionsState? _previousState;
  bool _hasRefreshFailure = false;
  bool _isFeedbackScheduled = false;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ??
      (_internalScrollController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _attachViewModel();
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      _previousState = null;
      _hasRefreshFailure = false;
      _attachViewModel();
    }
    _scheduleFeedback();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _internalScrollController?.dispose();
    super.dispose();
  }

  void _attachViewModel() {
    widget.viewModel.addListener(_onViewModelChanged);
    _onViewModelChanged();
    if (widget.viewModel.state is TransactionsInitial) {
      unawaited(widget.viewModel.load());
    }
  }

  void _onViewModelChanged() {
    final currentState = widget.viewModel.state;
    final previousState = _previousState;
    _previousState = currentState;

    if (previousState is TransactionsRefreshing &&
        currentState is TransactionsData) {
      _scrollToTop();
    }

    if (widget.viewModel.takeRefreshFailure() != null) {
      _hasRefreshFailure = true;
    }
    _scheduleFeedback();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _effectiveScrollController;
      if (controller.hasClients && controller.offset > 0) {
        controller.jumpTo(0.0);
      }
    });
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
          content: Text(l10n.transactionsRefreshFailure),
          action: SnackBarAction(label: l10n.retryAction, onPressed: _retry),
        ),
      );
    });
  }

  void _retry() => unawaited(widget.viewModel.load());

  Widget _buildContent(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return _buildEmpty();
    }
    return _buildList(expenses);
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      controller: _effectiveScrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _TransactionsMessage(
          icon: Icons.receipt_long_outlined,
          title: l10n.transactionsEmptyTitle,
          description: l10n.transactionsEmptyDescription,
          actionLabel: l10n.addExpenseTitle,
          onPressed: widget.onAddExpense,
        ),
      ],
    );
  }

  Widget _buildList(List<Expense> expenses) {
    return ListView.builder(
      controller: _effectiveScrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        AppSpacing.primaryButtonHeight + AppSpacing.sectionGap,
      ),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final item = ExpenseListItem(
          key: ValueKey(expense.id),
          expense: expense,
          onTap: widget.onTapExpense != null
              ? () => widget.onTapExpense!(expense)
              : null,
          onEdit: widget.onEditExpense != null
              ? () => widget.onEditExpense!(expense)
              : null,
          onDelete: widget.onDeleteExpense != null
              ? () => widget.onDeleteExpense!(expense)
              : null,
        );
        if (index == expenses.length - 1) {
          return item;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: item,
        );
      },
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _TransactionsMessage(
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
        title: Text(AppLocalizations.of(context)!.transactionsTitle),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, child) => switch (widget.viewModel.state) {
            TransactionsInitial() || TransactionsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TransactionsData(:final expenses) => _buildContent(expenses),
            TransactionsRefreshing(:final expenses) => _buildContent(expenses),
            TransactionsError() => _buildError(),
          },
        ),
      ),
    );
  }
}

class _TransactionsMessage extends StatelessWidget {
  const _TransactionsMessage({
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
