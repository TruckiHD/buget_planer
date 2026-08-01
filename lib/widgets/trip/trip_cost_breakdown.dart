import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';

class TripCostBreakdown extends StatelessWidget {
  final TripPlan trip;
  final bool isDark;

  const TripCostBreakdown({
    super.key,
    required this.trip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = trip.totalCostCents;
    if (total <= 0) return const SizedBox.shrink();

    final items = _costItems();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...items.map((item) => _costBar(item, total)),
    ]);
  }

  List<_CostItem> _costItems() {
    final items = <_CostItem>[];
    if (trip.segmentAccommodationCents > 0) {
      items.add(_CostItem('Hotel', trip.segmentAccommodationCents, AppColors.primary));
    }
    if (trip.segmentFoodCents > 0) {
      items.add(_CostItem('Essen', trip.segmentFoodCents, AppColors.green));
    }
    final transportTotal = trip.segmentTransportCents + trip.transportCents;
    if (transportTotal > 0) {
      items.add(_CostItem('Transport', transportTotal, AppColors.amber));
    }
    if (trip.segmentOtherCents > 0) {
      items.add(_CostItem('Sonstiges', trip.segmentOtherCents, const Color(0xFF00B8D9)));
    }
    if (trip.expenseCents > 0) {
      items.add(_CostItem('Expenses', trip.expenseCents, AppColors.pink));
    }
    if (trip.fixedCostsCents > 0) {
      items.add(_CostItem('Fixkosten', trip.fixedCostsCents, const Color(0xFF7B61FF)));
    }
    if (trip.bufferCents > 0) {
      items.add(_CostItem('Puffer', trip.bufferCents, isDark ? AppColors.darkMuted : AppColors.lightMuted));
    }
    return items;
  }

  Widget _costBar(_CostItem item, int total) {
    final fraction = total > 0 ? item.cents / total : 0.0;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 72, child: Text(item.label, style: TextStyle(fontSize: 12, color: mutedColor))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              color: item.color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            _money(item.cents),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: item.color),
            textAlign: TextAlign.right,
          ),
        ),
      ]),
    );
  }

  String _money(int cents) => '${(cents / 100).toStringAsFixed(0)} €';
}

class _CostItem {
  final String label;
  final int cents;
  final Color color;
  const _CostItem(this.label, this.cents, this.color);
}
