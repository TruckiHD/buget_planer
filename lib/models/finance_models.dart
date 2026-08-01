enum TransactionKind { income, expense }

enum TransactionFrequency { once, monthly, weekly, yearly }

enum ForecastScenario { cautious, realistic, optimistic }

DateTime _date(String value) => DateTime.parse(value);
String _dateValue(DateTime value) => value.toIso8601String();

class CashFlowEntry {
  final String id;
  final String title;
  final int amountCents;
  final DateTime date;
  final TransactionKind kind;
  final String category;
  final bool isConfirmed;

  const CashFlowEntry({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.date,
    required this.kind,
    required this.category,
    this.isConfirmed = false,
  });

  int get signedAmountCents =>
      kind == TransactionKind.income ? amountCents : -amountCents;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amountCents': amountCents,
        'date': _dateValue(date),
        'kind': kind.name,
        'category': category,
        'isConfirmed': isConfirmed,
      };

  factory CashFlowEntry.fromJson(Map<String, dynamic> json) => CashFlowEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        amountCents: json['amountCents'] as int,
        date: _date(json['date'] as String),
        kind: TransactionKind.values.byName(json['kind'] as String),
        category: json['category'] as String,
        isConfirmed: json['isConfirmed'] as bool? ?? false,
      );
}

class RecurringTransaction {
  final String id;
  final String title;
  final int amountCents;
  final TransactionKind kind;
  final String category;
  final TransactionFrequency frequency;
  final int dayOfMonth;
  final DateTime startsOn;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.kind,
    required this.category,
    this.frequency = TransactionFrequency.monthly,
    this.dayOfMonth = 1,
    required this.startsOn,
  });

  int get signedAmountCents =>
      kind == TransactionKind.income ? amountCents : -amountCents;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amountCents': amountCents,
        'kind': kind.name,
        'category': category,
        'frequency': frequency.name,
        'dayOfMonth': dayOfMonth,
        'startsOn': _dateValue(startsOn),
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) => RecurringTransaction(
        id: json['id'] as String,
        title: json['title'] as String,
        amountCents: json['amountCents'] as int,
        kind: TransactionKind.values.byName(json['kind'] as String),
        category: json['category'] as String,
        frequency: TransactionFrequency.values.byName(json['frequency'] as String),
        dayOfMonth: json['dayOfMonth'] as int? ?? 1,
        startsOn: _date(json['startsOn'] as String),
      );
}

class TripSegment {
  final String id;
  final String name;
  final String location;
  final DateTime startsOn;
  final DateTime endsOn;
  final String accommodationName;
  final int accommodationCostCents;
  final int dailyFoodBudgetCents;
  final int transportCostCents;
  final int otherCostCents;
  final bool accommodationPaid;

  const TripSegment({
    required this.id,
    required this.name,
    required this.location,
    required this.startsOn,
    required this.endsOn,
    required this.accommodationName,
    required this.accommodationCostCents,
    required this.dailyFoodBudgetCents,
    this.transportCostCents = 0,
    this.otherCostCents = 0,
    this.accommodationPaid = false,
  });

  int get days => endsOn.difference(startsOn).inDays.clamp(1, 365).toInt();
  int get foodCostCents => days * dailyFoodBudgetCents;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'startsOn': _dateValue(startsOn),
        'endsOn': _dateValue(endsOn),
        'accommodationName': accommodationName,
        'accommodationCostCents': accommodationCostCents,
        'dailyFoodBudgetCents': dailyFoodBudgetCents,
        'transportCostCents': transportCostCents,
        'otherCostCents': otherCostCents,
        'accommodationPaid': accommodationPaid,
      };

  factory TripSegment.fromJson(Map<String, dynamic> json) => TripSegment(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        startsOn: _date(json['startsOn'] as String),
        endsOn: _date(json['endsOn'] as String),
        accommodationName: json['accommodationName'] as String,
        accommodationCostCents: json['accommodationCostCents'] as int,
        dailyFoodBudgetCents: json['dailyFoodBudgetCents'] as int,
        transportCostCents: json['transportCostCents'] as int? ?? 0,
        otherCostCents: json['otherCostCents'] as int? ?? 0,
        accommodationPaid: json['accommodationPaid'] as bool? ?? false,
      );
}

class TripExpense {
  final String id;
  final String title;
  final String category;
  final int amountCents;
  final DateTime date;
  final bool isPaid;

  const TripExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    required this.date,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amountCents': amountCents,
        'date': _dateValue(date),
        'isPaid': isPaid,
      };

  factory TripExpense.fromJson(Map<String, dynamic> json) => TripExpense(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        amountCents: json['amountCents'] as int,
        date: _date(json['date'] as String),
        isPaid: json['isPaid'] as bool? ?? false,
      );
}

class TripPlan {
  final String id;
  final String name;
  final String destination;
  final DateTime startsOn;
  final DateTime endsOn;
  final int fixedCostsCents;
  final int dailyBudgetCents;
  final int budgetLimitCents;
  final int bufferPercent;
  final int alreadyPaidCents;
  final List<TripSegment> segments;
  final List<TripExpense> expenses;

  const TripPlan({
    required this.id,
    required this.name,
    required this.destination,
    required this.startsOn,
    required this.endsOn,
    required this.fixedCostsCents,
    required this.dailyBudgetCents,
    this.budgetLimitCents = 0,
    this.bufferPercent = 15,
    this.alreadyPaidCents = 0,
    this.segments = const [],
    this.expenses = const [],
  });

  int get days => endsOn.difference(startsOn).inDays.clamp(1, 365).toInt();

  int get segmentFoodCents => segments.fold<int>(0, (sum, segment) => sum + segment.foodCostCents);

  int get segmentAccommodationCents => segments.fold<int>(0, (sum, segment) => sum + segment.accommodationCostCents);

  int get segmentTransportCents => segments.fold<int>(0, (sum, segment) => sum + segment.transportCostCents);

  int get segmentOtherCents => segments.fold<int>(0, (sum, segment) => sum + segment.otherCostCents);

  int get expenseCents => expenses.fold<int>(0, (sum, expense) => sum + expense.amountCents);

  int get dailyCostsCents => segments.isEmpty ? days * dailyBudgetCents : segmentFoodCents;

  int get subtotalCents => fixedCostsCents +
      dailyCostsCents +
      segmentAccommodationCents +
      segmentTransportCents +
      segmentOtherCents +
      expenseCents;

  int get bufferCents => (subtotalCents * bufferPercent / 100).round();

  int get totalCostCents => subtotalCents + bufferCents;

  int get budgetRemainingCents => budgetLimitCents <= 0
      ? 0
      : budgetLimitCents - totalCostCents;

  bool get isOverBudget => budgetLimitCents > 0 && budgetRemainingCents < 0;

  int get paidCents => alreadyPaidCents +
      segments.where((segment) => segment.accommodationPaid).fold<int>(0, (sum, segment) => sum + segment.accommodationCostCents);

  int get remainingCostCents =>
      (totalCostCents - paidCents).clamp(0, totalCostCents).toInt();

  int get estimatedDailyFoodCents => segments.isEmpty
      ? dailyBudgetCents
      : (segmentFoodCents / segments.fold<int>(0, (sum, segment) => sum + segment.days)).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'destination': destination,
        'startsOn': _dateValue(startsOn),
        'endsOn': _dateValue(endsOn),
        'fixedCostsCents': fixedCostsCents,
        'dailyBudgetCents': dailyBudgetCents,
        'budgetLimitCents': budgetLimitCents,
        'bufferPercent': bufferPercent,
        'alreadyPaidCents': alreadyPaidCents,
        'segments': segments.map((segment) => segment.toJson()).toList(),
        'expenses': expenses.map((expense) => expense.toJson()).toList(),
      };

  factory TripPlan.fromJson(Map<String, dynamic> json) => TripPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        destination: json['destination'] as String,
        startsOn: _date(json['startsOn'] as String),
        endsOn: _date(json['endsOn'] as String),
        fixedCostsCents: json['fixedCostsCents'] as int,
        dailyBudgetCents: json['dailyBudgetCents'] as int,
        budgetLimitCents: json['budgetLimitCents'] as int? ?? 0,
        bufferPercent: json['bufferPercent'] as int? ?? 15,
        alreadyPaidCents: json['alreadyPaidCents'] as int? ?? 0,
        segments: (json['segments'] as List<dynamic>? ?? [])
            .map((item) => TripSegment.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        expenses: (json['expenses'] as List<dynamic>? ?? [])
            .map((item) => TripExpense.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  TripPlan copyWith({
    String? name,
    String? destination,
    DateTime? startsOn,
    DateTime? endsOn,
    int? fixedCostsCents,
    int? dailyBudgetCents,
    int? budgetLimitCents,
    int? bufferPercent,
    int? alreadyPaidCents,
    List<TripSegment>? segments,
    List<TripExpense>? expenses,
  }) {
    return TripPlan(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      fixedCostsCents: fixedCostsCents ?? this.fixedCostsCents,
      dailyBudgetCents: dailyBudgetCents ?? this.dailyBudgetCents,
      budgetLimitCents: budgetLimitCents ?? this.budgetLimitCents,
      bufferPercent: bufferPercent ?? this.bufferPercent,
      alreadyPaidCents: alreadyPaidCents ?? this.alreadyPaidCents,
      segments: segments ?? this.segments,
      expenses: expenses ?? this.expenses,
    );
  }
}

class PlannedPurchase {
  final String id;
  final String title;
  final String category;
  final int amountCents;
  final DateTime desiredDate;
  final int priority;
  final bool isPurchased;

  const PlannedPurchase({
    required this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    required this.desiredDate,
    this.priority = 1,
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amountCents': amountCents,
        'desiredDate': _dateValue(desiredDate),
        'priority': priority,
        'isPurchased': isPurchased,
      };

  factory PlannedPurchase.fromJson(Map<String, dynamic> json) => PlannedPurchase(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        amountCents: json['amountCents'] as int,
        desiredDate: _date(json['desiredDate'] as String),
        priority: json['priority'] as int? ?? 1,
        isPurchased: json['isPurchased'] as bool? ?? false,
      );
}

class SavingsGoal {
  final String id;
  final String name;
  final int targetCents;
  final int savedCents;
  final DateTime deadline;
  final int monthlyAllocationCents;
  final int priority;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetCents,
    required this.savedCents,
    required this.deadline,
    required this.monthlyAllocationCents,
    this.priority = 1,
  });

  int get remainingCents => (targetCents - savedCents).clamp(0, targetCents).toInt();

  double get progress => (savedCents / targetCents).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetCents': targetCents,
        'savedCents': savedCents,
        'deadline': _dateValue(deadline),
        'monthlyAllocationCents': monthlyAllocationCents,
        'priority': priority,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        targetCents: json['targetCents'] as int,
        savedCents: json['savedCents'] as int,
        deadline: _date(json['deadline'] as String),
        monthlyAllocationCents: json['monthlyAllocationCents'] as int,
        priority: json['priority'] as int? ?? 1,
      );
}

class FinancialProfile {
  final int currentBalanceCents;
  final int safetyReserveCents;
  final int monthlyVariableBudgetCents;
  final List<CashFlowEntry> entries;
  final List<RecurringTransaction> recurringTransactions;
  final List<TripPlan> trips;
  final List<SavingsGoal> goals;
  final List<PlannedPurchase> plannedPurchases;

  const FinancialProfile({
    required this.currentBalanceCents,
    required this.safetyReserveCents,
    required this.monthlyVariableBudgetCents,
    this.entries = const [],
    this.recurringTransactions = const [],
    this.trips = const [],
    this.goals = const [],
    this.plannedPurchases = const [],
  });

  int get monthlyIncomeCents => recurringTransactions
      .where((item) => item.kind == TransactionKind.income)
      .fold<int>(0, (sum, item) => sum + _monthlyEquivalent(item));

  int get monthlyFixedExpensesCents => recurringTransactions
      .where((item) => item.kind == TransactionKind.expense)
      .fold<int>(0, (sum, item) => sum + _monthlyEquivalent(item));

  int get monthlySurplusCents =>
      monthlyIncomeCents -
      monthlyFixedExpensesCents -
      monthlyVariableBudgetCents -
      monthlyGoalAllocationsCents;

  int get reservedTripCents =>
      trips.fold<int>(0, (sum, trip) => sum + trip.remainingCostCents);

  int get reservedGoalCents =>
      goals.fold<int>(0, (sum, goal) => sum + goal.remainingCents);

  int get monthlyGoalAllocationsCents =>
      goals.fold<int>(0, (sum, goal) => sum + goal.monthlyAllocationCents);

  int get reservedPurchaseCents => plannedPurchases
      .where((purchase) => !purchase.isPurchased)
      .fold<int>(0, (sum, purchase) => sum + purchase.amountCents);

  int get freeBalanceCents => currentBalanceCents -
      safetyReserveCents -
      reservedTripCents -
      reservedGoalCents -
      reservedPurchaseCents -
      entries
          .where((entry) => entry.kind == TransactionKind.expense && !entry.isConfirmed)
          .fold<int>(0, (sum, entry) => sum + entry.amountCents);

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

  FinancialProfile copyWith({
    int? currentBalanceCents,
    int? safetyReserveCents,
    int? monthlyVariableBudgetCents,
    List<CashFlowEntry>? entries,
    List<RecurringTransaction>? recurringTransactions,
    List<TripPlan>? trips,
    List<SavingsGoal>? goals,
    List<PlannedPurchase>? plannedPurchases,
  }) {
    return FinancialProfile(
      currentBalanceCents: currentBalanceCents ?? this.currentBalanceCents,
      safetyReserveCents: safetyReserveCents ?? this.safetyReserveCents,
      monthlyVariableBudgetCents: monthlyVariableBudgetCents ?? this.monthlyVariableBudgetCents,
      entries: entries ?? this.entries,
      recurringTransactions: recurringTransactions ?? this.recurringTransactions,
      trips: trips ?? this.trips,
      goals: goals ?? this.goals,
      plannedPurchases: plannedPurchases ?? this.plannedPurchases,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentBalanceCents': currentBalanceCents,
        'safetyReserveCents': safetyReserveCents,
        'monthlyVariableBudgetCents': monthlyVariableBudgetCents,
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'recurringTransactions': recurringTransactions.map((item) => item.toJson()).toList(),
        'trips': trips.map((trip) => trip.toJson()).toList(),
        'goals': goals.map((goal) => goal.toJson()).toList(),
        'plannedPurchases': plannedPurchases.map((purchase) => purchase.toJson()).toList(),
      };

  factory FinancialProfile.fromJson(Map<String, dynamic> json) => FinancialProfile(
        currentBalanceCents: json['currentBalanceCents'] as int,
        safetyReserveCents: json['safetyReserveCents'] as int,
        monthlyVariableBudgetCents: json['monthlyVariableBudgetCents'] as int,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((item) => CashFlowEntry.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        recurringTransactions: (json['recurringTransactions'] as List<dynamic>? ?? [])
            .map((item) => RecurringTransaction.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        trips: (json['trips'] as List<dynamic>? ?? [])
            .map((item) => TripPlan.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        goals: (json['goals'] as List<dynamic>? ?? [])
            .map((item) => SavingsGoal.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        plannedPurchases: (json['plannedPurchases'] as List<dynamic>? ?? [])
            .map((item) => PlannedPurchase.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
