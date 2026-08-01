import 'package:flutter/material.dart';

import '../data/local_storage_service.dart';
import '../models/finance_models.dart';
import '../services/projection_service.dart';
import 'trip_detail_screen.dart';
import '../utils/squircle_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = LocalStorageService();
  late FinancialProfile _profile;
  int _selectedIndex = 0;
  ForecastScenario _scenario = ForecastScenario.realistic;
  DateTime _dashboardMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _profile = FinancialProfile(
      currentBalanceCents: 0,
      safetyReserveCents: 0,
      monthlyVariableBudgetCents: 0,
    );
    _restoreProfile();
  }

  Future<void> _restoreProfile() async {
    final saved = await _storage.loadProfile();
    if (saved == null) {
      await _storage.saveProfile(_profile);
      return;
    }
    if (!mounted) return;
    setState(() => _profile = saved);
  }

  Future<void> _persistProfile() => _storage.saveProfile(_profile);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (desktop) _Sidebar(selectedIndex: _selectedIndex, onSelect: _selectTab),
                Expanded(child: _content(desktop)),
              ],
            ),
          ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectTab,
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Übersicht'),
                    NavigationDestination(icon: Icon(Icons.flight_takeoff_rounded), label: 'Reisen'),
                    NavigationDestination(icon: Icon(Icons.swap_vert_rounded), label: 'Cashflow'),
                    NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Ziele'),
                    NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Anschaffungen'),
                  ],
                ),
          floatingActionButton: _selectedIndex <= 4
              ? FloatingActionButton.extended(
                  onPressed: _selectedIndex == 0 ? _showAddIncome : _selectedIndex == 1 ? _showAddTrip : _selectedIndex == 2 ? _showAddCashflow : _selectedIndex == 3 ? _showAddGoal : _showAddPurchase,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_selectedIndex == 0 ? 'Plus hinzufügen' : _selectedIndex == 1 ? 'Reise hinzufügen' : _selectedIndex == 2 ? 'Buchung hinzufügen' : _selectedIndex == 3 ? 'Ziel hinzufügen' : 'Anschaffung planen'),
                )
              : null,
        );
      },
    );
  }

  Widget _content(bool desktop) {
    if (_selectedIndex == 1) return _tripsPage();
    if (_selectedIndex == 2) return _cashflowPage();
    if (_selectedIndex == 3) return _goalsPage();
    if (_selectedIndex == 4) return _purchasesPage();
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = desktop ? 1180.0 : width;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(desktop ? 44 : 20, 28, desktop ? 44 : 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 26),
              if (_profile.recurringTransactions.isEmpty && _profile.currentBalanceCents == 0) ...[
                _setupCard(),
                const SizedBox(height: 18),
              ],
              _responsiveOverview(desktop),
              const SizedBox(height: 22),
              _sectionTitle('Dein Monat', 'Was bleibt nach den festen Plänen?'),
              const SizedBox(height: 12),
              _monthPlanCard(),
              const SizedBox(height: 12),
              _cashflowCard(),
              const SizedBox(height: 22),
              _sectionTitle('Nächstes Ziel', 'Prognose statt Bauchgefühl'),
              const SizedBox(height: 12),
              if (_profile.trips.isEmpty)
                _surface(child: const Text('Noch keine Reise angelegt. Erstelle dein erstes Ziel über den Reisen-Bereich.', style: TextStyle(height: 1.4)))
              else
                _tripCard(_profile.trips.first),
              const SizedBox(height: 22),
              _sectionTitle('Szenario testen', 'Wie robust ist dein Plan?'),
              const SizedBox(height: 12),
              _scenarioCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              const Text('Dein Finanzblick', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
            ],
          ),
        ),
        IconButton(onPressed: _showSettings, icon: const Icon(Icons.tune_rounded)),
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE0E5FF),
          child: Text('G', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _setupCard() => _surface(child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFF1FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.waving_hand_outlined, color: Color(0xFF5669E8))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Richte deinen Finanzblick ein', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('Trage Guthaben, Reserve und dein monatliches Plus ein. Danach werden deine Prognosen aussagekräftig.', style: Theme.of(context).textTheme.bodyMedium)])), TextButton(onPressed: _showSettings, child: const Text('Starten'))]));

  Widget _responsiveOverview(bool desktop) {
    final cards = [_balanceCard(), _monthlyPlusCard(), _tripReadinessCard()];
    if (!desktop) return Column(children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList());
    // The dashboard lives inside a vertical scroll view. Stretching children
    // there asks the Row for an infinite height, so let each card keep its
    // intrinsic height instead.
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < cards.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == 2 ? 0 : 12), child: cards[i]))]);
  }

  Widget _balanceCard() {
    final balance = _profile.currentBalanceCents;
    final free = _profile.freeBalanceCents;
    final reserve = _profile.safetyReserveCents;
    final reserved = _profile.reservedTripCents + _profile.reservedGoalCents + _profile.reservedPurchaseCents;
    return _surface(
      gradient: const LinearGradient(colors: [Color(0xFF5669E8), Color(0xFF8290F8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('GUTHABEN HEUTE', Colors.white70),
        const SizedBox(height: 12),
        Text(_money(balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text('Tatsächliches Guthaben, nicht nur der freie Anteil', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        Row(children: [const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16), const SizedBox(width: 6), Text('Frei nach allen Plänen ${_money(free)}', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
        const SizedBox(height: 6),
        Row(children: [const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 16), const SizedBox(width: 6), Text('Reserviert ${_money(reserved)} · Reserve ${_money(reserve)}', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
      ]),
    );
  }

  Widget _monthlyPlusCard() {
    final surplus = _profile.monthlySurplusCents;
    return _surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('MONATLICHER ÜBERSCHUSS', const Color(0xFF78839A)),
        const SizedBox(height: 12),
        Text(_money(surplus), style: TextStyle(color: surplus >= 0 ? const Color(0xFF20966A) : const Color(0xFFD94E5A), fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 4),
        const Text('nach Fixkosten & Alltag', style: TextStyle(color: Color(0xFF78839A))),
        const SizedBox(height: 18),
        Row(children: [const Icon(Icons.trending_up_rounded, color: Color(0xFF20966A), size: 18), const SizedBox(width: 5), Text('${_money(_profile.monthlyIncomeCents)} Einnahmen / Monat', style: const TextStyle(fontSize: 12, color: Color(0xFF78839A)))]),
      ]),
    );
  }

  Widget _tripReadinessCard() {
    if (_profile.trips.isEmpty) {
      return _surface(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NOCH KEINE REISE', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: Color(0xFF78839A))), SizedBox(height: 12), Text('Lege eine Reise an, um den Reisetag zu prognostizieren.', style: TextStyle(color: Color(0xFF78839A)))]));
    }
    final trip = _profile.trips.first;
    final forecast = ProjectionService.forecastTrip(_profile, trip, scenario: _scenario);
    return _surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('AM REISETAG', const Color(0xFF78839A)),
        const SizedBox(height: 12),
        Text(_money(forecast.availableOnTripCents), style: TextStyle(color: forecast.isOnTrack ? const Color(0xFF20966A) : const Color(0xFFD94E5A), fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(forecast.isOnTrack ? 'Puffer nach Reisebudget' : 'Es fehlen noch ${_money(-forecast.availableOnTripCents)}', style: const TextStyle(color: Color(0xFF78839A))),
        const SizedBox(height: 18),
        Text('Tagesbudget ${_money(trip.dailyBudgetCents)}', style: const TextStyle(fontSize: 12, color: Color(0xFF78839A))),
      ]),
    );
  }

  Widget _cashflowCard() {
    final income = _profile.monthlyIncomeCents;
    final fixed = _profile.monthlyFixedExpensesCents;
    final variable = _profile.monthlyVariableBudgetCents;
    return _surface(child: Column(children: [
      _flowLine('Einnahmen', income, const Color(0xFF20966A), Icons.arrow_downward_rounded),
      const Divider(height: 24),
      _flowLine('Fixkosten', -fixed, const Color(0xFFD94E5A), Icons.arrow_upward_rounded),
      _flowLine('Alltagspuffer', -variable, const Color(0xFFE19A35), Icons.shopping_bag_outlined),
      const Divider(height: 24),
      _flowLine('Übrig zum Planen', _profile.monthlySurplusCents, const Color(0xFF5669E8), Icons.auto_awesome_rounded, bold: true),
    ]));
  }

  Widget _monthPlanCard() {
    final snapshot = ProjectionService.monthSnapshot(_profile, _dashboardMonth, scenario: _scenario);
    final isCurrentMonth = _dashboardMonth.year == DateTime.now().year && _dashboardMonth.month == DateTime.now().month;
    return _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [IconButton(tooltip: 'Vorheriger Monat', onPressed: () => setState(() => _dashboardMonth = DateTime(_dashboardMonth.year, _dashboardMonth.month - 1)), icon: const Icon(Icons.chevron_left_rounded)), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(_monthLabel(_dashboardMonth), style: Theme.of(context).textTheme.titleMedium), Text(isCurrentMonth ? 'Aktueller Monat' : 'Prognose', style: Theme.of(context).textTheme.bodyMedium)])), IconButton(tooltip: 'Nächster Monat', onPressed: () => setState(() => _dashboardMonth = DateTime(_dashboardMonth.year, _dashboardMonth.month + 1)), icon: const Icon(Icons.chevron_right_rounded))]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Voraussichtlich am Monatsende'), Text(_money(snapshot.projectedClosingBalanceCents), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF172033)))]),
      const SizedBox(height: 12),
      _flowLine('Einnahmen', snapshot.incomeCents, const Color(0xFF20966A), Icons.arrow_downward_rounded),
      _flowLine('Fixkosten & Alltag', -(snapshot.fixedExpensesCents + snapshot.variableExpensesCents), const Color(0xFFD94E5A), Icons.arrow_upward_rounded),
      if (snapshot.plannedPurchasesCents > 0) _flowLine('Geplante Anschaffungen', -snapshot.plannedPurchasesCents, const Color(0xFFE19A35), Icons.shopping_bag_outlined),
      if (snapshot.plannedTripCostsCents > 0) _flowLine('Reisezahlungen', -snapshot.plannedTripCostsCents, const Color(0xFF5669E8), Icons.flight_takeoff_rounded),
      const Divider(height: 20),
      _flowLine('Frei nach allen Reservierungen', snapshot.freeAfterPlansCents, snapshot.freeAfterPlansCents >= 0 ? const Color(0xFF20966A) : const Color(0xFFD94E5A), Icons.account_balance_wallet_outlined, bold: true),
    ]));
  }

  Widget _flowLine(String label, int amount, Color color, IconData icon, {bool bold = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: .11), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))), Text(_money(amount), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: amount < 0 ? const Color(0xFFD94E5A) : const Color(0xFF172033)))]));
  }

  Widget _tripCard(TripPlan trip) {
    final forecast = ProjectionService.forecastTrip(_profile, trip, scenario: _scenario);
    final progress = (trip.paidCents / trip.totalCostCents).clamp(0.0, 1.0).toDouble();
    return _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: const Color(0xFFFFEBD9), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('JP', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD47832)))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.name, style: Theme.of(context).textTheme.titleMedium),
                Text('${trip.destination} · ${trip.days} Tage', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          _statusPill(trip.isOverBudget ? 'Über Budget' : forecast.isOnTrack ? 'Im Plan' : 'Nachjustieren', !trip.isOverBudget && forecast.isOnTrack),
        ],
      ),
      const SizedBox(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Reisebudget'), Text(_money(trip.totalCostCents), style: const TextStyle(fontWeight: FontWeight.w700))]),
      if (trip.budgetLimitCents > 0) ...[
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Dein Limit'), Text(_money(trip.budgetLimitCents), style: const TextStyle(fontWeight: FontWeight.w700))]),
        const SizedBox(height: 4),
        Text(trip.isOverBudget ? 'Aktuell ${_money(-trip.budgetRemainingCents)} über deinem Limit' : '${_money(trip.budgetRemainingCents)} bleiben im Limit übrig', style: TextStyle(color: trip.isOverBudget ? const Color(0xFFD94E5A) : const Color(0xFF20966A), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: const Color(0xFFE9ECF4), color: const Color(0xFF5669E8))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${_money(trip.paidCents)} bezahlt', style: Theme.of(context).textTheme.bodyMedium), Text('${(progress * 100).round()} %', style: Theme.of(context).textTheme.bodyMedium)]),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE19A35)), const SizedBox(width: 10), Expanded(child: Text('Du brauchst ${_money(forecast.requiredMonthlySavingCents)} monatlich, damit am Reisetag auch die Reserve bleibt.', style: const TextStyle(fontSize: 13, height: 1.35)))])),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _openTrip(trip), icon: const Icon(Icons.edit_calendar_outlined, size: 18), label: const Text('Reise öffnen & bearbeiten'))),
    ]));
  }

  Widget _scenarioCard() {
    if (_profile.trips.isEmpty) {
      return _surface(child: const Text('Ein Szenario wird angezeigt, sobald du eine Reise angelegt hast.', style: TextStyle(color: Color(0xFF78839A))));
    }
    final trip = _profile.trips.first;
    final values = ForecastScenario.values.map((scenario) => ProjectionService.forecastTrip(_profile, trip, scenario: scenario).availableOnTripCents).toList();
    return _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [for (final scenario in ForecastScenario.values) ChoiceChip(label: Text(_scenarioName(scenario)), selected: _scenario == scenario, onSelected: (_) => setState(() => _scenario = scenario))]),
      const SizedBox(height: 20),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (var i = 0; i < values.length; i++) Expanded(child: Column(children: [AnimatedContainer(duration: const Duration(milliseconds: 350), height: 30 + (values[i].clamp(0, 250000).toDouble() / 250000 * 90), width: 34, decoration: BoxDecoration(color: i == _scenario.index ? const Color(0xFF5669E8) : const Color(0xFFDCE1FA), borderRadius: BorderRadius.circular(10))), const SizedBox(height: 8), Text(_money(values[i]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(_scenarioShort(ForecastScenario.values[i]), style: const TextStyle(fontSize: 11, color: Color(0xFF78839A)))]))]),
    ]));
  }

  Widget _tripsPage() => _pageScaffold('Reisen', 'Alle Ziele und ihre Finanzierung', [
        if (_profile.trips.isEmpty)
          _surface(child: const Text('Noch keine Reise angelegt. Plane dein erstes Ziel über den Button.', style: TextStyle(height: 1.4)))
        else
          ..._profile.trips.map(_tripCard),
      ]);

  Widget _cashflowPage() => _pageScaffold('Cashflow', 'Einnahmen und regelmäßige Ausgaben', [
        _cashflowCard(),
        const SizedBox(height: 12),
        _recurringCard(),
        const SizedBox(height: 12),
        if (_profile.entries.isEmpty)
          _surface(child: const Text('Noch keine einzelnen Buchungen. Füge Ausgaben und Einnahmen über den Button hinzu.', style: TextStyle(height: 1.4)))
        else
          _surface(child: Column(children: _profile.entries.reversed.map(_entryTile).toList())),
      ]);

  Widget _recurringCard() => _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Regelmäßige Bewegungen', style: Theme.of(context).textTheme.titleMedium)), TextButton.icon(onPressed: _showAddRecurring, icon: const Icon(Icons.add, size: 18), label: const Text('Neu'))]),
        const SizedBox(height: 8),
        ..._profile.recurringTransactions.map((item) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Icon(item.kind == TransactionKind.income ? Icons.autorenew_rounded : Icons.repeat_rounded, color: item.kind == TransactionKind.income ? const Color(0xFF20966A) : const Color(0xFFD94E5A)), title: Text(item.title), subtitle: Text('${item.frequency == TransactionFrequency.monthly ? 'monatlich' : item.frequency.name} · am ${item.dayOfMonth}.'), trailing: Text('${item.kind == TransactionKind.income ? '+' : '-'}${_money(item.amountCents)}', style: const TextStyle(fontWeight: FontWeight.w700))))
      ]));

  Widget _goalsPage() => _pageScaffold('Sparziele', 'Was möchtest du als Nächstes möglich machen?', [
        if (_profile.goals.isEmpty)
          _surface(child: const Text('Noch kein Sparziel angelegt. Lege ein Ziel mit Betrag und Deadline an.', style: TextStyle(height: 1.4)))
        else
          ..._profile.goals.map(_goalTile),
      ]);

  Widget _purchasesPage() => _pageScaffold('Anschaffungen', 'Plane Dinge, die du dir später leisten möchtest', [
        _purchaseSummary(),
        const SizedBox(height: 12),
        if (_profile.plannedPurchases.isEmpty)
          _surface(child: const Text('Noch keine geplante Anschaffung. Lege zum Beispiel einen Laptop, ein Fahrrad oder ein Geschenk an.', style: TextStyle(height: 1.4)))
        else
          ..._profile.plannedPurchases.map(_purchaseTile),
      ]);

  Widget _purchaseSummary() {
    final reserved = _profile.reservedPurchaseCents;
    return _surface(child: Row(children: [const Icon(Icons.event_available_rounded, color: Color(0xFF5669E8)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Verplant für Anschaffungen', style: Theme.of(context).textTheme.titleMedium), Text('${_money(reserved)} sind für zukünftige Käufe reserviert.', style: Theme.of(context).textTheme.bodyMedium)]))]));
  }

  Widget _purchaseTile(PlannedPurchase purchase) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Dismissible(key: ValueKey(purchase.id), direction: DismissDirection.endToStart, background: Container(color: const Color(0xFFFFE4E6), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD94E5A))), onDismissed: (_) async { setState(() => _profile = _profile.copyWith(plannedPurchases: _profile.plannedPurchases.where((item) => item.id != purchase.id).toList())); await _persistProfile(); }, child: _surface(child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF1FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF5669E8))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(purchase.title, style: Theme.of(context).textTheme.titleMedium), Text('${purchase.category} · geplant für ${_shortDate(purchase.desiredDate)}', style: Theme.of(context).textTheme.bodyMedium)])), Text(_money(purchase.amountCents), style: const TextStyle(fontWeight: FontWeight.w800))]))));

  Widget _entryTile(CashFlowEntry entry) => Dismissible(
        key: ValueKey(entry.id),
        background: Container(color: const Color(0xFFFFE4E6), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD94E5A))),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          setState(() => _profile = _profile.copyWith(entries: _profile.entries.where((item) => item.id != entry.id).toList(), currentBalanceCents: entry.isConfirmed ? _profile.currentBalanceCents - entry.signedAmountCents : null));
          await _persistProfile();
        },
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: (entry.kind == TransactionKind.income ? const Color(0xFF20966A) : const Color(0xFFD94E5A)).withValues(alpha: .1),
            child: Icon(entry.kind == TransactionKind.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: entry.kind == TransactionKind.income ? const Color(0xFF20966A) : const Color(0xFFD94E5A), size: 18),
          ),
          title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${entry.category} · ${_shortDate(entry.date)}${entry.isConfirmed ? ' · bestätigt' : ' · geplant'}'),
          trailing: Text('${entry.kind == TransactionKind.income ? '+' : '-'}${_money(entry.amountCents)}', style: TextStyle(fontWeight: FontWeight.w700, color: entry.kind == TransactionKind.income ? const Color(0xFF20966A) : const Color(0xFFD94E5A))),
        ),
      );

  Widget _goalTile(SavingsGoal goal) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(goal.name, style: Theme.of(context).textTheme.titleMedium)), Text(_money(goal.targetCents), style: const TextStyle(fontWeight: FontWeight.w700))]), const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: goal.progress, minHeight: 8, color: const Color(0xFF5669E8), backgroundColor: const Color(0xFFE9ECF4))), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${_money(goal.savedCents)} gespart'), Text('${(goal.progress * 100).round()} % · ${_money(goal.monthlyAllocationCents)}/Monat')])])));

  Widget _pageScaffold(String title, String subtitle, List<Widget> children) {
    return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 28, 20, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 26), ...children]))));
  }

  Widget _surface({required Widget child, Gradient? gradient}) => SquircleContainer(borderRadius: BorderRadius.circular(26), padding: const EdgeInsets.all(20), backgroundColor: gradient == null ? Colors.white : null, backgroundGradient: gradient, boxShadow: const [BoxShadow(color: Color(0x0D172033), blurRadius: 20, offset: Offset(0, 8))], child: child);

  Widget _sectionTitle(String title, String subtitle) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])), const Icon(Icons.more_horiz_rounded, color: Color(0xFF98A2B3))]);

  Widget _cardLabel(String text, Color color) => Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: color));

  Widget _statusPill(String label, bool positive) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (positive ? const Color(0xFF20966A) : const Color(0xFFE19A35)).withValues(alpha: .11), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: positive ? const Color(0xFF20966A) : const Color(0xFFE19A35))));

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  Future<void> _openTrip(TripPlan trip) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip, profile: _profile, onChanged: _replaceTrip, onDelete: () => _deleteTrip(trip))));
    if (mounted) setState(() {});
  }

  Future<void> _deleteTrip(TripPlan trip) async {
    setState(() => _profile = _profile.copyWith(trips: _profile.trips.where((item) => item.id != trip.id).toList()));
    await _persistProfile();
  }

  Future<void> _showSettings() async {
    final balanceController = TextEditingController(text: (_profile.currentBalanceCents / 100).toStringAsFixed(2));
    final reserveController = TextEditingController(text: (_profile.safetyReserveCents / 100).toStringAsFixed(2));
    final variableController = TextEditingController(text: (_profile.monthlyVariableBudgetCents / 100).toStringAsFixed(2));
    final values = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Finanzprofil', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Diese Werte bilden die Basis deiner Prognosen.'),
          const SizedBox(height: 18),
          TextField(controller: balanceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Aktuelles Guthaben')),
          const SizedBox(height: 12),
          TextField(controller: reserveController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Sicherheitsreserve')),
          const SizedBox(height: 12),
          TextField(controller: variableController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Alltagspuffer pro Monat')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final values = [_parseAmount(balanceController.text), _parseAmount(reserveController.text), _parseAmount(variableController.text)]; Navigator.pop(sheetContext, values); }, child: const Text('Profil speichern'))),
        ]),
      ),
    );
    if (values == null) return;
    setState(() => _profile = _profile.copyWith(currentBalanceCents: values[0], safetyReserveCents: values[1], monthlyVariableBudgetCents: values[2]));
    await _persistProfile();
  }

  Future<void> _showAddIncome() async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<int>(context: context, isScrollControlled: true, builder: (context) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Monatliches Plus', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 6), const Text('Wie viel kommt regelmäßig dazu?'), const SizedBox(height: 18), TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Betrag')), const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, ((double.tryParse(controller.text.replaceAll(',', '.')) ?? 0) * 100).round()), child: const Text('Übernehmen')))])));
    if (amount == null || amount <= 0) return;
    setState(() {
      final incomeTransactions = _profile.recurringTransactions.where((item) => item.kind == TransactionKind.income).toList();
      final existing = incomeTransactions.isEmpty ? null : incomeTransactions.first;
      final income = RecurringTransaction(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), title: existing?.title ?? 'Monatliches Plus', amountCents: amount, kind: TransactionKind.income, category: 'Einnahme', startsOn: existing?.startsOn ?? DateTime.now());
      final otherTransactions = _profile.recurringTransactions.where((item) => item.id != existing?.id).toList();
      _profile = _profile.copyWith(recurringTransactions: [income, ...otherTransactions]);
    });
    await _persistProfile();
  }

  Future<void> _showAddCashflow() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var kind = TransactionKind.expense;
    var confirmed = true;
    final entry = await showModalBottomSheet<CashFlowEntry>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Buchung hinzufügen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Titel', hintText: 'z. B. Zugticket', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Betrag', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionKind>(initialValue: kind, decoration: const InputDecoration(labelText: 'Art', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: TransactionKind.expense, child: Text('Ausgabe')), DropdownMenuItem(value: TransactionKind.income, child: Text('Einnahme'))], onChanged: (value) => setSheetState(() => kind = value ?? TransactionKind.expense)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: confirmed, title: const Text('Bereits bestätigt / bezahlt'), onChanged: (value) => setSheetState(() => confirmed = value ?? true)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, CashFlowEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), amountCents: amount, date: DateTime.now(), kind: kind, category: kind == TransactionKind.income ? 'Einnahme' : 'Sonstiges', isConfirmed: confirmed)); }, child: const Text('Buchung speichern'))),
          ]),
        ),
      ),
    );
    if (entry == null) return;
    setState(() => _profile = _profile.copyWith(entries: [..._profile.entries, entry], currentBalanceCents: entry.isConfirmed ? _profile.currentBalanceCents + entry.signedAmountCents : null));
    await _persistProfile();
  }

  Future<void> _showAddRecurring() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var kind = TransactionKind.expense;
    final item = await showModalBottomSheet<RecurringTransaction>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Regelmäßige Bewegung', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 18),
          TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Titel', hintText: 'z. B. Taschengeld oder Abo')),
          const SizedBox(height: 12),
          TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Betrag')),
          const SizedBox(height: 12),
          DropdownButtonFormField<TransactionKind>(initialValue: kind, decoration: const InputDecoration(labelText: 'Art'), items: const [DropdownMenuItem(value: TransactionKind.expense, child: Text('Ausgabe')), DropdownMenuItem(value: TransactionKind.income, child: Text('Einnahme'))], onChanged: (value) => kind = value ?? TransactionKind.expense),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, RecurringTransaction(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), amountCents: amount, kind: kind, category: kind == TransactionKind.income ? 'Einnahme' : 'Fixkosten', startsOn: DateTime.now())); }, child: const Text('Speichern'))),
        ]),
      ),
    );
    if (item == null) return;
    setState(() => _profile = _profile.copyWith(recurringTransactions: [..._profile.recurringTransactions, item]));
    await _persistProfile();
  }

  Future<void> _showAddPurchase() async {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Sonstiges');
    final amountController = TextEditingController();
    var desiredDate = DateTime.now().add(const Duration(days: 90));
    final purchase = await showModalBottomSheet<PlannedPurchase>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Anschaffung planen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Das Geld wird in deiner Übersicht reserviert und in Reiseprognosen berücksichtigt.'),
            const SizedBox(height: 18),
            TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Was möchtest du kaufen?', hintText: 'z. B. neuer Laptop')),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Preis'))), const SizedBox(width: 12), Expanded(child: TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategorie')))]),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.event_outlined, size: 20), const SizedBox(width: 8), Expanded(child: Text('Geplant für ${_shortDate(desiredDate)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: desiredDate); if (picked != null) setSheetState(() => desiredDate = picked); }, child: const Text('Ändern'))]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, PlannedPurchase(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), category: categoryController.text.trim().isEmpty ? 'Sonstiges' : categoryController.text.trim(), amountCents: amount, desiredDate: desiredDate)); }, child: const Text('Anschaffung speichern'))),
          ]),
        ),
      ),
    );
    if (purchase == null) return;
    setState(() => _profile = _profile.copyWith(plannedPurchases: [..._profile.plannedPurchases, purchase]));
    await _persistProfile();
  }

  Future<void> _showAddGoal() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final savedController = TextEditingController(text: '0');
    final monthlyController = TextEditingController();
    var deadline = DateTime.now().add(const Duration(days: 365));
    final goal = await showModalBottomSheet<SavingsGoal>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sparziel anlegen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name', hintText: 'z. B. Neuer Laptop', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextField(controller: targetController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Zielbetrag', border: OutlineInputBorder()))), const SizedBox(width: 12), Expanded(child: TextField(controller: monthlyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Pro Monat', border: OutlineInputBorder())))]),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.event_outlined, size: 20), const SizedBox(width: 8), Expanded(child: Text('Zieltermin: ${_shortDate(deadline)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: deadline); if (picked != null) setSheetState(() => deadline = picked); }, child: const Text('Ändern'))]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final target = _parseAmount(targetController.text); final monthly = _parseAmount(monthlyController.text); if (nameController.text.trim().isEmpty || target <= 0 || monthly <= 0) return; Navigator.pop(sheetContext, SavingsGoal(id: DateTime.now().microsecondsSinceEpoch.toString(), name: nameController.text.trim(), targetCents: target, savedCents: _parseAmount(savedController.text), deadline: deadline, monthlyAllocationCents: monthly)); }, child: const Text('Ziel speichern'))),
          ]),
        ),
      ),
    );
    if (goal == null) return;
    setState(() => _profile = _profile.copyWith(goals: [..._profile.goals, goal]));
    await _persistProfile();
  }

  Future<void> _showAddTrip() async {
    final nameController = TextEditingController();
    final destinationController = TextEditingController();
    final fixedController = TextEditingController();
    final dailyController = TextEditingController();
    final budgetController = TextEditingController();
    final paidController = TextEditingController(text: '0');
    var startsOn = DateTime.now().add(const Duration(days: 180));
    var endsOn = startsOn.add(const Duration(days: 7));
    final trip = await showModalBottomSheet<TripPlan>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reise planen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name', hintText: 'z. B. Japan 2026', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: destinationController, decoration: const InputDecoration(labelText: 'Ziel', hintText: 'z. B. Tokyo, Kyoto & Osaka', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: Text('Von ${_shortDate(startsOn)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: startsOn); if (picked != null) setSheetState(() { startsOn = picked; if (!endsOn.isAfter(startsOn)) endsOn = startsOn.add(const Duration(days: 1)); }); }, child: const Text('Start'))]),
            Row(children: [Expanded(child: Text('Bis ${_shortDate(endsOn)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: startsOn.add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: endsOn); if (picked != null) setSheetState(() => endsOn = picked); }, child: const Text('Ende'))]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: TextField(controller: fixedController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Feste Kosten', border: OutlineInputBorder()))), const SizedBox(width: 12), Expanded(child: TextField(controller: dailyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Pro Tag', border: OutlineInputBorder())))]),
            const SizedBox(height: 12),
            TextField(controller: budgetController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Maximales Reisebudget', hintText: 'z. B. 2000')),
            const SizedBox(height: 12),
            TextField(controller: paidController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Bereits bezahlt', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final fixed = _parseAmount(fixedController.text); final daily = _parseAmount(dailyController.text); if (nameController.text.trim().isEmpty || daily <= 0) return; Navigator.pop(sheetContext, TripPlan(id: DateTime.now().microsecondsSinceEpoch.toString(), name: nameController.text.trim(), destination: destinationController.text.trim(), startsOn: startsOn, endsOn: endsOn, fixedCostsCents: fixed, dailyBudgetCents: daily, budgetLimitCents: _parseAmount(budgetController.text), alreadyPaidCents: _parseAmount(paidController.text))); }, child: const Text('Reise speichern'))),
          ])),
        ),
      ),
    );
    if (trip == null) return;
    setState(() => _profile = _profile.copyWith(trips: [..._profile.trips, trip]));
    await _persistProfile();
    if (mounted) await _openTrip(trip);
  }

  Future<void> _showTripDetails(TripPlan trip) async {
    final forecast = ProjectionService.forecastTrip(_profile, trip, scenario: _scenario);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(trip.name, style: Theme.of(context).textTheme.headlineSmall),
          Text('${trip.destination} · ${trip.days} Tage', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          _flowLine('Unterkünfte', trip.segmentAccommodationCents, const Color(0xFF5669E8), Icons.hotel_outlined),
          _flowLine('Essen', trip.dailyCostsCents, const Color(0xFFE19A35), Icons.restaurant_outlined),
          _flowLine('Transport & Sonstiges', trip.segmentTransportCents + trip.segmentOtherCents + trip.expenseCents + trip.fixedCostsCents, const Color(0xFF78839A), Icons.train_outlined),
          _flowLine('Puffer', trip.bufferCents, const Color(0xFF98A2B3), Icons.shield_outlined),
          const Divider(height: 24),
          _flowLine('Gesamtbudget', trip.totalCostCents, const Color(0xFF172033), Icons.account_balance_wallet_outlined, bold: true),
          if (trip.budgetLimitCents > 0) _flowLine('Dein Budgetlimit', trip.budgetLimitCents, trip.isOverBudget ? const Color(0xFFD94E5A) : const Color(0xFF20966A), Icons.rule_rounded),
          _flowLine('Noch offen', trip.remainingCostCents, const Color(0xFFD94E5A), Icons.pending_actions_rounded),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEFF1FF), borderRadius: BorderRadius.circular(16)), child: Text('Am Reisetag bleiben im Szenario „${_scenarioName(_scenario)}“ voraussichtlich ${_money(forecast.availableOnTripCents)} nach Reserve, Reise und anderen Sparzielen.', style: const TextStyle(height: 1.35))),
          const SizedBox(height: 18),
          Row(children: [Expanded(child: Text('Reiseabschnitte', style: Theme.of(context).textTheme.titleMedium)), TextButton.icon(onPressed: () => _showAddSegment(trip), icon: const Icon(Icons.add, size: 18), label: const Text('Abschnitt'))]),
          if (trip.segments.isEmpty) const Text('Füge für jedes Hotel oder jede Stadt einen Abschnitt hinzu.', style: TextStyle(color: Color(0xFF78839A))) else ...trip.segments.map((segment) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.hotel_outlined, color: Color(0xFF5669E8)), title: Text('${segment.location} · ${segment.days} Tage'), subtitle: Text('${segment.accommodationName} · Essen ${_money(segment.dailyFoodBudgetCents)}/Tag'), trailing: Text(_money(segment.accommodationCostCents), style: const TextStyle(fontWeight: FontWeight.w700)))),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: Text('Geplante Reisekosten', style: Theme.of(context).textTheme.titleMedium)), TextButton.icon(onPressed: () => _showAddTripExpense(trip), icon: const Icon(Icons.add, size: 18), label: const Text('Kosten'))]),
          if (trip.expenses.isEmpty) const Text('Zum Beispiel Zugtickets, Eintrittskarten oder eine SIM-Karte.', style: TextStyle(color: Color(0xFF78839A))) else ...trip.expenses.map((expense) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFFE19A35)), title: Text(expense.title), subtitle: Text('${expense.category} · ${_shortDate(expense.date)}'), trailing: Text(_money(expense.amountCents), style: const TextStyle(fontWeight: FontWeight.w700)))),
        ])),
      ),
    );
  }

  Future<void> _showAddSegment(TripPlan trip) async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final hotelController = TextEditingController();
    final accommodationController = TextEditingController();
    final foodController = TextEditingController();
    final transportController = TextEditingController(text: '0');
    final otherController = TextEditingController(text: '0');
    var accommodationPaid = false;
    var startsOn = trip.startsOn;
    var endsOn = trip.endsOn.isAfter(startsOn) ? trip.endsOn : startsOn.add(const Duration(days: 1));
    final segment = await showModalBottomSheet<TripSegment>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reiseabschnitt hinzufügen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Abschnitt', hintText: 'z. B. Tokyo · Hotelphase')),
            const SizedBox(height: 10),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Ort', hintText: 'z. B. Tokyo')),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: Text('Von ${_shortDate(startsOn)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: trip.startsOn, lastDate: trip.endsOn, initialDate: startsOn); if (picked != null) setSheetState(() => startsOn = picked); }, child: const Text('Start'))]),
            Row(children: [Expanded(child: Text('Bis ${_shortDate(endsOn)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: startsOn.add(const Duration(days: 1)), lastDate: trip.endsOn.add(const Duration(days: 1)), initialDate: endsOn); if (picked != null) setSheetState(() => endsOn = picked); }, child: const Text('Ende'))]),
            TextField(controller: hotelController, decoration: const InputDecoration(labelText: 'Hotel / Unterkunft', hintText: 'z. B. Shibuya Hotel')),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: TextField(controller: accommodationController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Hotel gesamt'))), const SizedBox(width: 10), Expanded(child: TextField(controller: foodController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Essen / Tag')))]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: [ActionChip(label: const Text('Sparsam 20 €'), onPressed: () => setSheetState(() => foodController.text = '20')), ActionChip(label: const Text('Normal 35 €'), onPressed: () => setSheetState(() => foodController.text = '35')), ActionChip(label: const Text('Komfort 55 €'), onPressed: () => setSheetState(() => foodController.text = '55'))]),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: accommodationPaid, title: const Text('Unterkunft bereits bezahlt'), onChanged: (value) => setSheetState(() => accommodationPaid = value ?? false)),
            const SizedBox(height: 4),
            Row(children: [Expanded(child: TextField(controller: transportController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Transport'))), const SizedBox(width: 10), Expanded(child: TextField(controller: otherController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Sonstiges')))]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final food = _parseAmount(foodController.text); if (locationController.text.trim().isEmpty || hotelController.text.trim().isEmpty || food <= 0) return; Navigator.pop(sheetContext, TripSegment(id: DateTime.now().microsecondsSinceEpoch.toString(), name: nameController.text.trim().isEmpty ? locationController.text.trim() : nameController.text.trim(), location: locationController.text.trim(), startsOn: startsOn, endsOn: endsOn, accommodationName: hotelController.text.trim(), accommodationCostCents: _parseAmount(accommodationController.text), dailyFoodBudgetCents: food, transportCostCents: _parseAmount(transportController.text), otherCostCents: _parseAmount(otherController.text), accommodationPaid: accommodationPaid)); }, child: const Text('Abschnitt speichern'))),
          ])),
        ),
      ),
    );
    if (segment == null) return;
    await _replaceTrip(trip.copyWith(segments: [...trip.segments, segment]));
  }

  Future<void> _showAddTripExpense(TripPlan trip) async {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Transport');
    final amountController = TextEditingController();
    var date = trip.startsOn;
    final expense = await showModalBottomSheet<TripExpense>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reisekosten hinzufügen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Was möchtest du einplanen?', hintText: 'z. B. Zug Tokyo → Kyoto')),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Betrag'))), const SizedBox(width: 10), Expanded(child: TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategorie')))]),
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.event_outlined, size: 20), const SizedBox(width: 8), Expanded(child: Text('Geplant für ${_shortDate(date)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: trip.startsOn, lastDate: trip.endsOn, initialDate: date); if (picked != null) setSheetState(() => date = picked); }, child: const Text('Ändern'))]),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, TripExpense(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), category: categoryController.text.trim().isEmpty ? 'Sonstiges' : categoryController.text.trim(), amountCents: amount, date: date)); }, child: const Text('Kosten speichern'))),
          ]),
        ),
      ),
    );
    if (expense == null) return;
    await _replaceTrip(trip.copyWith(expenses: [...trip.expenses, expense]));
  }

  Future<void> _replaceTrip(TripPlan updated) async {
    setState(() => _profile = _profile.copyWith(trips: _profile.trips.map((trip) => trip.id == updated.id ? updated : trip).toList()));
    await _persistProfile();
  }

  String _greeting() { final hour = DateTime.now().hour; return hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend'; }
  String _scenarioName(ForecastScenario scenario) => switch (scenario) { ForecastScenario.cautious => 'Vorsichtig', ForecastScenario.realistic => 'Realistisch', ForecastScenario.optimistic => 'Optimistisch' };
  String _scenarioShort(ForecastScenario scenario) => switch (scenario) { ForecastScenario.cautious => 'Vorsicht', ForecastScenario.realistic => 'Realistisch', ForecastScenario.optimistic => 'Chance' };
  String _money(int cents) => '${cents < 0 ? '-' : ''}${(cents.abs() / 100).toStringAsFixed(0)} €';
  int _parseAmount(String value) => ((double.tryParse(value.replaceAll(',', '.')) ?? 0) * 100).round();
  String _shortDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  String _monthLabel(DateTime date) => '${const ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'][date.month - 1]} ${date.year}';
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(width: 230, color: Colors.white, padding: const EdgeInsets.fromLTRB(20, 30, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(left: 12, bottom: 36), child: Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFF5669E8)), SizedBox(width: 8), Text('Budget', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))])), _item(context, 0, Icons.grid_view_rounded, 'Übersicht'), _item(context, 1, Icons.flight_takeoff_rounded, 'Reisen'), _item(context, 2, Icons.swap_vert_rounded, 'Cashflow'), _item(context, 3, Icons.flag_outlined, 'Sparziele'), _item(context, 4, Icons.shopping_bag_outlined, 'Anschaffungen'), const Spacer(), const Padding(padding: EdgeInsets.all(12), child: Text('LOKAL & PRIVAT', style: TextStyle(fontSize: 10, letterSpacing: 1, color: Color(0xFF98A2B3), fontWeight: FontWeight.w700))), const Padding(padding: EdgeInsets.all(12), child: Text('Deine Daten bleiben auf deinem Gerät.', style: TextStyle(fontSize: 12, color: Color(0xFF98A2B3), height: 1.35)))]));
  }

  Widget _item(BuildContext context, int index, IconData icon, String label) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Material(color: Colors.transparent, child: ListTile(selected: selectedIndex == index, onTap: () => onSelect(index), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), selectedTileColor: const Color(0xFFEFF1FF), leading: Icon(icon, size: 20), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)))));
}
