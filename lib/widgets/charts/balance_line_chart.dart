import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/projection_service.dart';
import '../../utils/app_theme.dart';

class BalanceLineChart extends StatelessWidget {
  final FinancialProfile profile;
  final bool isDark;

  const BalanceLineChart({
    super.key,
    required this.profile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + 11);
    final projections = ProjectionService.project(profile, until: target);
    if (projections.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text('Keine Daten für Prognose', style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted))),
      );
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < projections.length; i++) {
      spots.add(FlSpot(i.toDouble(), projections[i].closingBalanceCents / 100));
    }
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final bottomPadding = range * 0.1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _interval(maxY - minY),
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= projections.length) return const SizedBox();
                  if (i % 2 != 0) return const SizedBox();
                  final m = projections[i].month;
                  final labels = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[m.month - 1], style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: .1),
              ),
            ),
          ],
          minY: (minY - bottomPadding).clamp(0, double.infinity),
        ),
      ),
    );
  }

  double _interval(double range) {
    if (range <= 0) return 1000;
    final raw = range / 4;
    if (raw <= 100) return 100;
    if (raw <= 500) return 500;
    if (raw <= 1000) return 1000;
    if (raw <= 5000) return 5000;
    if (raw <= 10000) return 10000;
    return (raw / 10000).ceil() * 10000;
  }
}
