import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../services/projection_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';

class CategoryDonutChart extends StatelessWidget {
  final List<CategorySpending> data;
  final bool isDark;

  const CategoryDonutChart({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = data.where((e) => e.spentCents > 0).toList();
    if (filtered.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text('Keine Ausgaben vorhanden', style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted))),
      );
    }
    final total = filtered.fold<int>(0, (sum, e) => sum + e.spentCents);
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: filtered.map((e) => PieChartSectionData(
                  value: e.spentCents.toDouble(),
                  color: e.category.color,
                  radius: 28,
                  title: '${(e.spentCents / total * 100).round()}%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filtered.take(6).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.category.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.category.label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary)),
                  const SizedBox(width: 4),
                  Text(CurrencyUtils.formatCents(e.spentCents), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

}
