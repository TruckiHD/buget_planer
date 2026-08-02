import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/currency_service.dart';
import '../../services/food_price_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';

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
  late TextEditingController _travelPassTypeController;
  late TextEditingController _travelPassCostController;
  late TextEditingController _travelPassDaysController;
  late TextEditingController _outboundCostController;
  late TextEditingController _returnCostController;
  late TextEditingController _rentalCompanyController;
  late TextEditingController _rentalCostController;
  late TextEditingController _rentalFuelController;
  late TextEditingController _rentalTollController;
  late TextEditingController _rentalParkingController;
  late DateTime _tripStartsOn;
  late DateTime _tripEndsOn;
  late DateTime? _outboundDate;
  late DateTime? _returnDate;
  late DateTime? _rentalStartDate;
  late DateTime? _rentalEndDate;
  Timer? _debounce;
  bool _showAdvanced = false;
  bool _showTravelPass = false;
  bool _showOutbound = false;
  bool _showRentalCar = false;
  TransportMode? _outboundMode;
  TransportMode? _returnMode;
  String? _targetCurrency;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _mutedColor => _isDark ? AppColors.darkMuted : AppColors.lightMuted;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _nameController = TextEditingController(text: t.name);
    _destinationController = TextEditingController(text: t.destination);
    _fixedController = TextEditingController(text: CurrencyUtils.formatCentsInput(t.fixedCostsCents));
    _dailyController = TextEditingController(text: CurrencyUtils.formatCentsInput(t.dailyBudgetCents));
    _limitController = TextEditingController(text: t.budgetLimitCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.budgetLimitCents));
    _paidController = TextEditingController(text: CurrencyUtils.formatCentsInput(t.alreadyPaidCents));
    _reservedController = TextEditingController(text: t.reservedCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.reservedCents));
    _bufferController = TextEditingController(text: t.bufferPercent == 0 ? '' : '${t.bufferPercent}');
    _travelPassTypeController = TextEditingController(text: t.travelPassType ?? '');
    _travelPassCostController = TextEditingController(text: t.travelPassCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.travelPassCents));
    _travelPassDaysController = TextEditingController(text: t.travelPassDays == 0 ? '' : '${t.travelPassDays}');
    _outboundCostController = TextEditingController(text: t.outboundTransportCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.outboundTransportCents));
    _returnCostController = TextEditingController(text: t.returnTransportCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.returnTransportCents));
    _rentalCompanyController = TextEditingController(text: t.rentalCarCompany ?? '');
    _rentalCostController = TextEditingController(text: t.rentalCarCostCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.rentalCarCostCents));
    _rentalFuelController = TextEditingController(text: t.rentalCarFuelCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.rentalCarFuelCents));
    _rentalTollController = TextEditingController(text: t.rentalCarTollCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.rentalCarTollCents));
    _rentalParkingController = TextEditingController(text: t.rentalCarParkingCents == 0 ? '' : CurrencyUtils.formatCentsInput(t.rentalCarParkingCents));
    _tripStartsOn = t.startsOn;
    _tripEndsOn = t.endsOn;
    _outboundDate = t.outboundDate;
    _returnDate = t.returnDate;
    _rentalStartDate = t.rentalCarStartDate;
    _rentalEndDate = t.rentalCarEndDate;
    _outboundMode = t.outboundTransportMode;
    _returnMode = t.returnTransportMode;
    _showTravelPass = t.hasTravelPass;
    _showOutbound = t.hasOutboundTransport;
    _showRentalCar = t.hasRentalCar;
    _targetCurrency = t.targetCurrency;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameController, _destinationController, _fixedController, _dailyController, _limitController, _paidController, _reservedController, _bufferController, _travelPassTypeController, _travelPassCostController, _travelPassDaysController, _outboundCostController, _returnCostController, _rentalCompanyController, _rentalCostController, _rentalFuelController, _rentalTollController, _rentalParkingController]) {
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
    final travelPassDays = int.tryParse(_travelPassDaysController.text) ?? 0;
    final updated = widget.trip.copyWith(
      name: _nameController.text.trim().isEmpty ? widget.trip.name : _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      startsOn: _tripStartsOn,
      endsOn: _tripEndsOn,
      fixedCostsCents: CurrencyUtils.parseCents(_fixedController.text),
      dailyBudgetCents: CurrencyUtils.parseCents(_dailyController.text),
      budgetLimitCents: CurrencyUtils.parseCents(_limitController.text),
      bufferPercent: bufferPercent,
      alreadyPaidCents: CurrencyUtils.parseCents(_paidController.text),
      reservedCents: CurrencyUtils.parseCents(_reservedController.text),
      travelPassType: _showTravelPass ? _travelPassTypeController.text.trim() : null,
      travelPassCents: _showTravelPass ? CurrencyUtils.parseCents(_travelPassCostController.text) : 0,
      travelPassDays: _showTravelPass ? travelPassDays : 0,
      outboundTransportMode: _showOutbound ? _outboundMode : null,
      outboundTransportCents: _showOutbound ? CurrencyUtils.parseCents(_outboundCostController.text) : 0,
      outboundDate: _showOutbound ? _outboundDate : null,
      returnTransportMode: _showOutbound ? _returnMode : null,
      returnTransportCents: _showOutbound ? CurrencyUtils.parseCents(_returnCostController.text) : 0,
      returnDate: _showOutbound ? _returnDate : null,
      rentalCarCompany: _showRentalCar ? _rentalCompanyController.text.trim() : null,
      rentalCarStartDate: _showRentalCar ? _rentalStartDate : null,
      rentalCarEndDate: _showRentalCar ? _rentalEndDate : null,
      rentalCarCostCents: _showRentalCar ? CurrencyUtils.parseCents(_rentalCostController.text) : 0,
      rentalCarFuelCents: _showRentalCar ? CurrencyUtils.parseCents(_rentalFuelController.text) : 0,
      rentalCarTollCents: _showRentalCar ? CurrencyUtils.parseCents(_rentalTollController.text) : 0,
      rentalCarParkingCents: _showRentalCar ? CurrencyUtils.parseCents(_rentalParkingController.text) : 0,
      targetCurrency: _targetCurrency,
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
      TextField(controller: _destinationController, decoration: const InputDecoration(labelText: 'Ziel / Regionen'), onChanged: (_) => setState(() { _scheduleSave(); _autoDetectCurrency(); })),
      if (foodSuggestion != null) ...[
        const SizedBox(height: 6),
        _foodSuggestionChip(foodSuggestion),
      ],
      const SizedBox(height: 10),
      _currencySelector(),
      if (widget.trip.segments.isNotEmpty) ...[
        const SizedBox(height: 6),
        _applyToAllChip(),
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
      const SizedBox(height: 12),
      InkWell(
        onTap: () => setState(() => _showOutbound = !_showOutbound),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(Icons.flight_takeoff_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Hin- & Rückreise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mutedColor))),
            Icon(_showOutbound ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _showOutbound ? _buildOutboundFields() : const SizedBox.shrink(),
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: () => setState(() => _showRentalCar = !_showRentalCar),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(Icons.directions_car_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Mietwagen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mutedColor))),
            Icon(_showRentalCar ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _showRentalCar ? _buildRentalCarFields() : const SizedBox.shrink(),
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: () => setState(() => _showTravelPass = !_showTravelPass),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(Icons.train_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('Reisepass (Interrail/Eurail)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mutedColor))),
            Icon(_showTravelPass ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _showTravelPass ? _buildTravelPassFields() : const SizedBox.shrink(),
      ),
    ]);
  }

  void _autoDetectCurrency() {
    final dest = _destinationController.text;
    if (dest.isEmpty) return;
    final detected = CurrencyService.detectCurrency(dest);
    if (detected != null && detected != 'EUR') {
      setState(() => _targetCurrency = detected);
    }
  }

  Widget _currencySelector() {
    final currencies = CurrencyService.supportedCurrencies.entries.toList()
      ..sort((a, b) => a.value.name.compareTo(b.value.name));
    final rate = _targetCurrency != null ? CurrencyService.getRate(_targetCurrency!) : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _targetCurrency,
            decoration: const InputDecoration(
              labelText: 'Zielwährung',
              helperText: 'Optional: Lokale Währung für Preisvergleich',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Euro (€)')),
              ...currencies.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text('${e.value.name} (${e.value.symbol})'),
              )),
            ],
            onChanged: (v) {
              setState(() => _targetCurrency = v);
              _scheduleSave();
            },
          ),
        ),
      ]),
      if (_targetCurrency != null && rate != null) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
          ),
          child: Row(children: [
            const Icon(Icons.currency_exchange_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '1 € = ${rate.toStringAsFixed(2)} $_targetCurrency',
              style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: .8), fontWeight: FontWeight.w600),
            )),
            if (!CurrencyService.isLoaded)
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          ]),
        ),
      ],
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
          Expanded(child: TextField(controller: _dailyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Basis-Essen / Tag'), onChanged: (_) { _scheduleSave(); setState(() {}); })),
        ]),
      ]),
    );
  }

  Widget _buildTravelPassFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _travelPassTypeController, decoration: const InputDecoration(labelText: 'Pass-Typ', hintText: 'z. B. Interrail Global, Eurail Pass'), onChanged: (_) => _scheduleSave()),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _travelPassCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Pass-Kosten'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _travelPassDaysController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reisetage im Pass'), onChanged: (_) => _scheduleSave())),
        ]),
        const SizedBox(height: 8),
        Text('Wenn ein Reisepass vorhanden ist, werden Zugkosten automatisch auf 0 gesetzt.', style: TextStyle(fontSize: 12, color: _mutedColor)),
      ]),
    );
  }

  Widget _buildOutboundFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hinfahrt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _mutedColor)),
        const SizedBox(height: 8),
        _transportModeSelector(_outboundMode, (mode) => setState(() => _outboundMode = mode)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _outboundCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Kosten'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: _dateButton(_outboundDate, 'Datum', (date) => setState(() { _outboundDate = date; _scheduleSave(); }))),
        ]),
        const SizedBox(height: 16),
        Text('Rückfahrt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _mutedColor)),
        const SizedBox(height: 8),
        _transportModeSelector(_returnMode, (mode) => setState(() => _returnMode = mode)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _returnCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Kosten'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: _dateButton(_returnDate, 'Datum', (date) => setState(() { _returnDate = date; _scheduleSave(); }))),
        ]),
      ]),
    );
  }

  Widget _buildRentalCarFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _rentalCompanyController, decoration: const InputDecoration(labelText: 'Mietwagenfirma', hintText: 'z. B. Sixt, Hertz, Europcar'), onChanged: (_) => _scheduleSave()),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _dateButton(_rentalStartDate, 'Abholdatum', (date) => setState(() { _rentalStartDate = date; _scheduleSave(); }))),
          const SizedBox(width: 10),
          Expanded(child: _dateButton(_rentalEndDate, 'Rückgabedatum', (date) => setState(() { _rentalEndDate = date; _scheduleSave(); }))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _rentalCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Mietwagen gesamt'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _rentalFuelController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Benzin geschätzt'), onChanged: (_) => _scheduleSave())),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _rentalTollController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Maut'), onChanged: (_) => _scheduleSave())),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _rentalParkingController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Parkgebühren'), onChanged: (_) => _scheduleSave())),
        ]),
      ]),
    );
  }

  Widget _transportModeSelector(TransportMode? selected, ValueChanged<TransportMode?> onChanged) {
    return Wrap(spacing: 6, runSpacing: 6, children: TransportMode.values.map((mode) {
      return ChoiceChip(
        label: Text(mode.label),
        selected: selected == mode,
        onSelected: (_) => onChanged(mode),
        avatar: Icon(mode.icon, size: 16, color: selected == mode ? Colors.white : mode.color),
        selectedColor: mode.color,
        labelStyle: TextStyle(color: selected == mode ? Colors.white : null, fontSize: 12),
      );
    }).toList());
  }

  Widget _dateButton(DateTime? date, String label, ValueChanged<DateTime> onPicked) {
    final dateStr = date != null ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}' : 'Wählen';
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          initialDate: date ?? widget.trip.startsOn,
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text('$label: $dateStr'),
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
    final color = data.isCountryLevel ? const Color(0xFFE5A000) : AppColors.green;
    final label = data.isCountryLevel ? '${data.country} (Durchschnitt)' : data.city;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(data.isCountryLevel ? Icons.public_rounded : Icons.lightbulb_outline_rounded, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(
          '$label: ~${(data.mealInexpensive).toStringAsFixed(0)}€ sparsam, ~${(data.mealMidRange).toStringAsFixed(0)}€ mittel',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
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

  Widget _applyToAllChip() {
    final count = widget.trip.segments.length;
    final euros = _dailyController.text.isEmpty ? '0' : _dailyController.text;
    return InkWell(
      onTap: _applyToAllSegments,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
        ),
        child: Row(children: [
          const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '€$euros/Tag auf $count ${count == 1 ? 'Abschnitt' : 'Abschnitte'} anwenden',
            style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: .8), fontWeight: FontWeight.w600),
          )),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
        ]),
      ),
    );
  }

  Future<void> _applyToAllSegments() async {
    final cents = CurrencyUtils.parseCents(_dailyController.text);
    if (cents <= 0) return;

    final count = widget.trip.segments.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Essenspreis anwenden?'),
        content: Text('${(cents / 100).toStringAsFixed(2)}€/Tag auf alle $count ${count == 1 ? 'Abschnitt' : 'Abschnitte'} anwenden?\n\nBestehende manuelle Einträge werden überschrieben.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anwenden')),
        ],
      ),
    );
    if (confirmed != true) return;

    final updatedSegments = widget.trip.segments.map((s) => s.copyWith(dailyFoodBudgetCents: cents)).toList();
    final updated = widget.trip.copyWith(segments: updatedSegments);
    await widget.onChanged(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Essenspreis auf $count ${count == 1 ? 'Abschnitt' : 'Abschnitte'} angewendet')),
      );
    }
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
}
