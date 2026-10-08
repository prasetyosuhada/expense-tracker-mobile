import 'package:flutter/material.dart';

import 'package:expensetracker/core/formatting/id_date_formatter.dart';
import 'package:expensetracker/core/formatting/idr_formatter.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';

/// Actions available in the transaction item popup menu.
enum ExpenseListItemAction { edit, delete }

/// Reusable transaction item displaying category icon, title, date, amount,
/// optional note, and an actions menu for edit and delete.
class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.amountFormatter,
    this.dateFormatter,
  });

  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final IdrFormatter? amountFormatter;
  final IdDateFormatter? dateFormatter;

  static final _defaultAmountFormatter = IdrFormatter();
  static final _defaultDateFormatter = IdDateFormatter();

  static IconData iconFor(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => Icons.restaurant,
    ExpenseCategory.transportation => Icons.directions_car,
    ExpenseCategory.shopping => Icons.shopping_bag,
    ExpenseCategory.bills => Icons.receipt_long,
    ExpenseCategory.other => Icons.more_horiz,
  };

  static String labelFor(AppLocalizations l10n, ExpenseCategory category) =>
      switch (category) {
        ExpenseCategory.food => l10n.categoryFood,
        ExpenseCategory.transportation => l10n.categoryTransportation,
        ExpenseCategory.shopping => l10n.categoryShopping,
        ExpenseCategory.bills => l10n.categoryBills,
        ExpenseCategory.other => l10n.categoryOther,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CategoryColors>() ?? CategoryColors.light;
    final l10n = AppLocalizations.of(context)!;
    final category = expense.category;
    final categoryLabel = labelFor(l10n, category);
    final categoryIcon = iconFor(category);
    final amountFmt = amountFormatter ?? _defaultAmountFormatter;
    final dateFmt = dateFormatter ?? _defaultDateFormatter;
    final formattedAmount = amountFmt.formatDisplay(expense.amount);
    final formattedDate = dateFmt.formatListItem(expense.transactionDate);
    final semanticMenuLabel = l10n.expenseActionMenuSemanticLabel(
      categoryLabel,
      formattedAmount,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.transparent,
        highlightColor: AppColors.surfaceActive,
        hoverColor: AppColors.transparent,
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
                  child: Icon(
                    categoryIcon,
                    color: colors.foregroundFor(category),
                    size: AppSpacing.iconSize,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScaler = MediaQuery.textScalerOf(context);
                        final namePainter = TextPainter(
                          text: TextSpan(
                            text: categoryLabel,
                            style: theme.textTheme.titleSmall,
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: textScaler,
                        )..layout();
                        final amountPainter = TextPainter(
                          text: TextSpan(
                            text: formattedAmount,
                            style: theme.textTheme.titleSmall,
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: textScaler,
                        )..layout();

                        final fitsOneLine =
                            (namePainter.width +
                                amountPainter.width +
                                AppSpacing.xs) <=
                            constraints.maxWidth;

                        namePainter.dispose();
                        amountPainter.dispose();

                        if (fitsOneLine) {
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  categoryLabel,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                formattedAmount,
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryLabel,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    formattedAmount,
                                    style: theme.textTheme.titleSmall,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(formattedDate, style: theme.textTheme.bodyMedium),
                    if (expense.note case final note?) ...[
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
              const SizedBox(width: AppSpacing.xs),
              MergeSemantics(
                child: Semantics(
                  button: true,
                  label: semanticMenuLabel,
                  child: PopupMenuButton<ExpenseListItemAction>(
                    tooltip: semanticMenuLabel,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert),
                    iconSize: AppSpacing.iconSize,
                    onSelected: (action) {
                      switch (action) {
                        case ExpenseListItemAction.edit:
                          onEdit?.call();
                        case ExpenseListItemAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<ExpenseListItemAction>(
                        value: ExpenseListItemAction.edit,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: AppSpacing.iconSize,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.editAction),
                          ],
                        ),
                      ),
                      PopupMenuItem<ExpenseListItemAction>(
                        value: ExpenseListItemAction.delete,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                              size: AppSpacing.iconSize,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.deleteAction,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
