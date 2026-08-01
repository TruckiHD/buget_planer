import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';
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
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return SquircleContainer(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      backgroundColor: surfaceColor,
      boxShadow: [BoxShadow(color: shadowColor, blurRadius: 18, offset: const Offset(0, 7))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('${trip.destination} · ${trip.days} Tage', style: Theme.of(context).textTheme.bodyMedium),
          ])),
          _statusPill(overLimit ? 'Über Budget' : 'Im Budget', !overLimit),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _metric('Budgetlimit', trip.budgetLimitCents <= 0 ? 'Kein Limit' : _money(trip.budgetLimitCents), AppColors.primary, mutedColor)),
          Expanded(child: _metric('Geplant', _money(trip.totalCostCents), overLimit ? AppColors.red : AppColors.green, mutedColor)),
          Expanded(child: _metric('Übrig', trip.budgetLimitCents <= 0 ? '–' : _money(trip.budgetRemainingCents), overLimit ? AppColors.red : AppColors.green, mutedColor)),
        ]),
        const SizedBox(height: 16),
        if (trip.budgetLimitCents > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (trip.totalCostCents / trip.budgetLimitCents).clamp(0.0, 1.0).toDouble(),
              minHeight: 9,
              backgroundColor: dividerColor,
              color: overLimit ? AppColors.red : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        TripCostBreakdown(trip: trip, isDark: isDark),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.info_outline_rounded, size: 16, color: mutedColor),
          const SizedBox(width: 6),
          Expanded(child: Text('Noch offen: ${_money(trip.remainingCostCents)} · Reserviert: ${_money(trip.reservedCents)}', style: TextStyle(fontSize: 12, color: mutedColor))),
        ]),
      ]),
    );
  }

  Widget _metric(String label, String value, Color color, Color mutedColor) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: mutedColor)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
    ]),
  );

  Widget _statusPill(String label, bool positive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (positive ? AppColors.green : AppColors.red).withValues(alpha: .11),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: positive ? AppColors.green : AppColors.red)),
  );

  String _money(int cents) => '${cents < 0 ? '-' : ''}${(cents.abs() / 100).toStringAsFixed(0)} €';
}
