import '../models/finance_models.dart';

class MonthProjection {
  final DateTime month;
  final int openingBalanceCents;
  final int incomeCents;
  final int fixedExpensesCents;
  final int variableExpensesCents;
  final int plannedEntriesCents;
  final int tripFundingCents;
  final int closingBalanceCents;

  const MonthProjection({
    required this.month,
    required this.openingBalanceCents,
    required this.incomeCents,
    required this.fixedExpensesCents,
    required this.variableExpensesCents,
    required this.plannedEntriesCents,
    required this.tripFundingCents,
    required this.closingBalanceCents,
  });
}

class TripForecast {
  final TripPlan trip;
  final int projectedBalanceCents;
  final int requiredMonthlySavingCents;
  final int availableOnTripCents;
  final bool isOnTrack;

  const TripForecast({
    required this.trip,
    required this.projectedBalanceCents,
    required this.requiredMonthlySavingCents,
    required this.availableOnTripCents,
    required this.isOnTrack,
  });
}

class MonthBudgetSnapshot {
  final DateTime month;
  final int projectedOpeningBalanceCents;
  final int incomeCents;
  final int fixedExpensesCents;
  final int variableExpensesCents;
  final int plannedEntriesCents;
  final int plannedPurchasesCents;
  final int plannedTripCostsCents;
  final int projectedClosingBalanceCents;
  final int freeAfterPlansCents;

  const MonthBudgetSnapshot({
    required this.month,
    required this.projectedOpeningBalanceCents,
    required this.incomeCents,
    required this.fixedExpensesCents,
    required this.variableExpensesCents,
    required this.plannedEntriesCents,
    required this.plannedPurchasesCents,
    required this.plannedTripCostsCents,
    required this.projectedClosingBalanceCents,
    required this.freeAfterPlansCents,
  });
}

class ProjectionService {
  static MonthBudgetSnapshot monthSnapshot(
    FinancialProfile profile,
    DateTime month, {
    ForecastScenario scenario = ForecastScenario.realistic,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final projections = project(profile, until: normalizedMonth, scenario: scenario);
    final projection = projections.isEmpty ? null : projections.last;
    final plannedTripCosts = _tripCostsForMonth(profile, normalizedMonth);
    final tripCostsBeforeMonth = _tripCostsUntil(profile, normalizedMonth);
    final projectedClosing = (projection?.closingBalanceCents ?? profile.currentBalanceCents) - tripCostsBeforeMonth;
    final plannedEntries = _plannedEntriesForMonth(profile, normalizedMonth);
    final plannedPurchases = -_plannedPurchasesForMonth(profile, normalizedMonth);
    final income = _scenarioIncome(profile.monthlyIncomeCents, scenario);
    final fixed = _scenarioExpense(profile.monthlyFixedExpensesCents, scenario);
    final variable = _scenarioExpense(profile.monthlyVariableBudgetCents, scenario);
    final freeAfterPlans = projectedClosing -
        profile.safetyReserveCents -
        profile.reservedTripCents -
        profile.reservedGoalCents -
        profile.reservedPurchaseCents;
    return MonthBudgetSnapshot(
      month: normalizedMonth,
      projectedOpeningBalanceCents: projection?.openingBalanceCents ?? profile.currentBalanceCents,
      incomeCents: income,
      fixedExpensesCents: fixed,
      variableExpensesCents: variable,
      plannedEntriesCents: plannedEntries,
      plannedPurchasesCents: plannedPurchases,
      plannedTripCostsCents: plannedTripCosts,
      projectedClosingBalanceCents: projectedClosing,
      freeAfterPlansCents: freeAfterPlans,
    );
  }

  static List<MonthProjection> project(
    FinancialProfile profile, {
    required DateTime until,
    ForecastScenario scenario = ForecastScenario.realistic,
  }) {
    final result = <MonthProjection>[];
    var balance = profile.currentBalanceCents;
    final firstMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final lastMonth = DateTime(until.year, until.month);
    var month = firstMonth;

    while (!month.isAfter(lastMonth)) {
      final opening = balance;
      final income = _scenarioIncome(profile.monthlyIncomeCents, scenario);
      final fixed = _scenarioExpense(profile.monthlyFixedExpensesCents, scenario);
      final variable = _scenarioExpense(profile.monthlyVariableBudgetCents, scenario);
      final plannedEntries = _plannedEntriesForMonth(profile, month) +
          _plannedPurchasesForMonth(profile, month);
      final tripFunding = _monthlyTripFunding(profile, month);
      // The trip funding is shown as an allocation, not subtracted twice from
      // the cash balance. The trip cost is deducted once at its payment date
      // in the forecast result.
      balance += income - fixed - variable + plannedEntries;
      result.add(MonthProjection(
        month: month,
        openingBalanceCents: opening,
        incomeCents: income,
        fixedExpensesCents: fixed,
        variableExpensesCents: variable,
        plannedEntriesCents: plannedEntries,
        tripFundingCents: tripFunding,
        closingBalanceCents: balance,
      ));
      month = DateTime(month.year, month.month + 1);
    }
    return result;
  }

  static TripForecast forecastTrip(
    FinancialProfile profile,
    TripPlan trip, {
    ForecastScenario scenario = ForecastScenario.realistic,
  }) {
    final months = _monthsUntil(trip.startsOn);
    final projection = project(profile, until: trip.startsOn, scenario: scenario);
    final projected = projection.isEmpty
        ? profile.currentBalanceCents
        : projection.last.closingBalanceCents;
    final otherGoalReserve = profile.goals.fold<int>(0, (sum, goal) => sum + goal.remainingCents);
    // Planned purchases dated before the target month are already included in
    // the projected balance and must not be deducted a second time here.
    final required = ((trip.remainingCostCents + profile.safetyReserveCents + otherGoalReserve -
                projected) /
            (months == 0 ? 1 : months))
        .ceil()
        .clamp(0, 1000000000)
        .toInt();
    final available = projected -
        profile.safetyReserveCents -
        trip.remainingCostCents -
        otherGoalReserve;
    return TripForecast(
      trip: trip,
      projectedBalanceCents: projected,
      requiredMonthlySavingCents: required,
      availableOnTripCents: available,
      isOnTrack: available >= 0,
    );
  }

  static int _monthlyTripFunding(FinancialProfile profile, DateTime month) {
    return profile.trips
        .where((trip) => trip.startsOn.isAfter(month))
        .fold<int>(0, (sum, trip) {
      final months = _monthsUntil(trip.startsOn);
      return sum + (trip.remainingCostCents / (months == 0 ? 1 : months)).ceil();
    });
  }

  static int _plannedEntriesForMonth(FinancialProfile profile, DateTime month) {
    return profile.entries
        .where((entry) => !entry.isConfirmed && entry.date.year == month.year && entry.date.month == month.month)
        .fold<int>(0, (sum, entry) => sum + entry.signedAmountCents);
  }

  static int _plannedPurchasesForMonth(FinancialProfile profile, DateTime month) {
    return profile.plannedPurchases
        .where((purchase) => !purchase.isPurchased && purchase.desiredDate.year == month.year && purchase.desiredDate.month == month.month)
        .fold<int>(0, (sum, purchase) => sum - purchase.amountCents);
  }

  static int _tripCostsUntil(FinancialProfile profile, DateTime month) {
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month);
    final end = DateTime(month.year, month.month);
    var total = 0;
    while (!cursor.isAfter(end)) {
      total += _tripCostsForMonth(profile, cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return total;
  }

  static int _tripCostsForMonth(FinancialProfile profile, DateTime month) {
    var total = 0;
    for (final trip in profile.trips) {
      if (trip.startsOn.year == month.year && trip.startsOn.month == month.month) {
        total += trip.fixedCostsCents + trip.bufferCents;
      }
      for (final segment in trip.segments) {
        if (segment.startsOn.year == month.year && segment.startsOn.month == month.month) {
          if (!segment.accommodationPaid) total += segment.accommodationCostCents;
          total += segment.transportCostCents + segment.otherCostCents;
        }
        total += _dailyCostInMonth(segment.startsOn, segment.endsOn, segment.dailyFoodBudgetCents, month);
      }
      if (trip.segments.isEmpty) {
        total += _dailyCostInMonth(trip.startsOn, trip.endsOn, trip.dailyBudgetCents, month);
      }
      for (final expense in trip.expenses) {
        if (!expense.isPaid && expense.date.year == month.year && expense.date.month == month.month) {
          total += expense.amountCents;
        }
      }
    }
    return total;
  }

  static int _dailyCostInMonth(DateTime startsOn, DateTime endsOn, int dailyCents, DateTime month) {
    final monthStart = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final start = startsOn.isAfter(monthStart) ? startsOn : monthStart;
    final end = endsOn.isBefore(nextMonth) ? endsOn : nextMonth;
    final days = end.difference(start).inDays.clamp(0, 366).toInt();
    return days * dailyCents;
  }

  static int _monthsUntil(DateTime date) {
    final now = DateTime.now();
    final value = (date.year - now.year) * 12 + date.month - now.month;
    return value.clamp(0, 120).toInt();
  }

  static int _scenarioIncome(int value, ForecastScenario scenario) {
    if (scenario == ForecastScenario.cautious) return (value * .9).round();
    if (scenario == ForecastScenario.optimistic) return (value * 1.05).round();
    return value;
  }

  static int _scenarioExpense(int value, ForecastScenario scenario) {
    if (scenario == ForecastScenario.cautious) return (value * 1.15).round();
    if (scenario == ForecastScenario.optimistic) return (value * .9).round();
    return value;
  }
}
