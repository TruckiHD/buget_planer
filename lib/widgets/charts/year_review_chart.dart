import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../services/projection_service.dart';
import '../../utils/app_theme.dart';

class YearReviewChart extends StatelessWidget {
  final YearReview review;
  final bool isDark;

  const YearReviewChart({
    super.key,
    required this.review,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = review.monthlyData
        .map((m) => m.incomeCents > m.expensesCents ? m.incomeCents : m.expensesCents)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal / 100 * 1.1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                return BarTooltipItem(
                  '${isIncome ? "Einnahmen" : "Ausgaben"}\n${(rod.toY).round()} €',
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[value.toInt()], style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? (maxVal / 100 / 4).ceilToDouble().clamp(100, double.infinity) : 100,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              strokeWidth: 1,
            ),
          ),
          barGroups: review.monthlyData.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: m.incomeCents / 100,
                  color: AppColors.green,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: m.expensesCents / 100,
                  color: AppColors.red.withValues(alpha: .7),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
