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
              _dashboardCollapsible(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Ausgaben nach Kategorie',
                initiallyExpanded: false,
                child: _categoryChartCard(),
              ),
              const SizedBox(height: 12),
              _dashboardCollapsible(
                icon: Icons.show_chart_rounded,
                title: 'Kontostand-Prognose',
                initiallyExpanded: false,
                child: _balanceChartCard(),
              ),
              const SizedBox(height: 12),
              _dashboardCollapsible(
                icon: Icons.calendar_month_rounded,
                title: 'Jahresrückblick',
                initiallyExpanded: false,
                child: _yearReviewCard(),
              ),
              const SizedBox(height: 12),
              _dashboardCollapsible(
                icon: Icons.science_outlined,
                title: 'Szenario testen',
                initiallyExpanded: false,
                child: _scenarioCard(),
              ),
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
          child: _insightCard(insight),
        )),
      ],
    );
  }

  Widget _insightCard(Insight insight) {
    final isDark = _isDark;
    final bgColor = isDark
        ? insight.color.withValues(alpha: .08)
        : insight.color.withValues(alpha: .04);
    final accentColor = insight.color;
    
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _shadowColor, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(insight.icon, color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(insight.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textColor)),
                            const SizedBox(height: 4),
                            Text(insight.description, style: TextStyle(fontSize: 13, color: _mutedColor, height: 1.4)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _insightTypeLabel(insight.type),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _insightTypeLabel(InsightType type) => switch (type) {
    InsightType.warning => 'Achtung',
    InsightType.success => 'Gut',
    InsightType.info => 'Info',
    InsightType.tip => 'Tipp',
  };

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
      if (snapshot.plannedEntriesCents != 0) _flowLine('Geplante Buchungen', snapshot.plannedEntriesCents, snapshot.plannedEntriesCents >= 0 ? const Color(0xFF20966A) : const Color(0xFFE19A35), Icons.event_note_rounded),
      if (snapshot.plannedPurchasesCents > 0) _flowLine('Geplante Anschaffungen', -snapshot.plannedPurchasesCents, const Color(0xFFE19A35), Icons.shopping_bag_outlined),
      if (snapshot.plannedTripCostsCents > 0) _flowLine('Reisezahlungen', -snapshot.plannedTripCostsCents, const Color(0xFF5669E8), Icons.flight_takeoff_rounded),
      const Divider(height: 20),
      _flowLine('Frei nach allen Reservierungen', snapshot.freeAfterPlansCents, snapshot.freeAfterPlansCents >= 0 ? const Color(0xFF20966A) : const Color(0xFFD94E5A), Icons.account_balance_wallet_outlined, bold: true),
    ]));
  }

  Widget _flowLine(String label, int amount, Color color, IconData icon, {bool bold = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: .11), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))), Text(_money(amount), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: amount < 0 ? AppColors.red : _textColor))]));
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

  Widget _tripsPage() {
    final sortedTrips = [..._profile.trips]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    final totalCost = _profile.trips.fold<int>(0, (sum, trip) => sum + trip.totalCostCents);
    final totalPaid = _profile.trips.fold<int>(0, (sum, trip) => sum + trip.paidCents);
    final nextTrip = sortedTrips.where((t) => t.startsOn.isAfter(DateTime.now())).isEmpty
        ? sortedTrips.lastOrNull
        : sortedTrips.firstWhere((t) => t.startsOn.isAfter(DateTime.now()));
    
    return _pageScaffold('Reisen', 'Alle Ziele und ihre Finanzierung', [
      if (_profile.trips.isEmpty)
        _surface(child: EmptyState(
          icon: Icons.flight_takeoff_rounded,
          title: 'Noch keine Reise geplant',
          subtitle: 'Plane dein erstes Ziel und behalte die Kosten im Blick.',
          actionLabel: 'Reise anlegen',
          onAction: _openNewTrip,
          isDark: _isDark,
        ))
      else ...[
        _tripsKPIs(totalCost, totalPaid, nextTrip),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _sectionTitle('Timeline', 'Alle Reisen chronologisch')),
            FilledButton.icon(
              onPressed: _openNewTrip,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Reise hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _tripsTimeline(sortedTrips),
      ],
    ]);
  }

  Widget _tripsKPIs(int totalCost, int totalPaid, TripPlan? nextTrip) {
    return Row(children: [
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('REISEN', _mutedColor),
        const SizedBox(height: 8),
        Text('${_profile.trips.length}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 4),
        Text('geplant', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('GESAMTKOSTEN', _mutedColor),
        const SizedBox(height: 8),
        Text(_money(totalCost), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 4),
        Text('${_money(totalPaid)} bezahlt', style: TextStyle(fontSize: 12, color: AppColors.green)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('NÄCHSTE REISE', _mutedColor),
        const SizedBox(height: 8),
        Text(nextTrip != null ? _shortDate(nextTrip.startsOn) : '–', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(nextTrip?.name ?? 'Keine', style: TextStyle(fontSize: 12, color: _mutedColor), overflow: TextOverflow.ellipsis),
      ]))),
    ]);
  }

  Widget _tripsTimeline(List<TripPlan> sortedTrips) {
    return Column(
      children: [
        for (var i = 0; i < sortedTrips.length; i++)
          _timelineItem(sortedTrips[i], isFirst: i == 0, isLast: i == sortedTrips.length - 1),
      ],
    );
  }

  Widget _timelineItem(TripPlan trip, {required bool isFirst, required bool isLast}) {
    final now = DateTime.now();
    final isActive = trip.startsOn.isBefore(now) && trip.endsOn.isAfter(now);
    final isPast = trip.endsOn.isBefore(now);
    final isFuture = trip.startsOn.isAfter(now);
    final statusColor = isActive ? AppColors.primary : isPast ? _mutedColor : AppColors.green;
    final statusLabel = isActive ? 'Aktuell' : isPast ? 'Abgeschlossen' : 'Geplant';
    
    final fundingProgress = trip.totalCostCents <= 0 ? 0.0 : (trip.paidCents / trip.totalCostCents).clamp(0.0, 1.0).toDouble();
    final costProgress = trip.budgetLimitCents <= 0 ? 0.0 : (trip.totalCostCents / trip.budgetLimitCents).clamp(0.0, 1.0).toDouble();
    final daysUntil = trip.startsOn.difference(now).inDays;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _surfaceColor, width: 3),
                    boxShadow: [BoxShadow(color: statusColor.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: _dividerColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _surface(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                      const SizedBox(width: 8),
                      if (isFuture && daysUntil > 0)
                        Text('in $daysUntil Tagen', style: TextStyle(fontSize: 12, color: _mutedColor)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _openTrip(trip),
                        tooltip: 'Bearbeiten',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(trip.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textColor)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 14, color: _mutedColor),
                    const SizedBox(width: 4),
                    Text(trip.destination.isEmpty ? 'Kein Ziel' : trip.destination, style: TextStyle(fontSize: 13, color: _mutedColor)),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today_rounded, size: 14, color: _mutedColor),
                    const SizedBox(width: 4),
                    Text('${_shortDate(trip.startsOn)} – ${_shortDate(trip.endsOn)}', style: TextStyle(fontSize: 13, color: _mutedColor)),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded, size: 14, color: _mutedColor),
                    const SizedBox(width: 4),
                    Text('${trip.days} Tage', style: TextStyle(fontSize: 13, color: _mutedColor)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Budget', style: TextStyle(fontSize: 12, color: _mutedColor)),
                        Text(_money(trip.totalCostCents), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: costProgress, minHeight: 6, backgroundColor: _dividerColor, color: trip.isOverBudget ? AppColors.red : AppColors.primary)),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Finanziert', style: TextStyle(fontSize: 12, color: _mutedColor)),
                        Text(_money(trip.paidCents), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: fundingProgress, minHeight: 6, backgroundColor: _dividerColor, color: AppColors.green)),
                    ])),
                  ]),
                  if (trip.budgetLimitCents > 0) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(trip.isOverBudget ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, size: 16, color: trip.isOverBudget ? AppColors.red : AppColors.green),
                      const SizedBox(width: 6),
                      Text(
                        trip.isOverBudget
                            ? '${_money(-trip.budgetRemainingCents)} über Limit'
                            : '${_money(trip.budgetRemainingCents)} im Limit',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: trip.isOverBudget ? AppColors.red : AppColors.green),
                      ),
                    ]),
                  ],
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cashflowPage() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final monthSpending = ProjectionService.categorySpending(_profile, now);
    final totalMonthExpenses = monthSpending.values.fold<int>(0, (sum, v) => sum + v);
    final monthIncome = _profile.monthlyIncomeCents;
    
    final plannedIncome = _profile.entries
        .where((e) => !e.isConfirmed && e.kind == TransactionKind.income && e.date.year == currentMonth.year && e.date.month == currentMonth.month)
        .fold<int>(0, (sum, e) => sum + e.amountCents);
    final plannedExpenses = _profile.entries
        .where((e) => !e.isConfirmed && e.kind == TransactionKind.expense && e.date.year == currentMonth.year && e.date.month == currentMonth.month)
        .fold<int>(0, (sum, e) => sum + e.amountCents);
    
    final totalIncome = monthIncome + plannedIncome;
    final totalExpenses = totalMonthExpenses + plannedExpenses;
    final surplus = totalIncome - totalExpenses;
    
    final totalEntries = _profile.entries.length;
    final confirmedEntries = _profile.entries.where((e) => e.isConfirmed).length;
    
    final sortedEntries = [..._profile.entries]..sort((a, b) => b.date.compareTo(a.date));
    final groupedEntries = _groupByMonth(sortedEntries);
    
    return _pageScaffold('Cashflow', 'Einnahmen und regelmäßige Ausgaben', [
      _cashflowKPIs(totalIncome, totalExpenses, surplus, totalEntries, confirmedEntries, plannedIncome, plannedExpenses),
      const SizedBox(height: 24),
      _recurringCard(),
      const SizedBox(height: 24),
      if (_profile.entries.isEmpty)
        _surface(child: EmptyState(
          icon: Icons.swap_vert_rounded,
          title: 'Noch keine Buchungen',
          subtitle: 'Füge Ausgaben und Einnahmen hinzu, um deinen Cashflow zu tracken.',
          actionLabel: 'Buchung hinzufügen',
          onAction: _showAddCashflow,
          isDark: _isDark,
        ))
      else ...[
        Row(
          children: [
            Expanded(child: _sectionTitle('Buchungen', 'Alle Transaktionen chronologisch')),
            FilledButton.icon(
              onPressed: _showAddCashflow,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Buchung hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _cashflowTimeline(groupedEntries),
      ],
    ]);
  }

  Widget _cashflowKPIs(int totalIncome, int totalExpenses, int surplus, int totalEntries, int confirmedEntries, int plannedIncome, int plannedExpenses) {
    return Row(children: [
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('EINNAHMEN', _mutedColor),
        const SizedBox(height: 8),
        Text(_money(totalIncome), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.green)),
        const SizedBox(height: 4),
        if (plannedIncome > 0)
          Text('+${_money(plannedIncome)} geplant', style: TextStyle(fontSize: 12, color: AppColors.amber))
        else
          Text('diesen Monat', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('AUSGABEN', _mutedColor),
        const SizedBox(height: 8),
        Text(_money(totalExpenses), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.red)),
        const SizedBox(height: 4),
        if (plannedExpenses > 0)
          Text('+${_money(plannedExpenses)} geplant', style: TextStyle(fontSize: 12, color: AppColors.amber))
        else
          Text('diesen Monat', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('ÜBERSCHUSS', _mutedColor),
        const SizedBox(height: 8),
        Text(_money(surplus), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: surplus >= 0 ? AppColors.green : AppColors.red)),
        const SizedBox(height: 4),
        Text('$confirmedEntries/$totalEntries bestätigt', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]))),
    ]);
  }

  Map<String, List<CashFlowEntry>> _groupByMonth(List<CashFlowEntry> entries) {
    final grouped = <String, List<CashFlowEntry>>{};
    for (final entry in entries) {
      final key = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  Widget _cashflowTimeline(Map<String, List<CashFlowEntry>> groupedEntries) {
    final monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    
    return Column(
      children: [
        for (final entry in groupedEntries.entries) ...[
          _surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${monthNames[int.parse(entry.key.split('-')[1]) - 1]} ${entry.key.split('-')[0]}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const Spacer(),
                  Text('${entry.value.length} Buchungen', style: TextStyle(fontSize: 12, color: _mutedColor)),
                ],
              ),
              const SizedBox(height: 12),
              ...entry.value.map(_entryTile),
            ],
          )),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _recurringCard() => _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Regelmäßige Bewegungen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${_profile.recurringTransactions.length} Positionen', style: TextStyle(fontSize: 12, color: _mutedColor)),
          ])),
          TextButton.icon(onPressed: () => _showAddRecurring(), icon: const Icon(Icons.add, size: 18), label: const Text('Neu')),
        ]),
        const SizedBox(height: 12),
        if (_profile.recurringTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Keine regelmäßigen Bewegungen', style: TextStyle(color: _mutedColor))),
          )
        else
          ..._profile.recurringTransactions.map((item) => Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(color: AppColors.red.withValues(alpha: .12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
            onDismissed: (_) async {
              setState(() => _profile = _profile.copyWith(recurringTransactions: _profile.recurringTransactions.where((t) => t.id != item.id).toList()));
              await _persistProfile();
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDark ? AppColors.darkSurface2 : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: item.categoryColor.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(item.categoryIcon, size: 18, color: item.categoryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textColor)),
                    const SizedBox(height: 2),
                    Text('${item.categoryLabel} · ${_frequencyLabel(item.frequency)} · am ${item.dayOfMonth}.', style: TextStyle(fontSize: 12, color: _mutedColor)),
                  ])),
                  Text('${item.kind == TransactionKind.income ? '+' : '-'}${_money(item.amountCents)}', style: TextStyle(fontWeight: FontWeight.w700, color: item.kind == TransactionKind.income ? AppColors.green : AppColors.red)),
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showAddRecurring(item), tooltip: 'Bearbeiten', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
              ),
            ),
          )),
      ]));

  Widget _goalsPage() {
    final sortedGoals = [..._profile.goals]..sort((a, b) => a.deadline.compareTo(b.deadline));
    final totalTarget = _profile.goals.fold<int>(0, (sum, g) => sum + g.targetCents);
    final totalSaved = _profile.goals.fold<int>(0, (sum, g) => sum + g.savedCents);
    final avgProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
    final reachedGoals = _profile.goals.where((g) => g.progress >= 1.0).length;
    
    return _pageScaffold('Sparziele', 'Was möchtest du als Nächstes möglich machen?', [
      if (_profile.goals.isEmpty)
        _surface(child: EmptyState(
          icon: Icons.flag_outlined,
          title: 'Noch kein Sparziel',
          subtitle: 'Lege ein Ziel mit Betrag und Deadline an und verfolge deinen Fortschritt.',
          actionLabel: 'Ziel anlegen',
          onAction: _showAddGoal,
          isDark: _isDark,
        ))
      else ...[
        _goalsKPIs(totalTarget, totalSaved, avgProgress, reachedGoals),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _sectionTitle('Timeline', 'Alle Ziele chronologisch')),
            FilledButton.icon(
              onPressed: _showAddGoal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ziel hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _goalsTimeline(sortedGoals),
      ],
    ]);
  }

  Widget _goalsKPIs(int totalTarget, int totalSaved, double avgProgress, int reachedGoals) {
    return Row(children: [
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('ZIELE', _mutedColor),
        const SizedBox(height: 8),
        Text('${_profile.goals.length}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 4),
        Text('$reachedGoals erreicht', style: TextStyle(fontSize: 12, color: AppColors.green)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('GESAMTZIEL', _mutedColor),
        const SizedBox(height: 8),
        Text(_money(totalTarget), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 4),
        Text('${_money(totalSaved)} gespart', style: TextStyle(fontSize: 12, color: AppColors.green)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('FORTSCHRITT', _mutedColor),
        const SizedBox(height: 8),
        Text('${(avgProgress * 100).round()}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: avgProgress >= 0.8 ? AppColors.green : avgProgress >= 0.5 ? AppColors.amber : AppColors.primary)),
        const SizedBox(height: 4),
        Text('Ø Fortschritt', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]))),
    ]);
  }

  Widget _goalsTimeline(List<SavingsGoal> sortedGoals) {
    return Column(
      children: [
        for (var i = 0; i < sortedGoals.length; i++)
          _goalTimelineItem(sortedGoals[i], isFirst: i == 0, isLast: i == sortedGoals.length - 1),
      ],
    );
  }

  Widget _goalTimelineItem(SavingsGoal goal, {required bool isFirst, required bool isLast}) {
    final now = DateTime.now();
    final isReached = goal.progress >= 1.0;
    final daysUntil = goal.deadline.difference(now).inDays;
    final isOverdue = daysUntil < 0 && !isReached;
    final monthsLeft = (daysUntil / 30).ceil().clamp(0, 120);
    final neededPerMonth = monthsLeft > 0 ? (goal.remainingCents / monthsLeft).ceil() : goal.remainingCents;
    final onTrack = neededPerMonth <= goal.monthlyAllocationCents;
    
    final statusColor = isReached ? AppColors.green : isOverdue ? AppColors.red : onTrack ? AppColors.primary : AppColors.amber;
    final statusLabel = isReached ? 'Erreicht' : isOverdue ? 'Überfällig' : onTrack ? 'Im Plan' : 'Nachjustieren';
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _surfaceColor, width: 3),
                    boxShadow: [BoxShadow(color: statusColor.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: _dividerColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Dismissible(
                key: ValueKey(goal.id),
                direction: DismissDirection.endToStart,
                background: Container(decoration: BoxDecoration(color: AppColors.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
                onDismissed: (_) async {
                  setState(() => _profile = _profile.copyWith(goals: _profile.goals.where((g) => g.id != goal.id).toList()));
                  await _persistProfile();
                },
                child: _surface(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.flag_rounded, size: 14, color: _mutedColor),
                        const SizedBox(width: 4),
                        Text(_shortDate(goal.deadline), style: TextStyle(fontSize: 12, color: _mutedColor)),
                        if (!isReached && daysUntil > 0) ...[
                          const SizedBox(width: 8),
                          Text('in $daysUntil Tagen', style: TextStyle(fontSize: 12, color: _mutedColor)),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showAddGoal(goal),
                          tooltip: 'Bearbeiten',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(goal.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textColor)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('Ziel: ${_money(goal.targetCents)}', style: TextStyle(fontSize: 13, color: _mutedColor)),
                      const SizedBox(width: 16),
                      Text('${_money(goal.savedCents)} gespart', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
                      const SizedBox(width: 16),
                      Text('${_money(goal.monthlyAllocationCents)}/Monat', style: TextStyle(fontSize: 13, color: _mutedColor)),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: goal.progress, minHeight: 10, color: statusColor, backgroundColor: _dividerColor)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${(goal.progress * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: statusColor)),
                      if (!isReached && !onTrack)
                        Text('Bräuchte ${_money(neededPerMonth)}/Monat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amber)),
                      if (isReached)
                        Text('Geschafft!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ]),
                  ],
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _purchasesPage() {
    final sortedPurchases = [..._profile.plannedPurchases]..sort((a, b) => a.desiredDate.compareTo(b.desiredDate));
    final totalCost = _profile.plannedPurchases.fold<int>(0, (sum, p) => sum + p.amountCents);
    final reservedCost = _profile.plannedPurchases.where((p) => p.isReserved).fold<int>(0, (sum, p) => sum + p.amountCents);
    final purchasedCount = _profile.plannedPurchases.where((p) => p.isPurchased).length;
    
    return _pageScaffold('Anschaffungen', 'Plane Dinge, die du dir später leisten möchtest', [
      if (_profile.plannedPurchases.isEmpty)
        _surface(child: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Keine Anschaffungen geplant',
          subtitle: 'Plane zukünftige Käufe und behalte den Überblick über dein Budget.',
          actionLabel: 'Anschaffung planen',
          onAction: _showAddPurchase,
          isDark: _isDark,
        ))
      else ...[
        _purchasesKPIs(totalCost, reservedCost, purchasedCount),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _sectionTitle('Timeline', 'Alle Anschaffungen chronologisch')),
            FilledButton.icon(
              onPressed: _showAddPurchase,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Anschaffung planen'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _purchasesTimeline(sortedPurchases),
      ],
    ]);
  }

  Widget _purchasesKPIs(int totalCost, int reservedCost, int purchasedCount) {
    return Row(children: [
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('ANSCHAFFUNGEN', _mutedColor),
        const SizedBox(height: 8),
        Text('${_profile.plannedPurchases.length}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 4),
        Text('$purchasedCount gekauft', style: TextStyle(fontSize: 12, color: AppColors.green)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('GESAMTKOSTEN', _mutedColor),
        const SizedBox(height: 8),
        Text(_money(totalCost), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 4),
        Text('${_money(reservedCost)} reserviert', style: TextStyle(fontSize: 12, color: AppColors.green)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel('RESERVIERT', _mutedColor),
        const SizedBox(height: 8),
        Text(totalCost > 0 ? '${(reservedCost / totalCost * 100).round()}%' : '0%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: reservedCost > 0 ? AppColors.green : _mutedColor)),
        const SizedBox(height: 4),
        Text('des Gesamtbetrags', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]))),
    ]);
  }

  Widget _purchasesTimeline(List<PlannedPurchase> sortedPurchases) {
    return Column(
      children: [
        for (var i = 0; i < sortedPurchases.length; i++)
          _purchaseTimelineItem(sortedPurchases[i], isFirst: i == 0, isLast: i == sortedPurchases.length - 1),
      ],
    );
  }

  Widget _purchaseTimelineItem(PlannedPurchase purchase, {required bool isFirst, required bool isLast}) {
    final now = DateTime.now();
    final daysUntil = purchase.desiredDate.difference(now).inDays;
    final isPast = daysUntil < 0;
    final isPurchased = purchase.isPurchased;
    final isReserved = purchase.isReserved;
    
    final statusColor = isPurchased ? AppColors.green : isPast ? AppColors.red : isReserved ? AppColors.primary : AppColors.amber;
    final statusLabel = isPurchased ? 'Gekauft' : isPast ? 'Überfällig' : isReserved ? 'Reserviert' : 'Geplant';
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _surfaceColor, width: 3),
                    boxShadow: [BoxShadow(color: statusColor.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: _dividerColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Dismissible(
                key: ValueKey(purchase.id),
                direction: DismissDirection.endToStart,
                background: Container(decoration: BoxDecoration(color: AppColors.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
                onDismissed: (_) async {
                  setState(() => _profile = _profile.copyWith(plannedPurchases: _profile.plannedPurchases.where((p) => p.id != purchase.id).toList()));
                  await _persistProfile();
                },
                child: _surface(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: purchase.category.color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(purchase.category.icon, size: 12, color: purchase.category.color),
                            const SizedBox(width: 4),
                            Text(purchase.category.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: purchase.category.color)),
                          ]),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showAddPurchase(purchase),
                          tooltip: 'Bearbeiten',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(purchase.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textColor)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: _mutedColor),
                      const SizedBox(width: 4),
                      Text(_shortDate(purchase.desiredDate), style: TextStyle(fontSize: 13, color: _mutedColor)),
                      if (!isPurchased && daysUntil > 0) ...[
                        const SizedBox(width: 8),
                        Text('in $daysUntil Tagen', style: TextStyle(fontSize: 13, color: _mutedColor)),
                      ],
                      const Spacer(),
                      Text(_money(purchase.amountCents), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textColor)),
                    ]),
                  ],
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(CashFlowEntry entry) => Dismissible(
        key: ValueKey(entry.id),
        background: Container(color: AppColors.red.withValues(alpha: .12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: AppColors.red)),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          setState(() => _profile = _profile.copyWith(entries: _profile.entries.where((item) => item.id != entry.id).toList(), currentBalanceCents: entry.isConfirmed ? _profile.currentBalanceCents - entry.signedAmountCents : null));
          await _persistProfile();
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDark ? AppColors.darkSurface2 : AppColors.lightBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: entry.categoryColor.withValues(alpha: .12), shape: BoxShape.circle),
                child: Icon(entry.categoryIcon, color: entry.categoryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textColor)),
                const SizedBox(height: 2),
                Text('${entry.categoryLabel} · ${_shortDate(entry.date)}', style: TextStyle(fontSize: 12, color: _mutedColor)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.isConfirmed ? AppColors.green.withValues(alpha: .12) : AppColors.amber.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry.isConfirmed ? 'Bestätigt' : 'Geplant', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: entry.isConfirmed ? AppColors.green : AppColors.amber)),
              ),
              const SizedBox(width: 8),
              Text('${entry.kind == TransactionKind.income ? '+' : '-'}${_money(entry.amountCents)}', style: TextStyle(fontWeight: FontWeight.w700, color: entry.kind == TransactionKind.income ? AppColors.green : AppColors.red)),
            ]),
          ),
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

  Widget _dashboardCollapsible({
    required IconData icon,
    required String title,
    required bool initiallyExpanded,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _shadowColor, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            initiallyExpanded: initiallyExpanded,
            leading: Icon(icon, color: AppColors.primary, size: 20),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            shape: const Border(),
            children: [child],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)]))]);

  Widget _cardLabel(String text, Color color) => Text(text, style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: color));

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


  Future<void> _showAddCashflow() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var kind = TransactionKind.expense;
    var confirmed = true;
    ExpenseCategory expCat = ExpenseCategory.sonstiges;
    IncomeCategory incCat = IncomeCategory.sonstiges;
    var selectedDate = DateTime.now();
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
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setSheetState(() => selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Datum', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today_rounded, size: 20)),
                child: Text(_shortDate(selectedDate)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setSheetState(() => selectedDate = DateTime.now()),
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: const Text('Heute'),
                ),
              ),
            ]),
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
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = _parseAmount(amountController.text); if (titleController.text.trim().isEmpty || amount <= 0) return; Navigator.pop(sheetContext, CashFlowEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), amountCents: amount, date: selectedDate, kind: kind, expenseCategory: kind == TransactionKind.expense ? expCat : null, incomeCategory: kind == TransactionKind.income ? incCat : null, isConfirmed: confirmed)); }, child: const Text('Buchung speichern'))),
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
