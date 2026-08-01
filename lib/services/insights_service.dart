import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/projection_service.dart';
import '../utils/app_theme.dart';

enum InsightType { warning, success, info, tip }

class Insight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final InsightType type;

  const Insight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class InsightsService {
  static List<Insight> generateInsights(FinancialProfile profile) {
    final insights = <Insight>[];

    _checkSavingsRate(profile, insights);
    _checkCategoryBudgets(profile, insights);
    _checkTripStatus(profile, insights);
    _checkSavingsGoals(profile, insights);
    _checkBalanceTrend(profile, insights);
    _checkMonthlySurplus(profile, insights);
    _checkMonthlyComparison(profile, insights);

    insights.sort((a, b) {
      const order = {InsightType.warning: 0, InsightType.info: 1, InsightType.tip: 2, InsightType.success: 3};
      return (order[a.type] ?? 4).compareTo(order[b.type] ?? 4);
    });

    return insights.take(6).toList();
  }

  static void _checkSavingsRate(FinancialProfile profile, List<Insight> insights) {
    if (profile.monthlyIncomeCents <= 0) return;
    final review = ProjectionService.yearReview(profile);
    final rate = review.savingRatePercent / 100;
    if (rate >= 0.3) {
      insights.add(Insight(
        title: 'Ausgezeichnete Sparquote!',
        description: 'Du sparst ${(rate * 100).round()}% deines Einkommens. Weiter so!',
        icon: Icons.savings_rounded,
        color: AppColors.green,
        type: InsightType.success,
      ));
    } else if (rate >= 0.1) {
      final monthlySaving = review.totalIncomeCents > 0
          ? ((review.totalIncomeCents - review.totalExpensesCents) / 12).round()
          : 0;
      insights.add(Insight(
        title: 'Solide Sparquote',
        description: 'Du sparst ${(rate * 100).round()}% deines Einkommens. ${_money(monthlySaving)} bleiben monatlich übrig.',
        icon: Icons.trending_up_rounded,
        color: AppColors.primary,
        type: InsightType.info,
      ));
    } else if (rate > 0) {
      insights.add(Insight(
        title: 'Sparquote ausbaufähig',
        description: 'Du sparst nur ${(rate * 100).round()}%. Versuche, Ausgaben in nicht-essenziellen Kategorien zu reduzieren.',
        icon: Icons.info_outline_rounded,
        color: AppColors.amber,
        type: InsightType.tip,
      ));
    } else {
      final deficit = review.totalExpensesCents - review.totalIncomeCents;
      insights.add(Insight(
        title: 'Ausgaben übersteigen Einnahmen',
        description: 'Du gibst ${_money(deficit)} mehr aus, als du einnimmst. Zeit, Ausgaben zu priorisieren!',
        icon: Icons.warning_amber_rounded,
        color: AppColors.red,
        type: InsightType.warning,
      ));
    }
  }

  static void _checkCategoryBudgets(FinancialProfile profile, List<Insight> insights) {
    final status = ProjectionService.categoryBudgetStatus(profile, DateTime.now());
    for (final cat in status) {
      if (cat.isOverBudget) {
        insights.add(Insight(
          title: '${cat.category.label}-Budget überschritten',
          description: 'Du hast ${_money(cat.spentCents)} von ${_money(cat.budgetLimitCents!)} ausgegeben.',
          icon: cat.category.icon,
          color: AppColors.red,
          type: InsightType.warning,
        ));
      } else if (cat.isNearBudget) {
        insights.add(Insight(
          title: '${cat.category.label}-Budget bald erreicht',
          description: 'Du hast bereits ${(cat.budgetUsage * 100).round()}% deines Budgets verbraucht.',
          icon: cat.category.icon,
          color: AppColors.amber,
          type: InsightType.info,
        ));
      }
    }
  }

  static void _checkTripStatus(FinancialProfile profile, List<Insight> insights) {
    for (final trip in profile.trips) {
      final daysUntil = trip.startsOn.difference(DateTime.now()).inDays;
      if (daysUntil <= 0) continue;
      final forecast = ProjectionService.forecastTrip(profile, trip);
      if (!forecast.isOnTrack) {
        insights.add(Insight(
          title: '"${trip.name}" braucht mehr Sparen',
          description: 'Du brauchst ${_money(forecast.requiredMonthlySavingCents)} pro Monat, um genug zu haben.',
          icon: Icons.flight_takeoff_rounded,
          color: AppColors.amber,
          type: InsightType.warning,
        ));
      } else if (daysUntil <= 30) {
        insights.add(Insight(
          title: '"${trip.name}" startet in $daysUntil Tagen!',
          description: 'Alles auf Kurs. Du hast ${_money(forecast.availableOnTripCents)} Puffer.',
          icon: Icons.flight_takeoff_rounded,
          color: AppColors.green,
          type: InsightType.success,
        ));
      }
    }
  }

  static void _checkSavingsGoals(FinancialProfile profile, List<Insight> insights) {
    for (final goal in profile.goals) {
      if (goal.progress >= 1.0) {
        insights.add(Insight(
          title: '"${goal.name}" erreicht!',
          description: 'Herzlichen Glückwunsch! Du hast dein Sparziel erreicht.',
          icon: Icons.emoji_events_rounded,
          color: AppColors.amber,
          type: InsightType.success,
        ));
      } else if (goal.progress >= 0.8) {
        insights.add(Insight(
          title: '"${goal.name}" fast geschafft!',
          description: '${(goal.progress * 100).round()}% erreicht. Noch ${_money(goal.remainingCents)} bis zum Ziel.',
          icon: Icons.flag_rounded,
          color: AppColors.green,
          type: InsightType.success,
        ));
      } else {
        final monthsLeft = goal.deadline.difference(DateTime.now()).inDays / 30;
        if (monthsLeft > 0) {
          final needed = (goal.remainingCents / monthsLeft).ceil();
          if (needed > goal.monthlyAllocationCents) {
            insights.add(Insight(
              title: '"${goal.name}" braucht mehr Tempo',
              description: 'Für das Ziel bräuchtest du ${_money(needed)}/Monat, aber du zahlst nur ${_money(goal.monthlyAllocationCents)}.',
              icon: Icons.flag_rounded,
              color: AppColors.amber,
              type: InsightType.tip,
            ));
          }
        }
      }
    }
  }

  static void _checkBalanceTrend(FinancialProfile profile, List<Insight> insights) {
    final now = DateTime.now();
    final in3Months = DateTime(now.year, now.month + 3);
    final projections = ProjectionService.project(profile, until: in3Months);
    if (projections.length >= 3) {
      final future = projections.last.closingBalanceCents;
      if (future < profile.safetyReserveCents) {
        insights.add(Insight(
          title: 'Reserve in 3 Monaten knapp',
          description: 'Dein Guthaben könnte unter die Sicherheitsreserve fallen. Prüfe deine Ausgaben.',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.red,
          type: InsightType.warning,
        ));
      }
    }
  }

  static void _checkMonthlySurplus(FinancialProfile profile, List<Insight> insights) {
    final surplus = profile.monthlySurplusCents;
    if (surplus > 0 && profile.trips.isNotEmpty) {
      final trip = profile.trips.first;
      final monthsUntilTrip = trip.startsOn.difference(DateTime.now()).inDays / 30;
      if (monthsUntilTrip > 0) {
        final canSave = (surplus * monthsUntilTrip).round();
        final needed = trip.remainingCostCents;
        if (canSave >= needed) {
          insights.add(Insight(
            title: 'Reise locker finanzierbar',
            description: 'Bei deinem aktuellen Überschuss kannst du "${trip.name}" problemlos bezahlen.',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.green,
            type: InsightType.success,
          ));
        }
      }
    }
  }

  static void _checkMonthlyComparison(FinancialProfile profile, List<Insight> insights) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final currentSpending = ProjectionService.categorySpending(profile, currentMonth);
    final lastSpending = ProjectionService.categorySpending(profile, lastMonth);
    final currentTotal = currentSpending.values.fold<int>(0, (sum, v) => sum + v);
    final lastTotal = lastSpending.values.fold<int>(0, (sum, v) => sum + v);
    if (lastTotal <= 0 || currentTotal <= 0) return;
    final diff = currentTotal - lastTotal;
    final percent = (diff / lastTotal * 100).round();
    if (percent > 20) {
      insights.add(Insight(
        title: 'Ausgaben gestiegen',
        description: 'Du gibst diesen Monat ${_money(diff)} mehr aus als letzten Monat (+$percent%).',
        icon: Icons.trending_up_rounded,
        color: AppColors.amber,
        type: InsightType.info,
      ));
    } else if (percent < -20) {
      insights.add(Insight(
        title: 'Ausgaben gesunken',
        description: 'Du sparst diesen Monat ${_money(-diff)} im Vergleich zu letzten Monat (-${percent.abs()}%).',
        icon: Icons.trending_down_rounded,
        color: AppColors.green,
        type: InsightType.success,
      ));
    }
  }

  static String _money(int cents) => '${cents < 0 ? '-' : ''}${(cents.abs() / 100).toStringAsFixed(0)} €';
}
