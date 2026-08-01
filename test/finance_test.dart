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
          category: 'Einnahme',
          startsOn: DateTime.now(),
        ),
        RecurringTransaction(
          id: 'cost',
          title: 'Abo',
          amountCents: 2000,
          kind: TransactionKind.expense,
          category: 'Fixkosten',
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
          category: 'Einnahme',
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
}
