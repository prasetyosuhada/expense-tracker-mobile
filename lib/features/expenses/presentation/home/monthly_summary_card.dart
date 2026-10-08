import 'package:flutter/material.dart';

import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';

/// Displays the formatted current-month total on the signature lime surface.
class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({
    super.key,
    required this.monthLabel,
    required this.formattedTotal,
  });

  final String monthLabel;
  final String formattedTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;
    return Card(
      color: theme.colorScheme.primary,
      shape: const RoundedRectangleBorder(borderRadius: AppShapes.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.summaryPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthLabel,
              style: theme.textTheme.titleMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.homeTotalLabel,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Wrap rather than clip or shrink below readable display sizing.
            Text(
              formattedTotal,
              style: theme.textTheme.displaySmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
