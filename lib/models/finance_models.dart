import 'package:flutter/material.dart';

enum TransactionKind { income, expense }

enum TransactionFrequency { once, monthly, weekly, yearly }

enum ForecastScenario { cautious, realistic, optimistic }

enum ExpenseCategory {
  wohnen('Wohnen', Icons.home_rounded, Color(0xFF5C6DF2)),
  lebensmittel('Lebensmittel', Icons.shopping_cart_rounded, Color(0xFF20966A)),
  transport('Transport', Icons.directions_bus_rounded, Color(0xFFE19A35)),
  unterhaltung('Unterhaltung', Icons.sports_esports_rounded, Color(0xFFD94E5A)),
  gesundheit('Gesundheit', Icons.favorite_rounded, Color(0xFFE05B9A)),
  bildung('Bildung', Icons.school_rounded, Color(0xFF7B61FF)),
  vertrag('Verträge & Abos', Icons.subscriptions_rounded, Color(0xFF00B8D9)),
  geschenke('Geschenke', Icons.card_giftcard_rounded, Color(0xFFFF6D00)),
  sonstiges('Sonstiges', Icons.more_horiz_rounded, Color(0xFF78839A));

  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.label, this.icon, this.color);

  static ExpenseCategory fromString(String value) {
    for (final cat in ExpenseCategory.values) {
      if (cat.name == value || cat.label == value) return cat;
    }
    return ExpenseCategory.sonstiges;
  }
}

enum IncomeCategory {
  gehalt('Gehalt', Icons.work_rounded, Color(0xFF20966A)),
  freelance('Freelance', Icons.laptop_mac_rounded, Color(0xFF5C6DF2)),
  investitionen('Investitionen', Icons.trending_up_rounded, Color(0xFFE19A35)),
  geschenk('Geschenk', Icons.card_giftcard_rounded, Color(0xFFFF6D00)),
  sonstiges('Sonstiges', Icons.more_horiz_rounded, Color(0xFF78839A));

  final String label;
  final IconData icon;
  final Color color;

  const IncomeCategory(this.label, this.icon, this.color);

  static IncomeCategory fromString(String value) {
    for (final cat in IncomeCategory.values) {
      if (cat.name == value || cat.label == value) return cat;
    }
    return IncomeCategory.sonstiges;
  }
}

DateTime _date(String value) => DateTime.parse(value);
String _dateValue(DateTime value) => value.toIso8601String();

class CashFlowEntry {
  final String id;
  final String title;
  final int amountCents;
  final DateTime date;
  final TransactionKind kind;
  final ExpenseCategory? expenseCategory;
  final IncomeCategory? incomeCategory;
  final bool isConfirmed;

  const CashFlowEntry({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.date,
    required this.kind,
    this.expenseCategory,
    this.incomeCategory,
    this.isConfirmed = false,
  });

  int get signedAmountCents =>
      kind == TransactionKind.income ? amountCents : -amountCents;

  String get categoryLabel => kind == TransactionKind.income
      ? (incomeCategory ?? IncomeCategory.sonstiges).label
      : (expenseCategory ?? ExpenseCategory.sonstiges).label;

  IconData get categoryIcon => kind == TransactionKind.income
      ? (incomeCategory ?? IncomeCategory.sonstiges).icon
      : (expenseCategory ?? ExpenseCategory.sonstiges).icon;

  Color get categoryColor => kind == TransactionKind.income
      ? (incomeCategory ?? IncomeCategory.sonstiges).color
      : (expenseCategory ?? ExpenseCategory.sonstiges).color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amountCents': amountCents,
        'date': _dateValue(date),
        'kind': kind.name,
        'expenseCategory': expenseCategory?.name,
        'incomeCategory': incomeCategory?.name,
        'isConfirmed': isConfirmed,
      };

  factory CashFlowEntry.fromJson(Map<String, dynamic> json) {
    final kind = TransactionKind.values.byName(json['kind'] as String);
    ExpenseCategory? expCat;
    IncomeCategory? incCat;
    if (json['expenseCategory'] != null) {
      expCat = ExpenseCategory.fromString(json['expenseCategory'] as String);
    } else if (json['incomeCategory'] != null) {
      incCat = IncomeCategory.fromString(json['incomeCategory'] as String);
    } else if (json['category'] != null) {
      final raw = json['category'] as String;
      if (kind == TransactionKind.expense) {
        expCat = ExpenseCategory.fromString(raw);
      } else {
        incCat = IncomeCategory.fromString(raw);
      }
    }
    return CashFlowEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      amountCents: json['amountCents'] as int,
      date: _date(json['date'] as String),
      kind: kind,
      expenseCategory: expCat,
      incomeCategory: incCat,
      isConfirmed: json['isConfirmed'] as bool? ?? false,
    );
  }
}

class RecurringTransaction {
  final String id;
  final String title;
  final int amountCents;
  final TransactionKind kind;
  final ExpenseCategory? expenseCategory;
  final IncomeCategory? incomeCategory;
  final TransactionFrequency frequency;
  final int dayOfMonth;
  final DateTime startsOn;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.kind,
    this.expenseCategory,
    this.incomeCategory,
    this.frequency = TransactionFrequency.monthly,
    this.dayOfMonth = 1,
    required this.startsOn,
  });

  int get signedAmountCents =>
      kind == TransactionKind.income ? amountCents : -amountCents;

  String get categoryLabel => kind == TransactionKind.income
      ? (incomeCategory ?? IncomeCategory.sonstiges).label
      : (expenseCategory ?? ExpenseCategory.sonstiges).label;

  IconData get categoryIcon => kind == TransactionKind.income
      ? (incomeCategory ?? IncomeCategory.sonstiges).icon
      : (expenseCategory ?? ExpenseCategory.sonstiges).icon;

  Color get categoryColor => kind == TransactionKind.income
      ? (incomeCategory ?? IncomeCategory.sonstiges).color
      : (expenseCategory ?? ExpenseCategory.sonstiges).color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amountCents': amountCents,
        'kind': kind.name,
        'expenseCategory': expenseCategory?.name,
        'incomeCategory': incomeCategory?.name,
        'frequency': frequency.name,
        'dayOfMonth': dayOfMonth,
        'startsOn': _dateValue(startsOn),
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    final kind = TransactionKind.values.byName(json['kind'] as String);
    ExpenseCategory? expCat;
    IncomeCategory? incCat;
    if (json['expenseCategory'] != null) {
      expCat = ExpenseCategory.fromString(json['expenseCategory'] as String);
    } else if (json['incomeCategory'] != null) {
      incCat = IncomeCategory.fromString(json['incomeCategory'] as String);
    } else if (json['category'] != null) {
      final raw = json['category'] as String;
      if (kind == TransactionKind.expense) {
        expCat = ExpenseCategory.fromString(raw);
      } else {
        incCat = IncomeCategory.fromString(raw);
      }
    }
    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amountCents: json['amountCents'] as int,
      kind: kind,
      expenseCategory: expCat,
      incomeCategory: incCat,
      frequency: TransactionFrequency.values.byName(json['frequency'] as String),
      dayOfMonth: json['dayOfMonth'] as int? ?? 1,
      startsOn: _date(json['startsOn'] as String),
    );
  }
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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
  });

  int get days => endsOn.difference(startsOn).inDays.clamp(1, 365).toInt();
  int get foodCostCents => days * dailyFoodBudgetCents;
  bool get hasCoordinates => latitude != null && longitude != null;

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
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
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
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  TripSegment copyWith({
    String? name,
    String? location,
    DateTime? startsOn,
    DateTime? endsOn,
    String? accommodationName,
    int? accommodationCostCents,
    int? dailyFoodBudgetCents,
    int? transportCostCents,
    int? otherCostCents,
    bool? accommodationPaid,
    double? latitude,
    double? longitude,
  }) {
    return TripSegment(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      accommodationName: accommodationName ?? this.accommodationName,
      accommodationCostCents: accommodationCostCents ?? this.accommodationCostCents,
      dailyFoodBudgetCents: dailyFoodBudgetCents ?? this.dailyFoodBudgetCents,
      transportCostCents: transportCostCents ?? this.transportCostCents,
      otherCostCents: otherCostCents ?? this.otherCostCents,
      accommodationPaid: accommodationPaid ?? this.accommodationPaid,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

enum TransportMode {
  zug(Icons.train_rounded, 'Zug', Color(0xFF5669E8)),
  bus(Icons.directions_bus_rounded, 'Bus', Color(0xFF20966A)),
  flug(Icons.flight_rounded, 'Flug', Color(0xFFE19A35)),
  faehre(Icons.directions_boat_rounded, 'Fähre', Color(0xFF00B8D9)),
  auto(Icons.directions_car_rounded, 'Auto', Color(0xFF78839A));

  final IconData icon;
  final String label;
  final Color color;

  const TransportMode(this.icon, this.label, this.color);

  static TransportMode fromString(String value) {
    for (final mode in TransportMode.values) {
      if (mode.name == value || mode.label == value) return mode;
    }
    return TransportMode.zug;
  }
}

class TripTransport {
  final String id;
  final String? fromSegmentId;
  final String? toSegmentId;
  final String fromLocation;
  final String toLocation;
  final TransportMode mode;
  final int estimatedCostCents;
  final int? durationMinutes;
  final DateTime departureDate;
  final String? bookingReference;
  final bool isBooked;
  final String? notes;

  const TripTransport({
    required this.id,
    this.fromSegmentId,
    this.toSegmentId,
    required this.fromLocation,
    required this.toLocation,
    this.mode = TransportMode.zug,
    this.estimatedCostCents = 0,
    this.durationMinutes,
    required this.departureDate,
    this.bookingReference,
    this.isBooked = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (fromSegmentId != null) 'fromSegmentId': fromSegmentId,
        if (toSegmentId != null) 'toSegmentId': toSegmentId,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'mode': mode.name,
        'estimatedCostCents': estimatedCostCents,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'departureDate': _dateValue(departureDate),
        if (bookingReference != null) 'bookingReference': bookingReference,
        'isBooked': isBooked,
        if (notes != null) 'notes': notes,
      };

  factory TripTransport.fromJson(Map<String, dynamic> json) => TripTransport(
        id: json['id'] as String,
        fromSegmentId: json['fromSegmentId'] as String?,
        toSegmentId: json['toSegmentId'] as String?,
        fromLocation: json['fromLocation'] as String,
        toLocation: json['toLocation'] as String,
        mode: json['mode'] != null
            ? TransportMode.fromString(json['mode'] as String)
            : TransportMode.zug,
        estimatedCostCents: json['estimatedCostCents'] as int? ?? 0,
        durationMinutes: json['durationMinutes'] as int?,
        departureDate: _date(json['departureDate'] as String),
        bookingReference: json['bookingReference'] as String?,
        isBooked: json['isBooked'] as bool? ?? false,
        notes: json['notes'] as String?,
      );

  TripTransport copyWith({
    String? fromLocation,
    String? toLocation,
    TransportMode? mode,
    int? estimatedCostCents,
    int? durationMinutes,
    DateTime? departureDate,
    String? bookingReference,
    bool? isBooked,
    String? notes,
  }) {
    return TripTransport(
      id: id,
      fromSegmentId: fromSegmentId,
      toSegmentId: toSegmentId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      mode: mode ?? this.mode,
      estimatedCostCents: estimatedCostCents ?? this.estimatedCostCents,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      departureDate: departureDate ?? this.departureDate,
      bookingReference: bookingReference ?? this.bookingReference,
      isBooked: isBooked ?? this.isBooked,
      notes: notes ?? this.notes,
    );
  }
}

class FoodPriceData {
  final String city;
  final String country;
  final double mealInexpensive;
  final double mealMidRange;
  final double groceriesPerDay;
  final double coffeePrice;

  const FoodPriceData({
    required this.city,
    required this.country,
    required this.mealInexpensive,
    required this.mealMidRange,
    required this.groceriesPerDay,
    this.coffeePrice = 3.0,
  });

  int get suggestedBudgetCents => ((mealInexpensive + mealMidRange) / 2 * 100).round();
  int get budgetCents => (mealInexpensive * 100 * 2).round();
  int get comfortableCents => (mealMidRange * 100).round();
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

class TripGap {
  final DateTime start;
  final DateTime end;

  const TripGap({required this.start, required this.end});

  int get days => end.difference(start).inDays;
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
  final int reservedCents;
  final List<TripSegment> segments;
  final List<TripExpense> expenses;
  final List<TripTransport> transports;

  const TripPlan({
    required this.id,
    required this.name,
    required this.destination,
    required this.startsOn,
    required this.endsOn,
    required this.fixedCostsCents,
    required this.dailyBudgetCents,
    this.budgetLimitCents = 0,
    this.bufferPercent = 0,
    this.alreadyPaidCents = 0,
    this.reservedCents = 0,
    this.segments = const [],
    this.expenses = const [],
    this.transports = const [],
  });

  int get days => endsOn.difference(startsOn).inDays.clamp(1, 365).toInt();

  int get segmentFoodCents => segments.fold<int>(0, (sum, segment) => sum + segment.foodCostCents);

  int get segmentAccommodationCents => segments.fold<int>(0, (sum, segment) => sum + segment.accommodationCostCents);

  int get segmentTransportCents => segments.fold<int>(0, (sum, segment) => sum + segment.transportCostCents);

  int get segmentOtherCents => segments.fold<int>(0, (sum, segment) => sum + segment.otherCostCents);

  int get expenseCents => expenses.fold<int>(0, (sum, expense) => sum + expense.amountCents);

  int get transportCents => transports.fold<int>(0, (sum, t) => sum + t.estimatedCostCents);

  int get dailyCostsCents => segments.isEmpty ? days * dailyBudgetCents : segmentFoodCents;

  int get subtotalCents => fixedCostsCents +
      dailyCostsCents +
      segmentAccommodationCents +
      segmentTransportCents +
      segmentOtherCents +
      expenseCents +
      transportCents;

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

  List<TripGap> get gaps {
    if (segments.isEmpty) return [TripGap(start: startsOn, end: endsOn)];
    final sorted = [...segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    final result = <TripGap>[];
    if (sorted.first.startsOn.isAfter(startsOn)) {
      result.add(TripGap(start: startsOn, end: sorted.first.startsOn));
    }
    for (var i = 0; i < sorted.length - 1; i++) {
      final currentEnd = sorted[i].endsOn;
      final nextStart = sorted[i + 1].startsOn;
      if (nextStart.isAfter(currentEnd)) {
        result.add(TripGap(start: currentEnd, end: nextStart));
      }
    }
    if (sorted.last.endsOn.isBefore(endsOn)) {
      result.add(TripGap(start: sorted.last.endsOn, end: endsOn));
    }
    return result;
  }

  int get uncoveredDays => gaps.fold<int>(0, (sum, gap) => sum + gap.days);

  int get coveredDays => days - uncoveredDays;

  double get coveragePercent => days > 0 ? (coveredDays / days).clamp(0.0, 1.0) : 0.0;

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
        'reservedCents': reservedCents,
        'segments': segments.map((segment) => segment.toJson()).toList(),
        'expenses': expenses.map((expense) => expense.toJson()).toList(),
        'transports': transports.map((t) => t.toJson()).toList(),
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
        bufferPercent: json['bufferPercent'] as int? ?? 0,
        alreadyPaidCents: json['alreadyPaidCents'] as int? ?? 0,
        reservedCents: json['reservedCents'] as int? ?? 0,
        segments: (json['segments'] as List<dynamic>? ?? [])
            .map((item) => TripSegment.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        expenses: (json['expenses'] as List<dynamic>? ?? [])
            .map((item) => TripExpense.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        transports: (json['transports'] as List<dynamic>? ?? [])
            .map((item) => TripTransport.fromJson(Map<String, dynamic>.from(item as Map)))
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
    int? reservedCents,
    List<TripSegment>? segments,
    List<TripExpense>? expenses,
    List<TripTransport>? transports,
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
      reservedCents: reservedCents ?? this.reservedCents,
      segments: segments ?? this.segments,
      expenses: expenses ?? this.expenses,
      transports: transports ?? this.transports,
    );
  }
}

class PlannedPurchase {
  final String id;
  final String title;
  final ExpenseCategory category;
  final int amountCents;
  final DateTime desiredDate;
  final int priority;
  final bool isPurchased;
  final bool isReserved;

  const PlannedPurchase({
    required this.id,
    required this.title,
    this.category = ExpenseCategory.sonstiges,
    required this.amountCents,
    required this.desiredDate,
    this.priority = 1,
    this.isPurchased = false,
    this.isReserved = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'amountCents': amountCents,
        'desiredDate': _dateValue(desiredDate),
        'priority': priority,
        'isPurchased': isPurchased,
        'isReserved': isReserved,
      };

  factory PlannedPurchase.fromJson(Map<String, dynamic> json) => PlannedPurchase(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] != null
            ? ExpenseCategory.fromString(json['category'] as String)
            : ExpenseCategory.sonstiges,
        amountCents: json['amountCents'] as int,
        desiredDate: _date(json['desiredDate'] as String),
        priority: json['priority'] as int? ?? 1,
        isPurchased: json['isPurchased'] as bool? ?? false,
        isReserved: json['isReserved'] as bool? ?? false,
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

class CategoryBudget {
  final ExpenseCategory category;
  final int monthlyLimitCents;

  const CategoryBudget({
    required this.category,
    required this.monthlyLimitCents,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'monthlyLimitCents': monthlyLimitCents,
      };

  factory CategoryBudget.fromJson(Map<String, dynamic> json) => CategoryBudget(
        category: ExpenseCategory.fromString(json['category'] as String),
        monthlyLimitCents: json['monthlyLimitCents'] as int,
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
  final List<CategoryBudget> categoryBudgets;

  const FinancialProfile({
    required this.currentBalanceCents,
    required this.safetyReserveCents,
    required this.monthlyVariableBudgetCents,
    this.entries = const [],
    this.recurringTransactions = const [],
    this.trips = const [],
    this.goals = const [],
    this.plannedPurchases = const [],
    this.categoryBudgets = const [],
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
      trips.fold<int>(0, (sum, trip) => sum + trip.reservedCents);

  int get reservedGoalCents =>
      goals.fold<int>(0, (sum, goal) => sum + goal.remainingCents);

  int get monthlyGoalAllocationsCents =>
      goals.fold<int>(0, (sum, goal) => sum + goal.monthlyAllocationCents);

  int get reservedPurchaseCents => plannedPurchases
      .where((purchase) => !purchase.isPurchased && purchase.isReserved)
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
    List<CategoryBudget>? categoryBudgets,
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
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
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
        'categoryBudgets': categoryBudgets.map((budget) => budget.toJson()).toList(),
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
        categoryBudgets: (json['categoryBudgets'] as List<dynamic>? ?? [])
            .map((item) => CategoryBudget.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
