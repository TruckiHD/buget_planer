import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/projection_service.dart';
import '../utils/squircle_container.dart';

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
  late final TextEditingController _nameController;
  late final TextEditingController _destinationController;
  late final TextEditingController _fixedController;
  late final TextEditingController _dailyController;
  late final TextEditingController _limitController;
  late final TextEditingController _paidController;

  String? _editingSegmentId;
  String? _editingExpenseId;
  bool _showSegmentEditor = false;
  bool _showExpenseEditor = false;
  bool _segmentPaid = false;
  bool _expensePaid = false;
  late DateTime _tripStartsOn;
  late DateTime _tripEndsOn;
  late DateTime _segmentStartsOn;
  late DateTime _segmentEndsOn;
  late DateTime _expenseDate;

  late final TextEditingController _segmentNameController;
  late final TextEditingController _segmentLocationController;
  late final TextEditingController _hotelController;
  late final TextEditingController _hotelCostController;
  late final TextEditingController _foodController;
  late final TextEditingController _transportController;
  late final TextEditingController _otherController;
  late final TextEditingController _expenseTitleController;
  late final TextEditingController _expenseCategoryController;
  late final TextEditingController _expenseAmountController;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _nameController = TextEditingController(text: _trip.name);
    _destinationController = TextEditingController(text: _trip.destination);
    _fixedController = TextEditingController(text: _euros(_trip.fixedCostsCents));
    _dailyController = TextEditingController(text: _euros(_trip.dailyBudgetCents));
    _limitController = TextEditingController(text: _trip.budgetLimitCents == 0 ? '' : _euros(_trip.budgetLimitCents));
    _paidController = TextEditingController(text: _euros(_trip.alreadyPaidCents));
    _segmentNameController = TextEditingController();
    _segmentLocationController = TextEditingController();
    _hotelController = TextEditingController();
    _hotelCostController = TextEditingController();
    _foodController = TextEditingController();
    _transportController = TextEditingController(text: '0');
    _otherController = TextEditingController(text: '0');
    _expenseTitleController = TextEditingController();
    _expenseCategoryController = TextEditingController(text: 'Transport');
    _expenseAmountController = TextEditingController();
    _tripStartsOn = _trip.startsOn;
    _tripEndsOn = _trip.endsOn;
    _segmentStartsOn = _trip.startsOn;
    _segmentEndsOn = _trip.endsOn;
    _expenseDate = _trip.startsOn;
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _destinationController,
      _fixedController,
      _dailyController,
      _limitController,
      _paidController,
      _segmentNameController,
      _segmentLocationController,
      _hotelController,
      _hotelCostController,
      _foodController,
      _transportController,
      _otherController,
      _expenseTitleController,
      _expenseCategoryController,
      _expenseAmountController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forecast = ProjectionService.forecastTrip(_profileForForecast, _trip);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reise bearbeiten'),
        actions: [
          IconButton(
            tooltip: 'Reise löschen',
            onPressed: _deleteTrip,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 850;
          final content = SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _budgetHeader(forecast),
                const SizedBox(height: 18),
                _tripBasics(),
                const SizedBox(height: 18),
                _segmentsSection(),
                const SizedBox(height: 18),
                _expensesSection(),
              ],
            ),
          );
          return Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: desktop ? 1180 : 700), child: content));
        },
      ),
    );
  }

  FinancialProfile get _profileForForecast => widget.profile.copyWith(
        trips: widget.profile.trips.map((trip) => trip.id == _trip.id ? _trip : trip).toList(),
      );

  Widget _budgetHeader(TripForecast forecast) {
    final overLimit = _trip.isOverBudget;
    return _surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_trip.name, style: Theme.of(context).textTheme.headlineSmall), Text('${_trip.destination} · ${_trip.days} Tage', style: Theme.of(context).textTheme.bodyMedium)])),
          _statusPill(overLimit ? 'Über Budget' : 'Im Budget', !overLimit),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _metric('Budgetlimit', _trip.budgetLimitCents <= 0 ? 'Kein Limit' : _money(_trip.budgetLimitCents), const Color(0xFF5669E8))),
          Expanded(child: _metric('Geplant', _money(_trip.totalCostCents), overLimit ? const Color(0xFFD94E5A) : const Color(0xFF20966A))),
          Expanded(child: _metric('Übrig', _trip.budgetLimitCents <= 0 ? '–' : _money(_trip.budgetRemainingCents), overLimit ? const Color(0xFFD94E5A) : const Color(0xFF20966A))),
        ]),
        const SizedBox(height: 16),
        if (_trip.budgetLimitCents > 0) ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_trip.totalCostCents / _trip.budgetLimitCents).clamp(0.0, 1.0).toDouble(), minHeight: 9, backgroundColor: const Color(0xFFE9ECF4), color: overLimit ? const Color(0xFFD94E5A) : const Color(0xFF5669E8))),
        const SizedBox(height: 12),
        Text('Noch offene Reiseplanung: ${_money(_trip.remainingCostCents)}', style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }

  Widget _tripBasics() => _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reisegrundlagen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: _destinationController, decoration: const InputDecoration(labelText: 'Ziel / Regionen')),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _dateButton('Start', _tripStartsOn, () => _pickTripDate(true))), const SizedBox(width: 10), Expanded(child: _dateButton('Ende', _tripEndsOn, () => _pickTripDate(false)))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: _limitController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Maximales Budget'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _paidController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Bereits bezahlt')))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: _fixedController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Globale feste Kosten'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _dailyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Basis-Essen / Tag')))]),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _saveTripBasics, icon: const Icon(Icons.save_outlined), label: const Text('Grundlagen speichern'))),
      ]));

  Widget _segmentsSection() => _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Abschnitte & Hotels', style: Theme.of(context).textTheme.titleMedium)), OutlinedButton.icon(onPressed: () => _beginSegmentEdit(), icon: const Icon(Icons.add, size: 18), label: const Text('Abschnitt'))]),
        const SizedBox(height: 8),
        if (_trip.segments.isEmpty) const Text('Noch keine Hotels oder Städte eingetragen.', style: TextStyle(color: Color(0xFF78839A))) else ..._trip.segments.map(_segmentTile),
        if (_showSegmentEditor) ...[
          const Divider(height: 28),
          Text(_editingSegmentId == null ? 'Neuen Abschnitt anlegen' : 'Abschnitt bearbeiten', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _segmentNameController, decoration: const InputDecoration(labelText: 'Abschnittsname', hintText: 'z. B. Tokyo · Shibuya')),
          const SizedBox(height: 10),
          TextField(controller: _segmentLocationController, decoration: const InputDecoration(labelText: 'Ort')),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: _dateButton('Von', _segmentStartsOn, () => _pickSegmentDate(true))), const SizedBox(width: 10), Expanded(child: _dateButton('Bis', _segmentEndsOn, () => _pickSegmentDate(false)))]),
          const SizedBox(height: 10),
          TextField(controller: _hotelController, decoration: const InputDecoration(labelText: 'Hotel / Unterkunft')),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: TextField(controller: _hotelCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Hotel gesamt'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _foodController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Essen / Tag')))]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: [ActionChip(label: const Text('20 € sparsam'), onPressed: () => setState(() => _foodController.text = '20')), ActionChip(label: const Text('35 € normal'), onPressed: () => setState(() => _foodController.text = '35')), ActionChip(label: const Text('55 € komfortabel'), onPressed: () => setState(() => _foodController.text = '55'))]),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: _segmentPaid, title: const Text('Hotel bereits bezahlt'), onChanged: (value) => setState(() => _segmentPaid = value ?? false)),
          Row(children: [Expanded(child: TextField(controller: _transportController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Transport'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _otherController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Sonstiges')))]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: _cancelSegmentEdit, child: const Text('Abbrechen')), const SizedBox(width: 8), FilledButton(onPressed: _saveSegment, child: const Text('Abschnitt speichern'))]),
        ],
      ]));

  Widget _expensesSection() => _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Einzelne Reisekosten', style: Theme.of(context).textTheme.titleMedium)), OutlinedButton.icon(onPressed: _beginExpenseEdit, icon: const Icon(Icons.add, size: 18), label: const Text('Kosten'))]),
        const SizedBox(height: 8),
        if (_trip.expenses.isEmpty) const Text('Züge, SIM-Karten, Eintrittskarten und andere Kosten gehören hier hinein.', style: TextStyle(color: Color(0xFF78839A))) else ..._trip.expenses.map(_expenseTile),
        if (_showExpenseEditor) ...[
          const Divider(height: 28),
          Text(_editingExpenseId == null ? 'Neue Kosten planen' : 'Kosten bearbeiten', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _expenseTitleController, decoration: const InputDecoration(labelText: 'Bezeichnung', hintText: 'z. B. Zug Tokyo → Kyoto')),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: TextField(controller: _expenseAmountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Preis'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _expenseCategoryController, decoration: const InputDecoration(labelText: 'Kategorie')))]),
          const SizedBox(height: 10),
          _dateButton('Geplant für', _expenseDate, _pickExpenseDate),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: _expensePaid, title: const Text('Bereits bezahlt'), onChanged: (value) => setState(() => _expensePaid = value ?? false)),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: _cancelExpenseEdit, child: const Text('Abbrechen')), const SizedBox(width: 8), FilledButton(onPressed: _saveExpense, child: const Text('Kosten speichern'))]),
        ],
      ]));

  Widget _segmentTile(TripSegment segment) => Dismissible(key: ValueKey(segment.id), direction: DismissDirection.endToStart, background: _deleteBackground(), onDismissed: (_) => _removeSegment(segment), child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.hotel_outlined, color: Color(0xFF5669E8)), title: Text('${segment.location} · ${segment.days} Tage'), subtitle: Text('${segment.accommodationName} · ${_money(segment.accommodationCostCents)} · Essen ${_money(segment.dailyFoodBudgetCents)}/Tag'), trailing: IconButton(tooltip: 'Bearbeiten', onPressed: () => _beginSegmentEdit(segment), icon: const Icon(Icons.edit_outlined))));

  Widget _expenseTile(TripExpense expense) => Dismissible(key: ValueKey(expense.id), direction: DismissDirection.endToStart, background: _deleteBackground(), onDismissed: (_) => _removeExpense(expense), child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFFE19A35)), title: Text(expense.title), subtitle: Text('${expense.category} · ${_dateLabel(expense.date)}${expense.isPaid ? ' · bezahlt' : ' · geplant'}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(_money(expense.amountCents), style: const TextStyle(fontWeight: FontWeight.w700)), IconButton(tooltip: 'Bearbeiten', onPressed: () => _beginExpenseEdit(expense), icon: const Icon(Icons.edit_outlined))])));

  Widget _metric(String label, String value, Color color) => Padding(padding: const EdgeInsets.only(right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF78839A))), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color))]));

  Widget _dateButton(String label, DateTime date, VoidCallback onPressed) => OutlinedButton.icon(onPressed: onPressed, icon: const Icon(Icons.event_outlined, size: 18), label: Text('$label ${_dateLabel(date)}'));

  Widget _surface({required Widget child}) => SquircleContainer(borderRadius: BorderRadius.circular(24), padding: const EdgeInsets.all(20), backgroundColor: Colors.white, boxShadow: const [BoxShadow(color: Color(0x0D172033), blurRadius: 18, offset: Offset(0, 7))], child: child);

  Widget _statusPill(String label, bool positive) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (positive ? const Color(0xFF20966A) : const Color(0xFFD94E5A)).withValues(alpha: .11), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: positive ? const Color(0xFF20966A) : const Color(0xFFD94E5A))));

  Widget _deleteBackground() => Container(color: const Color(0xFFFFE4E6), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD94E5A)));

  Future<void> _saveTripBasics() async {
    final updated = _trip.copyWith(name: _nameController.text.trim().isEmpty ? _trip.name : _nameController.text.trim(), destination: _destinationController.text.trim(), startsOn: _tripStartsOn, endsOn: _tripEndsOn, fixedCostsCents: _parseAmount(_fixedController.text), dailyBudgetCents: _parseAmount(_dailyController.text), budgetLimitCents: _parseAmount(_limitController.text), alreadyPaidCents: _parseAmount(_paidController.text));
    setState(() => _trip = updated);
    await widget.onChanged(updated);
  }

  void _beginSegmentEdit([TripSegment? segment]) {
    setState(() {
      _showSegmentEditor = true;
      _editingSegmentId = segment?.id;
      _segmentNameController.text = segment?.name ?? '';
      _segmentLocationController.text = segment?.location ?? '';
      _hotelController.text = segment?.accommodationName ?? '';
      _hotelCostController.text = segment == null ? '' : _euros(segment.accommodationCostCents);
      _foodController.text = segment == null ? '' : _euros(segment.dailyFoodBudgetCents);
      _transportController.text = segment == null ? '0' : _euros(segment.transportCostCents);
      _otherController.text = segment == null ? '0' : _euros(segment.otherCostCents);
      _segmentStartsOn = segment?.startsOn ?? _trip.startsOn;
      _segmentEndsOn = segment?.endsOn ?? _trip.endsOn;
      _segmentPaid = segment?.accommodationPaid ?? false;
    });
  }

  void _cancelSegmentEdit() => setState(() { _showSegmentEditor = false; _editingSegmentId = null; });

  Future<void> _saveSegment() async {
    final food = _parseAmount(_foodController.text);
    if (_segmentLocationController.text.trim().isEmpty || _hotelController.text.trim().isEmpty || food <= 0) return;
    final segment = TripSegment(id: _editingSegmentId ?? DateTime.now().microsecondsSinceEpoch.toString(), name: _segmentNameController.text.trim().isEmpty ? _segmentLocationController.text.trim() : _segmentNameController.text.trim(), location: _segmentLocationController.text.trim(), startsOn: _segmentStartsOn, endsOn: _segmentEndsOn, accommodationName: _hotelController.text.trim(), accommodationCostCents: _parseAmount(_hotelCostController.text), dailyFoodBudgetCents: food, transportCostCents: _parseAmount(_transportController.text), otherCostCents: _parseAmount(_otherController.text), accommodationPaid: _segmentPaid);
    final segments = [..._trip.segments.where((item) => item.id != segment.id), segment];
    final updated = _trip.copyWith(segments: segments);
    setState(() { _trip = updated; _showSegmentEditor = false; _editingSegmentId = null; });
    await widget.onChanged(updated);
  }

  Future<void> _removeSegment(TripSegment segment) async {
    final updated = _trip.copyWith(segments: _trip.segments.where((item) => item.id != segment.id).toList());
    setState(() => _trip = updated);
    await widget.onChanged(updated);
  }

  void _beginExpenseEdit([TripExpense? expense]) {
    setState(() {
      _showExpenseEditor = true;
      _editingExpenseId = expense?.id;
      _expenseTitleController.text = expense?.title ?? '';
      _expenseCategoryController.text = expense?.category ?? 'Transport';
      _expenseAmountController.text = expense == null ? '' : _euros(expense.amountCents);
      _expenseDate = expense?.date ?? _trip.startsOn;
      _expensePaid = expense?.isPaid ?? false;
    });
  }

  void _cancelExpenseEdit() => setState(() { _showExpenseEditor = false; _editingExpenseId = null; });

  Future<void> _saveExpense() async {
    final amount = _parseAmount(_expenseAmountController.text);
    if (_expenseTitleController.text.trim().isEmpty || amount <= 0) return;
    final expense = TripExpense(id: _editingExpenseId ?? DateTime.now().microsecondsSinceEpoch.toString(), title: _expenseTitleController.text.trim(), category: _expenseCategoryController.text.trim().isEmpty ? 'Sonstiges' : _expenseCategoryController.text.trim(), amountCents: amount, date: _expenseDate, isPaid: _expensePaid);
    final expenses = [..._trip.expenses.where((item) => item.id != expense.id), expense];
    final updated = _trip.copyWith(expenses: expenses);
    setState(() { _trip = updated; _showExpenseEditor = false; _editingExpenseId = null; });
    await widget.onChanged(updated);
  }

  Future<void> _removeExpense(TripExpense expense) async {
    final updated = _trip.copyWith(expenses: _trip.expenses.where((item) => item.id != expense.id).toList());
    setState(() => _trip = updated);
    await widget.onChanged(updated);
  }

  Future<void> _pickTripDate(bool start) async {
    final picked = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: start ? _tripStartsOn : _tripEndsOn);
    if (picked == null) return;
    setState(() { if (start) { _tripStartsOn = picked; if (!_tripEndsOn.isAfter(picked)) _tripEndsOn = picked.add(const Duration(days: 1)); } else { _tripEndsOn = picked; } });
  }

  Future<void> _pickSegmentDate(bool start) async {
    final picked = await showDatePicker(context: context, firstDate: _trip.startsOn, lastDate: _trip.endsOn, initialDate: start ? _segmentStartsOn : _segmentEndsOn);
    if (picked == null) return;
    setState(() { if (start) { _segmentStartsOn = picked; if (!_segmentEndsOn.isAfter(picked)) _segmentEndsOn = picked.add(const Duration(days: 1)); } else { _segmentEndsOn = picked; } });
  }

  Future<void> _pickExpenseDate() async {
    final picked = await showDatePicker(context: context, firstDate: _trip.startsOn, lastDate: _trip.endsOn, initialDate: _expenseDate);
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Reise löschen?'), content: Text('„${_trip.name}“ und alle zugehörigen Kosten werden gelöscht.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen'))]));
    if (confirmed != true) return;
    await widget.onDelete();
    if (mounted) Navigator.pop(context);
  }

  String _euros(int cents) => (cents / 100).toStringAsFixed(2);
  int _parseAmount(String value) => ((double.tryParse(value.replaceAll(',', '.')) ?? 0) * 100).round();
  String _money(int cents) => '${cents < 0 ? '-' : ''}${(cents.abs() / 100).toStringAsFixed(0)} €';
  String _dateLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
