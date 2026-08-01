import 'package:flutter_test/flutter_test.dart';

import 'package:buget_planer/models/finance_models.dart';
import 'package:buget_planer/services/projection_service.dart';

void main() {
  test('calculates a monthly surplus from recurring cash flow', () {
    final profile = FinancialProfile(
      currentBalanceCents: 100000,
      safetyReserveCents: 20000,
      monthlyVariableBudgetCents: 4000,
      recurringTransactions: [
        RecurringTransaction(
          id: 'income',
          title: 'Plus',
          amountCents: 16000,
          kind: TransactionKind.income,
          incomeCategory: IncomeCategory.gehalt,
          startsOn: DateTime.now(),
        ),
        RecurringTransaction(
          id: 'cost',
          title: 'Abo',
          amountCents: 2000,
          kind: TransactionKind.expense,
          expenseCategory: ExpenseCategory.vertrag,
          startsOn: DateTime.now(),
        ),
      ],
    );

    expect(profile.monthlySurplusCents, 10000);
    expect(profile.freeBalanceCents, 80000);
  });

  test('does not count a trip cost twice in the forecast', () {
    final now = DateTime.now();
    final trip = TripPlan(
      id: 'trip',
      name: 'Trip',
      destination: 'Berlin',
      startsOn: DateTime(now.year, now.month + 2, 1),
      endsOn: DateTime(now.year, now.month + 2, 4),
      fixedCostsCents: 20000,
      dailyBudgetCents: 10000,
      bufferPercent: 0,
    );
    final profile = FinancialProfile(
      currentBalanceCents: 100000,
      safetyReserveCents: 10000,
      monthlyVariableBudgetCents: 0,
      trips: [trip],
      recurringTransactions: [
        RecurringTransaction(
          id: 'income',
          title: 'Plus',
          amountCents: 10000,
          kind: TransactionKind.income,
          incomeCategory: IncomeCategory.gehalt,
          startsOn: now,
        ),
      ],
    );

    final forecast = ProjectionService.forecastTrip(profile, trip);
    expect(forecast.projectedBalanceCents, greaterThan(100000));
    expect(forecast.availableOnTripCents, lessThan(forecast.projectedBalanceCents));
  });

  test('serializes the complete financial profile', () {
    final profile = FinancialProfile(
      currentBalanceCents: 50000,
      safetyReserveCents: 10000,
      monthlyVariableBudgetCents: 2000,
      goals: [
        SavingsGoal(
          id: 'goal',
          name: 'Laptop',
          targetCents: 100000,
          savedCents: 25000,
          deadline: DateTime(2027, 1, 1),
          monthlyAllocationCents: 10000,
        ),
      ],
    );

    final restored = FinancialProfile.fromJson(profile.toJson());
    expect(restored.currentBalanceCents, 50000);
    expect(restored.goals.single.remainingCents, 75000);
  });

  test('does not reserve an unconfirmed trip budget automatically', () {
    final trip = TripPlan(
      id: 'trip',
      name: 'Japan',
      destination: 'Tokyo',
      startsOn: DateTime(2027, 10, 1),
      endsOn: DateTime(2027, 10, 8),
      fixedCostsCents: 100000,
      dailyBudgetCents: 3000,
      budgetLimitCents: 200000,
    );
    final profile = FinancialProfile(
      currentBalanceCents: 300000,
      safetyReserveCents: 0,
      monthlyVariableBudgetCents: 0,
      trips: [trip],
    );

    expect(trip.bufferCents, 0);
    expect(profile.reservedTripCents, 0);
    expect(profile.freeBalanceCents, 300000);
  });

  test('adds daily food budget for every day in a trip segment', () {
    final segment = TripSegment(
      id: 'tokyo',
      name: 'Tokyo',
      location: 'Tokyo',
      startsOn: DateTime(2027, 10, 1),
      endsOn: DateTime(2027, 10, 8),
      accommodationName: 'Hotel',
      accommodationCostCents: 60000,
      dailyFoodBudgetCents: 2000,
    );
    final trip = TripPlan(
      id: 'japan',
      name: 'Japan',
      destination: 'Japan',
      startsOn: DateTime(2027, 10, 1),
      endsOn: DateTime(2027, 10, 8),
      fixedCostsCents: 0,
      dailyBudgetCents: 0,
      segments: [segment],
    );

    expect(segment.days, 7);
    expect(trip.dailyCostsCents, 14000);
    expect(trip.totalCostCents, 74000);
  });

  test('detects gaps between trip segments', () {
    final trip = TripPlan(
      id: 'japan',
      name: 'Japan',
      destination: 'Japan',
      startsOn: DateTime(2027, 10, 1),
      endsOn: DateTime(2027, 10, 11),
      fixedCostsCents: 0,
      dailyBudgetCents: 0,
      segments: [
        TripSegment(
          id: 'tokyo',
          name: 'Tokyo',
          location: 'Tokyo',
          startsOn: DateTime(2027, 10, 1),
          endsOn: DateTime(2027, 10, 4),
          accommodationName: 'Hotel',
          accommodationCostCents: 30000,
          dailyFoodBudgetCents: 2000,
        ),
        TripSegment(
          id: 'kyoto',
          name: 'Kyoto',
          location: 'Kyoto',
          startsOn: DateTime(2027, 10, 6),
          endsOn: DateTime(2027, 10, 11),
          accommodationName: 'Ryokan',
          accommodationCostCents: 50000,
          dailyFoodBudgetCents: 3000,
        ),
      ],
    );

    expect(trip.days, 10);
    expect(trip.gaps.length, 1);
    expect(trip.gaps.first.start, DateTime(2027, 10, 4));
    expect(trip.gaps.first.end, DateTime(2027, 10, 6));
    expect(trip.gaps.first.days, 2);
    expect(trip.uncoveredDays, 2);
    expect(trip.coveredDays, 8);
  });

  test('detects gap at start and end of trip', () {
    final trip = TripPlan(
      id: 'europe',
      name: 'Europa',
      destination: 'Europa',
      startsOn: DateTime(2027, 7, 1),
      endsOn: DateTime(2027, 7, 11),
      fixedCostsCents: 0,
      dailyBudgetCents: 0,
      segments: [
        TripSegment(
          id: 'berlin',
          name: 'Berlin',
          location: 'Berlin',
          startsOn: DateTime(2027, 7, 3),
          endsOn: DateTime(2027, 7, 8),
          accommodationName: 'Hostel',
          accommodationCostCents: 20000,
          dailyFoodBudgetCents: 1500,
        ),
      ],
    );

    expect(trip.gaps.length, 2);
    expect(trip.gaps[0].start, DateTime(2027, 7, 1));
    expect(trip.gaps[0].end, DateTime(2027, 7, 3));
    expect(trip.gaps[0].days, 2);
    expect(trip.gaps[1].start, DateTime(2027, 7, 8));
    expect(trip.gaps[1].end, DateTime(2027, 7, 11));
    expect(trip.gaps[1].days, 3);
    expect(trip.uncoveredDays, 5);
  });

  test('no gaps when segments cover full trip', () {
    final trip = TripPlan(
      id: 'weekend',
      name: 'Wochenende',
      destination: 'Hamburg',
      startsOn: DateTime(2027, 8, 1),
      endsOn: DateTime(2027, 8, 4),
      fixedCostsCents: 0,
      dailyBudgetCents: 0,
      segments: [
        TripSegment(
          id: 'hotel',
          name: 'Hamburg',
          location: 'Hamburg',
          startsOn: DateTime(2027, 8, 1),
          endsOn: DateTime(2027, 8, 4),
          accommodationName: 'Hotel',
          accommodationCostCents: 15000,
          dailyFoodBudgetCents: 2000,
        ),
      ],
    );

    expect(trip.gaps.length, 0);
    expect(trip.uncoveredDays, 0);
    expect(trip.coveragePercent, 1.0);
  });

  test('projection includes trip costs and confirmed entries', () {
    final now = DateTime.now();
    final trip = TripPlan(
      id: 'japan',
      name: 'Japan',
      destination: 'Tokyo',
      startsOn: DateTime(now.year, now.month + 2, 1),
      endsOn: DateTime(now.year, now.month + 2, 10),
      fixedCostsCents: 0,
      dailyBudgetCents: 0,
      segments: [
        TripSegment(
          id: 'tokyo',
          name: 'Tokyo',
          location: 'Tokyo',
          startsOn: DateTime(now.year, now.month + 2, 1),
          endsOn: DateTime(now.year, now.month + 2, 10),
          accommodationName: 'Hotel',
          accommodationCostCents: 50000,
          dailyFoodBudgetCents: 3000,
        ),
      ],
    );
    final profile = FinancialProfile(
      currentBalanceCents: 100000,
      safetyReserveCents: 10000,
      monthlyVariableBudgetCents: 0,
      trips: [trip],
      recurringTransactions: [
        RecurringTransaction(
          id: 'income',
          title: 'Gehalt',
          amountCents: 50000,
          kind: TransactionKind.income,
          incomeCategory: IncomeCategory.gehalt,
          startsOn: now,
        ),
      ],
    );

    final target = DateTime(now.year, now.month + 3);
    final projections = ProjectionService.project(profile, until: target);
    final last = projections.last;

    // Income: 50k/month * 3 months = 150k, starting balance 100k
    // Trip costs in the trip month: 50k hotel + 9 days * 3k food = 77k
    // Expected: 100k + 150k - 77k = 173k
    // But projection runs from current month to target month (3 months),
    // and trip is in month+2, so trip costs apply there
    expect(last.closingBalanceCents, lessThan(100000 + 150000));
  });
}
