import '../models/finance_models.dart';

class CategorySpending {
  final ExpenseCategory category;
  final int spentCents;
  final int? budgetLimitCents;

  const CategorySpending({
    required this.category,
    required this.spentCents,
    this.budgetLimitCents,
  });

  double get budgetUsage =>
      budgetLimitCents == null || budgetLimitCents == 0
          ? 0.0
          : (spentCents / budgetLimitCents!).clamp(0.0, 2.0).toDouble();

  bool get isOverBudget =>
      budgetLimitCents != null && budgetLimitCents! > 0 && spentCents > budgetLimitCents!;

  bool get isNearBudget =>
      budgetLimitCents != null &&
      budgetLimitCents! > 0 &&
      spentCents > budgetLimitCents! * 0.8 &&
      spentCents <= budgetLimitCents!;
}

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
    final plannedEntries = _plannedEntriesForMonth(profile, normalizedMonth);
    final plannedPurchases = -_plannedPurchasesForMonth(profile, normalizedMonth);
    final income = _scenarioIncome(profile.monthlyIncomeCents, scenario);
    final fixed = _scenarioExpense(profile.monthlyFixedExpensesCents, scenario);
    final variable = _scenarioExpense(profile.monthlyVariableBudgetCents, scenario);
    final projectedClosing = projection?.closingBalanceCents ?? profile.currentBalanceCents;
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
    bool includeTripCosts = true,
    bool includeConfirmedEntries = true,
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
      final confirmedEntries = includeConfirmedEntries ? _confirmedEntriesForMonth(profile, month) : 0;
      final tripCosts = includeTripCosts ? _tripCostsForMonth(profile, month) : 0;
      final tripFunding = _monthlyTripFunding(profile, month);
      balance += income - fixed - variable + plannedEntries + confirmedEntries - tripCosts;
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
    final projection = project(profile, until: trip.startsOn, scenario: scenario, includeTripCosts: false);
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

  static int _confirmedEntriesForMonth(FinancialProfile profile, DateTime month) {
    return profile.entries
        .where((entry) => entry.isConfirmed && entry.date.year == month.year && entry.date.month == month.month)
        .fold<int>(0, (sum, entry) => sum + entry.signedAmountCents);
  }

  static int _plannedPurchasesForMonth(FinancialProfile profile, DateTime month) {
    return profile.plannedPurchases
        .where((purchase) => !purchase.isPurchased && purchase.desiredDate.year == month.year && purchase.desiredDate.month == month.month)
        .fold<int>(0, (sum, purchase) => sum - purchase.amountCents);
  }

  static int _tripCostsForMonth(FinancialProfile profile, DateTime month) {
    var total = 0;
    for (final trip in profile.trips) {
      if (trip.startsOn.year == month.year && trip.startsOn.month == month.month) {
        total += trip.fixedCostsCents + trip.bufferCents;
        total += trip.outboundTransportCents + trip.returnTransportCents;
        total += trip.rentalCarTotalCents;
        total += trip.travelPassCents;
      }
      for (final segment in trip.segments) {
        if (segment.startsOn.year == month.year && segment.startsOn.month == month.month) {
          if (!segment.accommodationPaid) total += segment.accommodationCostCents;
          total += segment.transportCostCents + segment.otherCostCents;
          total += segment.baseTransportCostCents;
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

  static Map<ExpenseCategory, int> categorySpending(
    FinancialProfile profile,
    DateTime month, {
    bool includePlanned = false,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final result = <ExpenseCategory, int>{};
    for (final cat in ExpenseCategory.values) {
      result[cat] = 0;
    }
    for (final entry in profile.entries) {
      if (entry.kind == TransactionKind.expense &&
          (includePlanned || entry.isConfirmed) &&
          entry.date.year == normalizedMonth.year &&
          entry.date.month == normalizedMonth.month) {
        final cat = entry.expenseCategory ?? ExpenseCategory.sonstiges;
        result[cat] = (result[cat] ?? 0) + entry.amountCents;
      }
    }
    for (final rec in profile.recurringTransactions) {
      if (rec.kind == TransactionKind.expense) {
        final cat = rec.expenseCategory ?? ExpenseCategory.sonstiges;
        result[cat] = (result[cat] ?? 0) + _monthlyEquivalent(rec);
      }
    }
    return result;
  }

  static List<CategorySpending> categoryBudgetStatus(
    FinancialProfile profile,
    DateTime month,
  ) {
    final spending = categorySpending(profile, month);
    return spending.entries.map((e) {
      final budget = profile.categoryBudgets
          .where((b) => b.category == e.key)
          .isEmpty ? null : profile.categoryBudgets.firstWhere((b) => b.category == e.key).monthlyLimitCents;
      return CategorySpending(
        category: e.key,
        spentCents: e.value,
        budgetLimitCents: budget,
      );
    }).toList()
      ..sort((a, b) => b.spentCents.compareTo(a.spentCents));
  }

  static int _monthlyEquivalent(RecurringTransaction item) {
    switch (item.frequency) {
      case TransactionFrequency.weekly:
        return (item.amountCents * 52 / 12).round();
      case TransactionFrequency.yearly:
        return (item.amountCents / 12).round();
      case TransactionFrequency.monthly:
        return item.amountCents;
      case TransactionFrequency.once:
        return 0;
    }
  }

  static YearReview yearReview(FinancialProfile profile, {int? year}) {
    final y = year ?? DateTime.now().year;
    final monthlyData = <MonthReview>[];
    var totalIncome = 0;
    var totalExpenses = 0;
    var bestSavingMonth = 0;
    var bestSaving = 0;

    for (var m = 1; m <= 12; m++) {
      final month = DateTime(y, m);
      final recurringIncome = profile.recurringTransactions
          .where((t) => t.kind == TransactionKind.income)
          .fold<int>(0, (sum, t) => sum + _monthlyEquivalent(t));
      final plannedIncome = profile.entries
          .where((e) => !e.isConfirmed && e.kind == TransactionKind.income && e.date.year == month.year && e.date.month == month.month)
          .fold<int>(0, (sum, e) => sum + e.amountCents);
      final income = recurringIncome + plannedIncome;
      
      final fixedExpenses = profile.recurringTransactions
          .where((t) => t.kind == TransactionKind.expense)
          .fold<int>(0, (sum, t) => sum + _monthlyEquivalent(t));
      final variableExpenses = profile.monthlyVariableBudgetCents;
      final confirmedEntries = _confirmedEntriesForMonth(profile, month);
      final plannedPurchases = _plannedPurchasesForMonth(profile, month);
      final tripCosts = _tripCostsForMonth(profile, month);
      final monthExpenses = fixedExpenses + variableExpenses - confirmedEntries - plannedPurchases + tripCosts;
      final monthSaving = income - monthExpenses;
      totalIncome += income;
      totalExpenses += monthExpenses;
      if (monthSaving > bestSaving) {
        bestSaving = monthSaving;
        bestSavingMonth = m;
      }
      monthlyData.add(MonthReview(
        month: month,
        incomeCents: income,
        expensesCents: monthExpenses,
        savingCents: monthSaving,
      ));
    }

    return YearReview(
      year: y,
      monthlyData: monthlyData,
      totalIncomeCents: totalIncome,
      totalExpensesCents: totalExpenses,
      savingRatePercent: totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome * 100).round() : 0,
      bestSavingMonth: bestSavingMonth,
      bestSavingCents: bestSaving,
    );
  }
}

class MonthReview {
  final DateTime month;
  final int incomeCents;
  final int expensesCents;
  final int savingCents;

  const MonthReview({
    required this.month,
    required this.incomeCents,
    required this.expensesCents,
    required this.savingCents,
  });
}

class YearReview {
  final int year;
  final List<MonthReview> monthlyData;
  final int totalIncomeCents;
  final int totalExpensesCents;
  final int savingRatePercent;
  final int bestSavingMonth;
  final int bestSavingCents;

  const YearReview({
    required this.year,
    required this.monthlyData,
    required this.totalIncomeCents,
    required this.totalExpensesCents,
    required this.savingRatePercent,
    required this.bestSavingMonth,
    required this.bestSavingCents,
  });
}
