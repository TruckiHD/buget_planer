import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/squircle_container.dart';
import '../widgets/trip/trip_basics_form.dart';
import '../widgets/trip/trip_budget_header.dart';
import '../widgets/trip/trip_expense_editor.dart';
import '../widgets/trip/trip_expense_tile.dart';
import '../widgets/trip/trip_map.dart';
import '../widgets/trip/trip_segment_editor.dart';
import '../widgets/trip/trip_segment_tile.dart';
import '../widgets/trip/trip_transport_section.dart';
import '../widgets/trip_timeline.dart';

class TripDetailScreen extends StatefulWidget {
  final TripPlan trip;
  final FinancialProfile profile;
  final Future<void> Function(TripPlan trip) onChanged;
  final Future<void> Function() onDelete;

  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.profile,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late TripPlan _trip;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surfaceColor => _isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get _shadowColor => _isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_trip.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (_trip.destination.isNotEmpty)
                  Text(_trip.destination, style: TextStyle(fontSize: 12, color: _isDark ? AppColors.darkMuted : AppColors.lightMuted)),
              ],
            )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reise kopieren',
            onPressed: _copyTrip,
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Reise löschen',
            onPressed: _deleteTrip,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;
        final content = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(desktop ? 44 : 20, 12, desktop ? 44 : 20, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: desktop ? 1180 : 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  TripBudgetHeader(trip: _trip, isDark: _isDark),
                  const SizedBox(height: 12),
                  _collapsibleSection(
                    icon: Icons.edit_note_rounded,
                    title: 'Reisegrundlagen',
                    initiallyExpanded: false,
                    child: TripBasicsForm(trip: _trip, onChanged: _onTripChanged),
                  ),
                  const SizedBox(height: 12),
                  TripMap(trip: _trip, isDark: _isDark, forceShow: true),
                  const SizedBox(height: 12),
                  if (_trip.segments.isNotEmpty)
                    _collapsibleSection(
                      icon: Icons.calendar_month_rounded,
                      title: 'Timeline',
                      initiallyExpanded: false,
                      child: _surface(child: TripTimeline(trip: _trip, isDark: _isDark)),
                    ),
                  if (_trip.segments.isNotEmpty) const SizedBox(height: 12),
                  _collapsibleSection(
                    icon: Icons.train_rounded,
                    title: 'Verbindungen',
                    initiallyExpanded: false,
                    child: TripTransportSection(trip: _trip, isDark: _isDark, onChanged: _onTripChanged),
                  ),
                  const SizedBox(height: 12),
                  _collapsibleSection(
                    icon: Icons.hotel_outlined,
                    title: 'Abschnitte & Hotels',
                    initiallyExpanded: true,
                    child: _segmentsContent(),
                  ),
                  const SizedBox(height: 12),
                  _collapsibleSection(
                    icon: Icons.receipt_long_outlined,
                    title: 'Einzelne Reisekosten',
                    initiallyExpanded: false,
                    child: _expensesContent(),
                  ),
                ],
              ),
            ),
          ),
        );
        return content;
      }),
    );
  }

  Widget _collapsibleSection({
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

  Widget _surface({required Widget child}) => SquircleContainer(
    borderRadius: BorderRadius.circular(16),
    padding: const EdgeInsets.all(16),
    backgroundColor: _isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC),
    boxShadow: const [],
    child: child,
  );

  Widget _segmentsContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: _addSegment,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Abschnitt'),
        ),
      ),
      if (_trip.segments.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Noch keine Hotels oder Städte eingetragen.', style: TextStyle(color: _isDark ? AppColors.darkMuted : AppColors.lightMuted)),
        )
      else
        ...([..._trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn))).map((s) => TripSegmentTile(
          segment: s,
          onEdit: () => _editSegment(s),
          onTogglePaid: () => _toggleSegmentPaid(s),
          onDelete: () => _removeSegment(s),
        )),
    ]);
  }

  Widget _expensesContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: _addExpense,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Kosten'),
        ),
      ),
      if (_trip.expenses.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Züge, SIM-Karten, Eintrittskarten und andere Kosten.', style: TextStyle(color: _isDark ? AppColors.darkMuted : AppColors.lightMuted)),
        )
      else
        ..._trip.expenses.map((e) => TripExpenseTile(
          expense: e,
          onEdit: () => _editExpense(e),
          onTogglePaid: () => _toggleExpensePaid(e),
          onDelete: () => _removeExpense(e),
        )),
    ]);
  }

  Future<void> _onTripChanged(TripPlan updated) async {
    setState(() => _trip = updated);
    await widget.onChanged(updated);
  }

  Future<void> _addSegment() async {
    final segment = await showSegmentEditor(context, _trip);
    if (segment == null) return;
    await _onTripChanged(_trip.copyWith(segments: [..._trip.segments, segment]));
  }

  Future<void> _editSegment(TripSegment segment) async {
    final updated = await showSegmentEditor(context, _trip, existing: segment);
    if (updated == null) return;
    final segments = _trip.segments.map((s) => s.id == segment.id ? updated : s).toList();
    await _onTripChanged(_trip.copyWith(segments: segments));
  }

  Future<void> _toggleSegmentPaid(TripSegment segment) async {
    final segments = _trip.segments.map((s) => s.id == segment.id ? s.copyWith(accommodationPaid: !s.accommodationPaid) : s).toList();
    await _onTripChanged(_trip.copyWith(segments: segments));
  }

  Future<void> _removeSegment(TripSegment segment) async {
    final segments = _trip.segments.where((s) => s.id != segment.id).toList();
    await _onTripChanged(_trip.copyWith(segments: segments));
  }

  Future<void> _addExpense() async {
    final expense = await showExpenseEditor(context, _trip);
    if (expense == null) return;
    await _onTripChanged(_trip.copyWith(expenses: [..._trip.expenses, expense]));
  }

  Future<void> _editExpense(TripExpense expense) async {
    final updated = await showExpenseEditor(context, _trip, existing: expense);
    if (updated == null) return;
    final expenses = _trip.expenses.map((e) => e.id == expense.id ? updated : e).toList();
    await _onTripChanged(_trip.copyWith(expenses: expenses));
  }

  Future<void> _toggleExpensePaid(TripExpense expense) async {
    final expenses = _trip.expenses.map((e) => e.id == expense.id ? TripExpense(id: e.id, title: e.title, category: e.category, amountCents: e.amountCents, date: e.date, isPaid: !e.isPaid) : e).toList();
    await _onTripChanged(_trip.copyWith(expenses: expenses));
  }

  Future<void> _removeExpense(TripExpense expense) async {
    final expenses = _trip.expenses.where((e) => e.id != expense.id).toList();
    await _onTripChanged(_trip.copyWith(expenses: expenses));
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          title: const Text('Reise löschen?'),
          content: Text('"${_trip.name}" und alle zugehörigen Kosten werden gelöscht.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await widget.onDelete();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _copyTrip() async {
    final now = DateTime.now();
    final offset = _trip.endsOn.difference(_trip.startsOn);
    final newStart = DateTime(now.year + 1, _trip.startsOn.month, _trip.startsOn.day);
    final newEnd = newStart.add(offset);
    final copied = TripPlan(
      id: now.microsecondsSinceEpoch.toString(),
      name: '${_trip.name} (Kopie)',
      destination: _trip.destination,
      startsOn: newStart,
      endsOn: newEnd,
      fixedCostsCents: _trip.fixedCostsCents,
      dailyBudgetCents: _trip.dailyBudgetCents,
      budgetLimitCents: _trip.budgetLimitCents,
      bufferPercent: _trip.bufferPercent,
      segments: _trip.segments.map((s) => TripSegment(
        id: '${now.microsecondsSinceEpoch}_${s.id}',
        name: s.name,
        location: s.location,
        startsOn: newStart.add(s.startsOn.difference(_trip.startsOn)),
        endsOn: newStart.add(s.endsOn.difference(_trip.startsOn)),
        accommodationName: s.accommodationName,
        accommodationCostCents: s.accommodationCostCents,
        dailyFoodBudgetCents: s.dailyFoodBudgetCents,
        transportCostCents: s.transportCostCents,
        otherCostCents: s.otherCostCents,
        latitude: s.latitude,
        longitude: s.longitude,
      )).toList(),
      expenses: _trip.expenses.map((e) => TripExpense(
        id: '${now.microsecondsSinceEpoch}_${e.id}',
        title: e.title,
        category: e.category,
        amountCents: e.amountCents,
        date: newStart.add(e.date.difference(_trip.startsOn)),
      )).toList(),
    );
    await widget.onChanged(copied);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reise kopiert!')));
      Navigator.pop(context);
    }
  }
}
