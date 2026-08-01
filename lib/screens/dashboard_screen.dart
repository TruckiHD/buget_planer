import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/budget_planner_app.dart';
import '../data/local_storage_service.dart';
import '../models/finance_models.dart';
import '../services/export_service.dart';
import '../services/insights_service.dart';
import '../services/projection_service.dart';
import 'onboarding_screen.dart';
import 'trip_detail_screen.dart';
import '../utils/app_theme.dart';
import '../utils/squircle_container.dart';
import '../widgets/charts/balance_line_chart.dart';
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/charts/year_review_chart.dart';
import '../widgets/empty_state.dart';

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
  bool _showOnboarding = false;

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
      setState(() => _showOnboarding = true);
      return;
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    setState(() {
      _profile = saved;
      if (!onboardingDone && saved.recurringTransactions.isEmpty && saved.currentBalanceCents == 0) {
        _showOnboarding = true;
      }
    });
  }

  Future<void> _persistProfile() => _storage.saveProfile(_profile);

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        profile: _profile,
        onComplete: (updated) async {
          setState(() {
            _profile = updated;
            _showOnboarding = false;
          });
          await _persistProfile();
        },
      );
    }
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
                  onPressed: _selectedIndex == 0 ? _showAddIncome : _selectedIndex == 1 ? _openNewTrip : _selectedIndex == 2 ? _showAddCashflow : _selectedIndex == 3 ? _showAddGoal : _showAddPurchase,
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
              _insightsSection(),
              const SizedBox(height: 22),
              _responsiveOverview(desktop),
              const SizedBox(height: 22),
              _sectionTitle('Dein Monat', 'Was bleibt nach den festen Plänen?'),
              const SizedBox(height: 12),
              _monthPlanCard(),
              const SizedBox(height: 12),
              _cashflowCard(),
              const SizedBox(height: 22),
              _sectionTitle('Ausgaben nach Kategorie', 'Wo geht dein Geld hin?'),
              const SizedBox(height: 12),
              _categoryChartCard(),
              const SizedBox(height: 22),
              _sectionTitle('Kontostand-Prognose', 'Die nächsten 12 Monate'),
              const SizedBox(height: 12),
              _balanceChartCard(),
              const SizedBox(height: 22),
              _sectionTitle('Jahresrückblick', 'Dein Finanzjahr auf einen Blick'),
              const SizedBox(height: 12),
              _yearReviewCard(),
              const SizedBox(height: 22),
              _sectionTitle('Nächstes Ziel', 'Prognose statt Bauchgefühl'),
              const SizedBox(height: 12),
              if (_profile.trips.isEmpty)
                _surface(child: EmptyState(
                  icon: Icons.flight_takeoff_rounded,
                  title: 'Noch keine Reise geplant',
                  subtitle: 'Erstelle dein erstes Ziel über den Reisen-Bereich.',
                  isDark: _isDark,
                ))
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
              Text('Dein Finanzblick', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: _textColor)),
            ],
          ),
        ),
        IconButton(onPressed: _showSettings, icon: const Icon(Icons.tune_rounded)),
        CircleAvatar(
          radius: 20,
          backgroundColor: _chipBgColor,
          child: Text('G', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _setupCard() => _surface(child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: _chipBgColor, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.waving_hand_outlined, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Richte deinen Finanzblick ein', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('Trage Guthaben, Reserve und dein monatliches Plus ein. Danach werden deine Prognosen aussagekräftig.', style: Theme.of(context).textTheme.bodyMedium)])), TextButton(onPressed: _showSettings, child: const Text('Starten'))]));

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
        _cardLabel('MONATLICHER ÜBERSCHUSS', _mutedColor),
        const SizedBox(height: 12),
        Text(_money(surplus), style: TextStyle(color: surplus >= 0 ? AppColors.green : AppColors.red, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text('nach Fixkosten & Alltag', style: TextStyle(color: _mutedColor)),
        const SizedBox(height: 18),
        Row(children: [const Icon(Icons.trending_up_rounded, color: AppColors.green, size: 18), const SizedBox(width: 5), Text('${_money(_profile.monthlyIncomeCents)} Einnahmen / Monat', style: TextStyle(fontSize: 12, color: _mutedColor))]),
      ]),
    );
  }

  Widget _tripReadinessCard() {
    if (_profile.trips.isEmpty) {
      return _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NOCH KEINE REISE', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: _mutedColor)), const SizedBox(height: 12), Text('Lege eine Reise an, um den Reisetag zu prognostizieren.', style: TextStyle(color: _mutedColor))]));
    }
    final trip = _profile.trips.first;
    final forecast = ProjectionService.forecastTrip(_profile, trip, scenario: _scenario);
    return _surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('AM REISETAG', _mutedColor),
        const SizedBox(height: 12),
        Text(_money(forecast.availableOnTripCents), style: TextStyle(color: forecast.isOnTrack ? AppColors.green : AppColors.red, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(forecast.isOnTrack ? 'Puffer nach Reisebudget' : 'Es fehlen noch ${_money(-forecast.availableOnTripCents)}', style: TextStyle(color: _mutedColor)),
        const SizedBox(height: 18),
        Text('Tagesbudget ${_money(trip.dailyBudgetCents)}', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]),
    );
  }

  Widget _insightsSection() {
    final insights = InsightsService.generateInsights(_profile);
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Smart Insights', 'Automatische Erkenntnisse'),
        const SizedBox(height: 12),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _surface(child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: insight.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
                child: Icon(insight.icon, color: insight.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(insight.description, style: TextStyle(fontSize: 13, color: _mutedColor, height: 1.3)),
                ],
              )),
            ],
          )),
        )),
      ],
    );
  }

  Widget _categoryChartCard() {
    final spending = ProjectionService.categoryBudgetStatus(_profile, DateTime.now());
    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryDonutChart(data: spending, isDark: _isDark),
        const SizedBox(height: 12),
        ...spending.where((e) => e.spentCents > 0).take(5).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(e.category.icon, size: 16, color: e.category.color),
              const SizedBox(width: 8),
              Expanded(child: Text(e.category.label, style: const TextStyle(fontWeight: FontWeight.w500))),
              Text(_money(e.spentCents), style: const TextStyle(fontWeight: FontWeight.w700)),
              if (e.budgetLimitCents != null && e.budgetLimitCents! > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: e.isOverBudget ? AppColors.red.withValues(alpha: .12) : e.isNearBudget ? AppColors.amber.withValues(alpha: .12) : AppColors.green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(e.budgetUsage * 100).round()}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: e.isOverBudget ? AppColors.red : e.isNearBudget ? AppColors.amber : AppColors.green),
                  ),
                ),
              ],
            ],
          ),
        )),
      ],
    ));
  }

  Widget _balanceChartCard() {
    return _surface(child: BalanceLineChart(profile: _profile, isDark: _isDark));
  }

  Widget _yearReviewCard() {
    final review = ProjectionService.yearReview(_profile);
    final monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _miniStat('Einnahmen', _money(review.totalIncomeCents), AppColors.green)),
            Expanded(child: _miniStat('Ausgaben', _money(review.totalExpensesCents), AppColors.red)),
            Expanded(child: _miniStat('Sparquote', '${review.savingRatePercent}%', review.savingRatePercent >= 20 ? AppColors.green : AppColors.amber)),
          ],
        ),
        const SizedBox(height: 18),
        YearReviewChart(review: review, isDark: _isDark),
        if (review.bestSavingMonth > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Bester Sparmonat: ${monthNames[review.bestSavingMonth - 1]} mit ${_money(review.bestSavingCents)} Überschuss', style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ],
      ],
    ));
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: _mutedColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
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
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Voraussichtlich am Monatsende'), Text(_money(snapshot.projectedClosingBalanceCents), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textColor))]),
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
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: .11), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))), Text(_money(amount), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: amount < 0 ? AppColors.red : _textColor))]));
  }

  Widget _tripCard(TripPlan trip) {
    final forecast = ProjectionService.forecastTrip(_profile, trip, scenario: _scenario);
    final fundingProgress = trip.totalCostCents <= 0 ? 0.0 : (trip.paidCents / trip.totalCostCents).clamp(0.0, 1.0).toDouble();
    final costProgress = trip.budgetLimitCents <= 0 ? 0.0 : (trip.totalCostCents / trip.budgetLimitCents).clamp(0.0, 1.0).toDouble();
    return _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: _chipBgColor, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Icon(Icons.flight_takeoff_rounded, color: AppColors.primary)),
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
      Text('Kosten geplant · ${_money(trip.totalCostCents)} von ${trip.budgetLimitCents > 0 ? _money(trip.budgetLimitCents) : 'ohne Limit'}', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      if (trip.budgetLimitCents > 0)
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: costProgress, minHeight: 8, backgroundColor: const Color(0xFFE9ECF4), color: trip.isOverBudget ? const Color(0xFFD94E5A) : const Color(0xFF5669E8)))
      else
        const Text('Kein Budgetlimit gesetzt', style: TextStyle(fontSize: 12, color: Color(0xFF78839A))),
      const SizedBox(height: 10),
      Text('Finanziert · ${_money(trip.paidCents)} von ${_money(trip.totalCostCents)}', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: fundingProgress, minHeight: 6, backgroundColor: const Color(0xFFE9ECF4), color: const Color(0xFF20966A))),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _isDark ? AppColors.darkSurface2 : const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.lightbulb_outline_rounded, color: AppColors.amber), const SizedBox(width: 10), Expanded(child: Text('Du brauchst ${_money(forecast.requiredMonthlySavingCents)} monatlich, damit am Reisetag auch die Reserve bleibt.', style: const TextStyle(fontSize: 13, height: 1.35)))])),
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
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (var i = 0; i < values.length; i++) Expanded(child: Column(children: [AnimatedContainer(duration: const Duration(milliseconds: 350), height: 30 + (values[i].clamp(0, 250000).toDouble() / 250000 * 90), width: 34, decoration: BoxDecoration(color: i == _scenario.index ? AppColors.primary : _chipBgColor, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 8), Text(_money(values[i]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(_scenarioShort(ForecastScenario.values[i]), style: TextStyle(fontSize: 11, color: _mutedColor))]))]),
    ]));
  }

  Widget _tripsPage() => _pageScaffold('Reisen', 'Alle Ziele und ihre Finanzierung', [
        if (_profile.trips.isEmpty)
          _surface(child: EmptyState(
            icon: Icons.flight_takeoff_rounded,
            title: 'Noch keine Reise geplant',
            subtitle: 'Plane dein erstes Ziel und behalte die Kosten im Blick.',
            actionLabel: 'Reise anlegen',
            onAction: _openNewTrip,
            isDark: _isDark,
          ))
        else
          ..._profile.trips.map(_tripCard),
      ]);

  Widget _cashflowPage() => _pageScaffold('Cashflow', 'Einnahmen und regelmäßige Ausgaben', [
        _cashflowSummary(),
        const SizedBox(height: 12),
        _cashflowCard(),
        const SizedBox(height: 12),
        _recurringCard(),
        const SizedBox(height: 12),
        if (_profile.entries.isEmpty)
          _surface(child: EmptyState(
            icon: Icons.swap_vert_rounded,
            title: 'Noch keine Buchungen',
            subtitle: 'Füge Ausgaben und Einnahmen hinzu, um deinen Cashflow zu tracken.',
            actionLabel: 'Buchung hinzufügen',
            onAction: _showAddCashflow,
            isDark: _isDark,
          ))
        else
          _surface(child: Column(children: _profile.entries.reversed.map(_entryTile).toList())),
      ]);

  Widget _cashflowSummary() {
    final now = DateTime.now();
    final monthSpending = ProjectionService.categorySpending(_profile, now);
    final totalMonthExpenses = monthSpending.values.fold<int>(0, (sum, v) => sum + v);
    final monthIncome = _profile.monthlyIncomeCents;
    final surplus = monthIncome - totalMonthExpenses;
    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktueller Monat', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _miniStat('Einnahmen', _money(monthIncome), AppColors.green)),
          Expanded(child: _miniStat('Ausgaben', _money(totalMonthExpenses), AppColors.red)),
          Expanded(child: _miniStat('Überschuss', _money(surplus), surplus >= 0 ? AppColors.green : AppColors.red)),
        ]),
        if (totalMonthExpenses > 0) ...[
          const SizedBox(height: 16),
          Text('Top-Ausgaben', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _mutedColor)),
          const SizedBox(height: 8),
          ...monthSpending.entries.where((e) => e.value > 0).take(3).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(e.key.icon, size: 16, color: e.key.color),
              const SizedBox(width: 8),
              Expanded(child: Text(e.key.label, style: const TextStyle(fontSize: 13))),
              Text(_money(e.value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          )),
        ],
      ],
    ));
  }

  Widget _recurringCard() => _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Regelmäßige Bewegungen', style: Theme.of(context).textTheme.titleMedium)), TextButton.icon(onPressed: () => _showAddRecurring(), icon: const Icon(Icons.add, size: 18), label: const Text('Neu'))]),
        const SizedBox(height: 8),
        ..._profile.recurringTransactions.map((item) => Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(color: AppColors.red.withValues(alpha: .12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
          onDismissed: (_) async {
            setState(() => _profile = _profile.copyWith(recurringTransactions: _profile.recurringTransactions.where((t) => t.id != item.id).toList()));
            await _persistProfile();
          },
          child: ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: item.categoryColor.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(item.categoryIcon, size: 18, color: item.categoryColor)), title: Text(item.title), subtitle: Text('${item.categoryLabel} · ${_frequencyLabel(item.frequency)} · am ${item.dayOfMonth}.'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${item.kind == TransactionKind.income ? '+' : '-'}${_money(item.amountCents)}', style: const TextStyle(fontWeight: FontWeight.w700)), IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showAddRecurring(item), tooltip: 'Bearbeiten')])),
        )),
      ]));

  Widget _goalsPage() => _pageScaffold('Sparziele', 'Was möchtest du als Nächstes möglich machen?', [
        if (_profile.goals.isEmpty)
          _surface(child: EmptyState(
            icon: Icons.flag_outlined,
            title: 'Noch kein Sparziel',
            subtitle: 'Lege ein Ziel mit Betrag und Deadline an und verfolge deinen Fortschritt.',
            actionLabel: 'Ziel anlegen',
            onAction: _showAddGoal,
            isDark: _isDark,
          ))
        else
          ..._profile.goals.map(_goalTile),
      ]);

  Widget _purchasesPage() => _pageScaffold('Anschaffungen', 'Plane Dinge, die du dir später leisten möchtest', [
        _purchaseSummary(),
        const SizedBox(height: 12),
        if (_profile.plannedPurchases.isEmpty)
          _surface(child: EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Keine Anschaffungen geplant',
            subtitle: 'Plane zukünftige Käufe und behalte den Überblick über dein Budget.',
            actionLabel: 'Anschaffung planen',
            onAction: _showAddPurchase,
            isDark: _isDark,
          ))
        else
          ..._profile.plannedPurchases.map(_purchaseTile),
      ]);

  Widget _purchaseSummary() {
    final reserved = _profile.reservedPurchaseCents;
    return _surface(child: Row(children: [const Icon(Icons.event_available_rounded, color: AppColors.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Verplant für Anschaffungen', style: Theme.of(context).textTheme.titleMedium), Text('${_money(reserved)} sind für zukünftige Käufe reserviert.', style: Theme.of(context).textTheme.bodyMedium)]))]));
  }

  Widget _purchaseTile(PlannedPurchase purchase) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Dismissible(
      key: ValueKey(purchase.id),
      direction: DismissDirection.endToStart,
      background: Container(color: AppColors.red.withValues(alpha: .12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
      onDismissed: (_) async { setState(() => _profile = _profile.copyWith(plannedPurchases: _profile.plannedPurchases.where((item) => item.id != purchase.id).toList())); await _persistProfile(); },
      child: _surface(child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: purchase.category.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: Icon(purchase.category.icon, color: purchase.category.color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(purchase.title, style: Theme.of(context).textTheme.titleMedium),
          Text('${purchase.category.label} · geplant für ${_shortDate(purchase.desiredDate)}${purchase.isReserved ? ' · reserviert' : ' · nur geplant'}', style: Theme.of(context).textTheme.bodyMedium),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_money(purchase.amountCents), style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showAddPurchase(purchase), tooltip: 'Bearbeiten'),
        ]),
      ])),
    ),
  );

  Widget _entryTile(CashFlowEntry entry) => Dismissible(
        key: ValueKey(entry.id),
        background: Container(color: AppColors.red.withValues(alpha: .12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          setState(() => _profile = _profile.copyWith(entries: _profile.entries.where((item) => item.id != entry.id).toList(), currentBalanceCents: entry.isConfirmed ? _profile.currentBalanceCents - entry.signedAmountCents : null));
          await _persistProfile();
        },
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: entry.categoryColor.withValues(alpha: .12), shape: BoxShape.circle),
            child: Icon(entry.categoryIcon, color: entry.categoryColor, size: 18),
          ),
          title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${entry.categoryLabel} · ${_shortDate(entry.date)}${entry.isConfirmed ? ' · bestätigt' : ' · geplant'}'),
          trailing: Text('${entry.kind == TransactionKind.income ? '+' : '-'}${_money(entry.amountCents)}', style: TextStyle(fontWeight: FontWeight.w700, color: entry.kind == TransactionKind.income ? const Color(0xFF20966A) : const Color(0xFFD94E5A))),
        ),
      );

  Widget _goalTile(SavingsGoal goal) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(color: AppColors.red.withValues(alpha: .12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
      onDismissed: (_) async {
        setState(() => _profile = _profile.copyWith(goals: _profile.goals.where((g) => g.id != goal.id).toList()));
        await _persistProfile();
      },
      child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(goal.name, style: Theme.of(context).textTheme.titleMedium)),
          Text(_money(goal.targetCents), style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showAddGoal(goal), tooltip: 'Bearbeiten'),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: goal.progress, minHeight: 8, color: AppColors.primary, backgroundColor: _dividerColor)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${_money(goal.savedCents)} gespart'), Text('${(goal.progress * 100).round()} % · ${_money(goal.monthlyAllocationCents)}/Monat')])])),
    ),
  );
  Widget _pageScaffold(String title, String subtitle, List<Widget> children) {
    return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 28, 20, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.4, color: _textColor)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: _secondaryColor)), const SizedBox(height: 26), ...children]))));
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surfaceColor => _isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get _textColor => _isDark ? AppColors.darkText : AppColors.lightText;
  Color get _secondaryColor => _isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  Color get _mutedColor => _isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get _dividerColor => _isDark ? AppColors.darkDivider : AppColors.lightDivider;
  Color get _chipBgColor => _isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
  Color get _shadowColor => _isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow;

  Widget _surface({required Widget child, Gradient? gradient}) => SquircleContainer(
    borderRadius: BorderRadius.circular(26),
    padding: const EdgeInsets.all(20),
    backgroundColor: gradient == null ? _surfaceColor : null,
    backgroundGradient: gradient,
    boxShadow: [BoxShadow(color: _shadowColor, blurRadius: 20, offset: const Offset(0, 8))],
    child: child,
  );

  Widget _sectionTitle(String title, String subtitle) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])), Icon(Icons.more_horiz_rounded, color: _mutedColor)]);

  Widget _cardLabel(String text, Color color) => Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: color));

  Widget _statusPill(String label, bool positive) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (positive ? AppColors.green : AppColors.amber).withValues(alpha: .11), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: positive ? AppColors.green : AppColors.amber)));

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  Future<void> _openTrip(TripPlan trip) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip, profile: _profile, onChanged: _replaceTrip, onDelete: () => _deleteTrip(trip))));
    if (mounted) setState(() {});
  }

  Future<void> _openNewTrip() async {
    final now = DateTime.now();
    final draft = TripPlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Neue Reise',
      destination: '',
      startsOn: now.add(const Duration(days: 180)),
      endsOn: now.add(const Duration(days: 187)),
      fixedCostsCents: 0,
      dailyBudgetCents: 0,
    );
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: draft, profile: _profile, onChanged: _replaceTrip, onDelete: () async {})));
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
    final budgetControllers = <ExpenseCategory, TextEditingController>{};
    for (final cat in ExpenseCategory.values) {
      final existing = _profile.categoryBudgets.where((b) => b.category == cat).isEmpty ? null : _profile.categoryBudgets.firstWhere((b) => b.category == cat);
      budgetControllers[cat] = TextEditingController(text: existing != null ? _euros(existing.monthlyLimitCents) : '');
    }
    final values = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Finanzprofil', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Diese Werte bilden die Basis deiner Prognosen.'),
          const SizedBox(height: 18),
          TextField(controller: balanceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Aktuelles Guthaben')),
          const SizedBox(height: 12),
          TextField(controller: reserveController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Sicherheitsreserve')),
          const SizedBox(height: 12),
          TextField(controller: variableController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Alltagspuffer pro Monat')),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text('Kategorie-Budgets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Setze monatliche Limits pro Kategorie. Leer = kein Budget.', style: TextStyle(fontSize: 13, color: Color(0xFF78839A))),
          const SizedBox(height: 12),
          ...ExpenseCategory.values.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: budgetControllers[cat],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '€ ',
                labelText: cat.label,
                prefixIcon: Icon(cat.icon, size: 20, color: cat.color),
              ),
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final values = [_parseAmount(balanceController.text), _parseAmount(reserveController.text), _parseAmount(variableController.text)]; Navigator.pop(sheetContext, values); }, child: const Text('Profil speichern'))),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); _exportData(); }, icon: const Icon(Icons.upload_rounded, size: 18), label: const Text('Export'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); _importData(); }, icon: const Icon(Icons.download_rounded, size: 18), label: const Text('Import'))),
          ]),
        ])),
      ),
    );
    if (values == null) return;
    final budgets = <CategoryBudget>[];
    for (final cat in ExpenseCategory.values) {
      final amount = _parseAmount(budgetControllers[cat]!.text);
      if (amount > 0) budgets.add(CategoryBudget(category: cat, monthlyLimitCents: amount));
    }
    setState(() => _profile = _profile.copyWith(currentBalanceCents: values[0], safetyReserveCents: values[1], monthlyVariableBudgetCents: values[2], categoryBudgets: budgets));
    await _persistProfile();
  }

  Future<void> _exportData() async {
    final json = ExportService.exportToJson(_profile);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten exportieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dein Finanzprofil als JSON. Kopiere den Text und speichere ihn als Datei.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? AppColors.darkSurface2 : const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(json, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), maxLines: 10),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten importieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Füge den JSON-Text deines gespeicherten Profils ein.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'JSON hier einfügen...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Importieren')),
        ],
      ),
    );
    if (json == null || json.trim().isEmpty) return;
    final imported = ExportService.importFromJson(json);
    if (imported == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ungültiges Format. Bitte prüfe den JSON-Text.')));
      return;
    }
    setState(() => _profile = imported);
    await _persistProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daten erfolgreich importiert!')));
  }

  Future<void> _showAddIncome() async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<int>(context: context, isScrollControlled: true, builder: (context) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Monatliches Plus', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 6), const Text('Wie viel kommt regelmäßig dazu?'), const SizedBox(height: 18), TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Betrag')), const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, ((double.tryParse(controller.text.replaceAll(',', '.')) ?? 0) * 100).round()), child: const Text('Übernehmen')))])));
    if (amount == null || amount <= 0) return;
    setState(() {
      final incomeTransactions = _profile.recurringTransactions.where((item) => item.kind == TransactionKind.income).toList();
      final existing = incomeTransactions.isEmpty ? null : incomeTransactions.first;
      final income = RecurringTransaction(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), title: existing?.title ?? 'Monatliches Plus', amountCents: amount, kind: TransactionKind.income, incomeCategory: existing?.incomeCategory ?? IncomeCategory.gehalt, startsOn: existing?.startsOn ?? DateTime.now());
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
    ExpenseCategory expCat = ExpenseCategory.sonstiges;
    IncomeCategory incCat = IncomeCategory.sonstiges;
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
            const SizedBox(height: 12),
            if (kind == TransactionKind.expense)
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: expCat,
                decoration: const InputDecoration(labelText: 'Kategorie', border: OutlineInputBorder()),
                items: ExpenseCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Row(children: [Icon(cat.icon, size: 18, color: cat.color), const SizedBox(width: 8), Text(cat.label)]),
                )).toList(),
                onChanged: (value) => setSheetState(() => expCat = value ?? ExpenseCategory.sonstiges),
              )
            else
              DropdownButtonFormField<IncomeCategory>(
                initialValue: incCat,
                decoration: const InputDecoration(labelText: 'Kategorie', border: OutlineInputBorder()),
                items: IncomeCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Row(children: [Icon(cat.icon, size: 18, color: cat.color), const SizedBox(width: 8), Text(cat.label)]),
                )).toList(),
                onChanged: (value) => setSheetState(() => incCat = value ?? IncomeCategory.sonstiges),
              ),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: confirmed, title: const Text('Bereits bestätigt / bezahlt'), onChanged: (value) => setSheetState(() => confirmed = value ?? true)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, CashFlowEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), amountCents: amount, date: DateTime.now(), kind: kind, expenseCategory: kind == TransactionKind.expense ? expCat : null, incomeCategory: kind == TransactionKind.income ? incCat : null, isConfirmed: confirmed)); }, child: const Text('Buchung speichern'))),
          ]),
        ),
      ),
    );
    if (entry == null) return;
    setState(() => _profile = _profile.copyWith(entries: [..._profile.entries, entry], currentBalanceCents: entry.isConfirmed ? _profile.currentBalanceCents + entry.signedAmountCents : null));
    await _persistProfile();
  }

  Future<void> _showAddRecurring([RecurringTransaction? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(text: existing != null ? _euros(existing.amountCents) : '');
    var kind = existing?.kind ?? TransactionKind.expense;
    ExpenseCategory expCat = existing?.expenseCategory ?? ExpenseCategory.sonstiges;
    IncomeCategory incCat = existing?.incomeCategory ?? IncomeCategory.sonstiges;
    final item = await showModalBottomSheet<RecurringTransaction>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing != null ? 'Bewegung bearbeiten' : 'Regelmäßige Bewegung', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Titel', hintText: 'z. B. Taschengeld oder Abo')),
            const SizedBox(height: 12),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Betrag')),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionKind>(initialValue: kind, decoration: const InputDecoration(labelText: 'Art'), items: const [DropdownMenuItem(value: TransactionKind.expense, child: Text('Ausgabe')), DropdownMenuItem(value: TransactionKind.income, child: Text('Einnahme'))], onChanged: (value) => setSheetState(() => kind = value ?? TransactionKind.expense)),
            const SizedBox(height: 12),
            if (kind == TransactionKind.expense)
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: expCat,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: ExpenseCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Row(children: [Icon(cat.icon, size: 18, color: cat.color), const SizedBox(width: 8), Text(cat.label)]),
                )).toList(),
                onChanged: (value) => setSheetState(() => expCat = value ?? ExpenseCategory.sonstiges),
              )
            else
              DropdownButtonFormField<IncomeCategory>(
                initialValue: incCat,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: IncomeCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Row(children: [Icon(cat.icon, size: 18, color: cat.color), const SizedBox(width: 8), Text(cat.label)]),
                )).toList(),
                onChanged: (value) => setSheetState(() => incCat = value ?? IncomeCategory.sonstiges),
              ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, RecurringTransaction(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), amountCents: amount, kind: kind, expenseCategory: kind == TransactionKind.expense ? expCat : null, incomeCategory: kind == TransactionKind.income ? incCat : null, frequency: existing?.frequency ?? TransactionFrequency.monthly, dayOfMonth: existing?.dayOfMonth ?? 1, startsOn: existing?.startsOn ?? DateTime.now())); }, child: Text(existing != null ? 'Speichern' : 'Speichern'))),
          ]),
        ),
      ),
    );
    if (item == null) return;
    setState(() {
      final list = [..._profile.recurringTransactions];
      final idx = list.indexWhere((t) => t.id == item.id);
      if (idx >= 0) { list[idx] = item; } else { list.add(item); }
      _profile = _profile.copyWith(recurringTransactions: list);
    });
    await _persistProfile();
  }

  String _euros(int cents) => (cents / 100).toStringAsFixed(2);

  Future<void> _showAddPurchase([PlannedPurchase? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(text: existing != null ? _euros(existing.amountCents) : '');
    var desiredDate = existing?.desiredDate ?? DateTime.now().add(const Duration(days: 90));
    var reserveNow = existing?.isReserved ?? false;
    var category = existing?.category ?? ExpenseCategory.sonstiges;
    final purchase = await showModalBottomSheet<PlannedPurchase>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing != null ? 'Anschaffung bearbeiten' : 'Anschaffung planen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Der Kauf fließt in die Zukunftsprognose ein. Heute wird nur dann Geld blockiert, wenn du es ausdrücklich reservierst.'),
            const SizedBox(height: 18),
            TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Was möchtest du kaufen?', hintText: 'z. B. neuer Laptop')),
            const SizedBox(height: 12),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Preis')),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: ExpenseCategory.values.map((cat) => DropdownMenuItem(
                value: cat,
                child: Row(children: [Icon(cat.icon, size: 18, color: cat.color), const SizedBox(width: 8), Text(cat.label)]),
              )).toList(),
              onChanged: (value) => setSheetState(() => category = value ?? ExpenseCategory.sonstiges),
            ),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.event_outlined, size: 20), const SizedBox(width: 8), Expanded(child: Text('Geplant für ${_shortDate(desiredDate)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: desiredDate); if (picked != null) setSheetState(() => desiredDate = picked); }, child: const Text('Ändern'))]),
            const SizedBox(height: 12),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: reserveNow, title: const Text('Betrag jetzt reservieren'), onChanged: (value) => setSheetState(() => reserveNow = value ?? false)),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, PlannedPurchase(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), category: category, amountCents: amount, desiredDate: desiredDate, isReserved: reserveNow, isPurchased: existing?.isPurchased ?? false)); }, child: Text(existing != null ? 'Speichern' : 'Anschaffung speichern'))),
          ]),
        ),
      ),
    );
    if (purchase == null) return;
    setState(() {
      final list = [..._profile.plannedPurchases];
      final idx = list.indexWhere((p) => p.id == purchase.id);
      if (idx >= 0) { list[idx] = purchase; } else { list.add(purchase); }
      _profile = _profile.copyWith(plannedPurchases: list);
    });
    await _persistProfile();
  }

  Future<void> _showAddGoal([SavingsGoal? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final targetController = TextEditingController(text: existing != null ? _euros(existing.targetCents) : '');
    final savedController = TextEditingController(text: existing != null ? _euros(existing.savedCents) : '0');
    final monthlyController = TextEditingController(text: existing != null ? _euros(existing.monthlyAllocationCents) : '');
    var deadline = existing?.deadline ?? DateTime.now().add(const Duration(days: 365));
    final goal = await showModalBottomSheet<SavingsGoal>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing != null ? 'Sparziel bearbeiten' : 'Sparziel anlegen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name', hintText: 'z. B. Neuer Laptop', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextField(controller: targetController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Zielbetrag', border: OutlineInputBorder()))), const SizedBox(width: 12), Expanded(child: TextField(controller: monthlyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Pro Monat', border: OutlineInputBorder())))]),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.event_outlined, size: 20), const SizedBox(width: 8), Expanded(child: Text('Zieltermin: ${_shortDate(deadline)}')), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: deadline); if (picked != null) setSheetState(() => deadline = picked); }, child: const Text('Ändern'))]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final target = _parseAmount(targetController.text); final monthly = _parseAmount(monthlyController.text); if (nameController.text.trim().isEmpty || target <= 0 || monthly <= 0) return; Navigator.pop(sheetContext, SavingsGoal(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), name: nameController.text.trim(), targetCents: target, savedCents: _parseAmount(savedController.text), deadline: deadline, monthlyAllocationCents: monthly)); }, child: Text(existing != null ? 'Speichern' : 'Ziel speichern'))),
          ]),
        ),
      ),
    );
    if (goal == null) return;
    setState(() {
      final list = [..._profile.goals];
      final idx = list.indexWhere((g) => g.id == goal.id);
      if (idx >= 0) { list[idx] = goal; } else { list.add(goal); }
      _profile = _profile.copyWith(goals: list);
    });
    await _persistProfile();
  }





  Future<void> _replaceTrip(TripPlan updated) async {
    final exists = _profile.trips.any((trip) => trip.id == updated.id);
    final trips = exists
        ? _profile.trips.map((trip) => trip.id == updated.id ? updated : trip).toList()
        : [..._profile.trips, updated];
    setState(() => _profile = _profile.copyWith(trips: trips));
    await _persistProfile();
  }

  String _greeting() { final hour = DateTime.now().hour; return hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend'; }
  String _scenarioName(ForecastScenario scenario) => switch (scenario) { ForecastScenario.cautious => 'Vorsichtig', ForecastScenario.realistic => 'Realistisch', ForecastScenario.optimistic => 'Optimistisch' };
  String _scenarioShort(ForecastScenario scenario) => switch (scenario) { ForecastScenario.cautious => 'Vorsicht', ForecastScenario.realistic => 'Realistisch', ForecastScenario.optimistic => 'Chance' };
  String _frequencyLabel(TransactionFrequency freq) => switch (freq) { TransactionFrequency.monthly => 'monatlich', TransactionFrequency.weekly => 'wöchentlich', TransactionFrequency.yearly => 'jährlich', TransactionFrequency.once => 'einmalig' };
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 245,
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 30, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 12, bottom: 36), child: Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Budget', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? AppColors.darkText : AppColors.lightText)),
        ])),
        _item(context, 0, Icons.grid_view_rounded, 'Übersicht'),
        _item(context, 1, Icons.flight_takeoff_rounded, 'Reisen'),
        _item(context, 2, Icons.swap_vert_rounded, 'Cashflow'),
        _item(context, 3, Icons.flag_outlined, 'Sparziele'),
        _item(context, 4, Icons.shopping_bag_outlined, 'Anschaffungen'),
        const Spacer(),
        _themeToggle(context),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.all(12), child: Text('LOKAL & PRIVAT', style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.darkMuted, fontWeight: FontWeight.w700))),
        Padding(padding: const EdgeInsets.all(12), child: Text('Deine Daten bleiben auf deinem Gerät.', style: TextStyle(fontSize: 12, color: AppColors.darkMuted, height: 1.35))),
      ]),
    );
  }

  Widget _themeToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            SharedPreferences.getInstance().then((prefs) => prefs.setInt('theme_mode', themeNotifier.value.index));
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
          title: Text(isDark ? 'Light Mode' : 'Dark Mode', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon, String label) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Material(color: Colors.transparent, child: ListTile(selected: selectedIndex == index, onTap: () => onSelect(index), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), selectedTileColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkChipBg : const Color(0xFFEFF1FF), leading: Icon(icon, size: 20), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))));
}
