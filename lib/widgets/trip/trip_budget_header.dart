import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/squircle_container.dart';
import 'trip_cost_breakdown.dart';

class TripBudgetHeader extends StatelessWidget {
  final TripPlan trip;
  final bool isDark;

  const TripBudgetHeader({
    super.key,
    required this.trip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final overLimit = trip.isOverBudget;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final shadowColor = isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final fundingProgress = trip.totalCostCents <= 0 ? 0.0 : (trip.paidCents / trip.totalCostCents).clamp(0.0, 1.0).toDouble();

    return SquircleContainer(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      backgroundColor: surfaceColor,
      boxShadow: [BoxShadow(color: shadowColor, blurRadius: 18, offset: const Offset(0, 7))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text('${trip.destination} · ${trip.days} Tage', style: TextStyle(fontSize: 13, color: mutedColor)),
          ])),
          _statusPill(overLimit ? 'Über Budget' : 'Im Budget', !overLimit),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _metric('Geplant', CurrencyUtils.formatCents(trip.totalCostCents), overLimit ? AppColors.red : AppColors.green, mutedColor),
          const SizedBox(width: 20),
          if (trip.budgetLimitCents > 0) _metric('Limit', CurrencyUtils.formatCents(trip.budgetLimitCents), AppColors.primary, mutedColor),
          if (trip.budgetLimitCents > 0) const SizedBox(width: 20),
          _metric('Offen', CurrencyUtils.formatCents(trip.remainingCostCents), overLimit ? AppColors.red : AppColors.green, mutedColor),
          const SizedBox(width: 20),
          _metric('Bezahlt', CurrencyUtils.formatCents(trip.paidCents), AppColors.green, mutedColor),
        ]),
        if (trip.budgetLimitCents > 0) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (trip.totalCostCents / trip.budgetLimitCents).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: dividerColor,
              color: overLimit ? AppColors.red : AppColors.primary,
            ),
          ),
        ],
        const SizedBox(height: 18),
        TripCostBreakdown(trip: trip, isDark: isDark),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fundingProgress,
            minHeight: 6,
            backgroundColor: dividerColor,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 6),
        Text('${(fundingProgress * 100).round()}% finanziert', style: TextStyle(fontSize: 12, color: mutedColor)),
      ]),
    );
  }

  Widget _metric(String label, String value, Color color, Color mutedColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: mutedColor)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    ],
  );

  Widget _statusPill(String label, bool positive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (positive ? AppColors.green : AppColors.red).withValues(alpha: .11),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(positive ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, size: 14, color: positive ? AppColors.green : AppColors.red),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: positive ? AppColors.green : AppColors.red)),
    ]),
  );


}
