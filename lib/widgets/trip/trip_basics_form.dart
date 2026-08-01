import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/food_price_service.dart';
import '../../utils/app_theme.dart';

class TripBasicsForm extends StatefulWidget {
  final TripPlan trip;
  final Future<void> Function(TripPlan updated) onChanged;

  const TripBasicsForm({
    super.key,
    required this.trip,
    required this.onChanged,
  });

  @override
  State<TripBasicsForm> createState() => _TripBasicsFormState();
}

class _TripBasicsFormState extends State<TripBasicsForm> {
  late TextEditingController _nameController;
  late TextEditingController _destinationController;
  late TextEditingController _fixedController;
  late TextEditingController _dailyController;
  late TextEditingController _limitController;
  late TextEditingController _paidController;
  late TextEditingController _reservedController;
  late TextEditingController _bufferController;
  late DateTime _tripStartsOn;
  late DateTime _tripEndsOn;
  Timer? _debounce;
  bool _showAdvanced = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _mutedColor => _isDark ? AppColors.darkMuted : AppColors.lightMuted;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _nameController = TextEditingController(text: t.name);
    _destinationController = TextEditingController(text: t.destination);
    _fixedController = TextEditingController(text: _euros(t.fixedCostsCents));
    _dailyController = TextEditingController(text: _euros(t.dailyBudgetCents));
    _limitController = TextEditingController(text: t.budgetLimitCents == 0 ? '' : _euros(t.budgetLimitCents));
    _paidController = TextEditingController(text: _euros(t.alreadyPaidCents));
    _reservedController = TextEditingController(text: t.reservedCents == 0 ? '' : _euros(t.reservedCents));
    _bufferController = TextEditingController(text: t.bufferPercent == 0 ? '' : '${t.bufferPercent}');
    _tripStartsOn = t.startsOn;
    _tripEndsOn = t.endsOn;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameController, _destinationController, _fixedController, _dailyController, _limitController, _paidController, _reservedController, _bufferController]) {
      c.dispose();
    }
    super.dispose();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    final bufferPercent = (int.tryParse(_bufferController.text) ?? 0).clamp(0, 100).toInt();
    final updated = widget.trip.copyWith(
      name: _nameController.text.trim().isEmpty ? widget.trip.name : _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      startsOn: _tripStartsOn,
      endsOn: _tripEndsOn,
      fixedCostsCents: _parseAmount(_fixedController.text),
      dailyBudgetCents: _parseAmount(_dailyController.text),
      budgetLimitCents: _parseAmount(_limitController.text),
      bufferPercent: bufferPercent,
      alreadyPaidCents: _parseAmount(_paidController.text),
      reservedCents: _parseAmount(_reservedController.text),
    );
    await widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final foodSuggestion = FoodPriceService.lookup(_destinationController.text);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(Icons.flight_takeoff_rounded, 'Reise-Info'),
      const SizedBox(height: 10),
      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), onChanged: (_) => _scheduleSave()),
      const SizedBox(height: 10),
      TextField(controller: _destinationController, decoration: const InputDecoration(labelText: 'Ziel / Regionen'), onChanged: (_) => setState(() => _scheduleSave())),
      if (foodSuggestion != null) ...[
        const SizedBox(height: 6),
        _foodSuggestionChip(foodSuggestion),
      ],
      const SizedBox(height: 10),
      _dateRangeButton(_tripStartsOn, _tripEndsOn, _pickTripDateRange),
      const SizedBox(height: 12),
      InkWell(
        onTap: () => setState(() => _showAdvanced = !_showAdvanced),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Budget & Kosten', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mutedColor))),
            Icon(_showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _showAdvanced ? _buildBudgetFields() : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _buildBudgetFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextField(controller: _limitController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Maximales Budget'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _paidController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Bereits bezahlt'), onChanged: (_) => _scheduleSave())),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _reservedController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Reservieren', helperText: '0 € = nur planen, nichts blockieren.'), onChanged: (_) => _scheduleSave()),
        const SizedBox(height: 10),
        TextField(controller: _bufferController, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: '%', labelText: 'Reisepuffer', helperText: '0 % = kein zusätzlicher Puffer.'), onChanged: (_) => _scheduleSave()),
        const SizedBox(height: 14),
        _sectionHeader(Icons.restaurant_rounded, 'Tägliche Kosten'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _fixedController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Globale feste Kosten'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _dailyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Basis-Essen / Tag'), onChanged: (_) => _scheduleSave())),
        ]),
      ]),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mutedColor)),
    ]);
  }

  Widget _foodSuggestionChip(FoodPriceData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.green),
        const SizedBox(width: 8),
        Expanded(child: Text(
          '${data.city}: ~${(data.mealInexpensive).toStringAsFixed(0)}€ sparsam, ~${(data.mealMidRange).toStringAsFixed(0)}€ mittel',
          style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600),
        )),
        TextButton(
          onPressed: () {
            _dailyController.text = ((data.mealInexpensive + data.mealMidRange) / 2).toStringAsFixed(2);
            _scheduleSave();
          },
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Übernehmen', style: TextStyle(fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _dateRangeButton(DateTime start, DateTime end, VoidCallback onPressed) {
    final startStr = '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}';
    final endStr = '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}';
    final nights = end.difference(start).inDays.clamp(1, 365);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$startStr – $endStr', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('$nights ${nights == 1 ? 'Nacht' : 'Nächte'}', style: TextStyle(fontSize: 12, color: _mutedColor)),
          ])),
          const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
        ]),
      ),
    );
  }

  Future<void> _pickTripDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: DateTimeRange(start: _tripStartsOn, end: _tripEndsOn),
      saveText: 'Übernehmen',
    );
    if (picked == null) return;
    setState(() {
      _tripStartsOn = picked.start;
      _tripEndsOn = picked.end;
    });
    _scheduleSave();
  }

  String _euros(int cents) => (cents / 100).toStringAsFixed(2);
  int _parseAmount(String value) => ((double.tryParse(value.replaceAll(',', '.')) ?? 0) * 100).round();
}
