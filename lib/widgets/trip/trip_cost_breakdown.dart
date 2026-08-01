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
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stackedBar(items, total),
      const SizedBox(height: 10),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        children: items.map((item) => _chip(item, total, mutedColor)).toList(),
      ),
    ]);
  }

  Widget _stackedBar(List<_CostItem> items, int total) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: items.map((item) {
            final fraction = (item.cents / total).clamp(0.0, 1.0).toDouble();
            return Expanded(
              flex: (fraction * 1000).round().clamp(1, 1000),
              child: Container(color: item.color),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _chip(_CostItem item, int total, Color mutedColor) {
    final percent = (item.cents / total * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(item.label, style: TextStyle(fontSize: 12, color: mutedColor)),
        const SizedBox(width: 4),
        Text(_money(item.cents), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.color)),
        const SizedBox(width: 2),
        Text('($percent%)', style: TextStyle(fontSize: 11, color: mutedColor)),
      ],
    );
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
      items.add(_CostItem('Kosten', trip.expenseCents, AppColors.pink));
    }
    if (trip.fixedCostsCents > 0) {
      items.add(_CostItem('Fixkosten', trip.fixedCostsCents, const Color(0xFF7B61FF)));
    }
    if (trip.bufferCents > 0) {
      items.add(_CostItem('Puffer', trip.bufferCents, isDark ? AppColors.darkMuted : AppColors.lightMuted));
    }
    return items;
  }

  String _money(int cents) => '${(cents / 100).toStringAsFixed(0)} €';
}

class _CostItem {
  final String label;
  final int cents;
  final Color color;
  const _CostItem(this.label, this.cents, this.color);
}
