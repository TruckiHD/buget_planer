import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/finance_models.dart';
import '../../services/currency_service.dart';
import '../../services/food_price_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';
import 'trip_location_picker.dart';

Future<TripSegment?> showSegmentEditor(BuildContext context, TripPlan trip, {TripSegment? existing}) async {
  return showModalBottomSheet<TripSegment>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: _SegmentEditorSheet(trip: trip, existing: existing),
    ),
  );
}

class _SegmentEditorSheet extends StatefulWidget {
  final TripPlan trip;
  final TripSegment? existing;
  const _SegmentEditorSheet({required this.trip, this.existing});

  @override
  State<_SegmentEditorSheet> createState() => _SegmentEditorSheetState();
}

class _SegmentEditorSheetState extends State<_SegmentEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _hotelController;
  late TextEditingController _hotelCostController;
  late TextEditingController _foodController;
  late TextEditingController _transportController;
  late TextEditingController _otherController;
  late TextEditingController _baseTransportController;
  late DateTime _startsOn;
  late DateTime _endsOn;
  bool _paid = false;
  bool _isBaseLocation = false;
  double? _lat;
  double? _lng;

  TripSegment? get _existing => widget.existing;

  LatLng? get _fallbackCenter {
    final sorted = [...widget.trip.segments.where((s) => s.hasCoordinates && s.id != widget.existing?.id)]
      ..sort((a, b) => b.startsOn.compareTo(a.startsOn));
    if (sorted.isNotEmpty) return LatLng(sorted.first.latitude!, sorted.first.longitude!);
    return null;
  }

  DateTime get _earliestStart {
    if (_existing != null) return widget.trip.startsOn;
    final sorted = [...widget.trip.segments.where((s) => s.id != _existing?.id)]
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    if (sorted.isEmpty) return widget.trip.startsOn;
    return sorted.last.endsOn;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _existing?.name ?? '');
    _locationController = TextEditingController(text: _existing?.location ?? '');
    _hotelController = TextEditingController(text: _existing?.accommodationName ?? '');
    _hotelCostController = TextEditingController(text: _existing == null ? '' : CurrencyUtils.formatCentsInput(_existing!.accommodationCostCents));
    _foodController = TextEditingController(text: _existing == null ? (widget.trip.dailyBudgetCents > 0 ? CurrencyUtils.formatCentsInput(widget.trip.dailyBudgetCents) : '') : CurrencyUtils.formatCentsInput(_existing!.dailyFoodBudgetCents));
    _transportController = TextEditingController(text: _existing == null ? '0' : CurrencyUtils.formatCentsInput(_existing!.transportCostCents));
    _otherController = TextEditingController(text: _existing == null ? '0' : CurrencyUtils.formatCentsInput(_existing!.otherCostCents));
    _baseTransportController = TextEditingController(text: _existing == null ? '' : CurrencyUtils.formatCentsInput(_existing!.baseTransportCostCents));
    _startsOn = _existing?.startsOn ?? _earliestStart;
    _endsOn = _existing?.endsOn ?? _earliestStart.add(const Duration(days: 2));
    _paid = _existing?.accommodationPaid ?? false;
    _isBaseLocation = _existing?.isBaseLocation ?? false;
    _lat = _existing?.latitude;
    _lng = _existing?.longitude;
  }

  @override
  void dispose() {
    for (final c in [_nameController, _locationController, _hotelController, _hotelCostController, _foodController, _transportController, _otherController, _baseTransportController]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final foodSuggestion = FoodPriceService.lookup(_locationController.text);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightDivider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Text(_existing == null ? 'Neuen Abschnitt anlegen' : 'Abschnitt bearbeiten', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Abschnittsname', hintText: 'z. B. Tokyo · Shibuya')),
          const SizedBox(height: 10),
          TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Stadt / Ort'), onChanged: (_) => setState(() {})),
          if (foodSuggestion != null) ...[
            const SizedBox(height: 6),
            _foodSuggestionChip(foodSuggestion),
          ] else ...[
            const SizedBox(height: 6),
            _countryPickerChip(),
          ],
          const SizedBox(height: 10),
          _dateRangeButton(_startsOn, _endsOn, _pickDateRange),
          const SizedBox(height: 16),
          TripLocationPicker(
            initialLat: _lat,
            initialLng: _lng,
            isDark: Theme.of(context).brightness == Brightness.dark,
            fallbackCenter: _fallbackCenter,
            onPicked: (lat, lng) => setState(() { _lat = lat; _lng = lng; }),
          ),
          const SizedBox(height: 16),
          TextField(controller: _hotelController, decoration: const InputDecoration(labelText: 'Hotel / Unterkunft')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _hotelCostController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Hotel gesamt'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _foodController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Essen / Tag'))),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: _buildFoodChips(foodSuggestion)),
          const SizedBox(height: 10),
          Material(color: Colors.transparent, child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _paid,
            title: const Text('Hotel bereits bezahlt'),
            onChanged: (v) => setState(() => _paid = v),
          )),
          const SizedBox(height: 16),
          _sectionHeader(Icons.hotel_outlined, 'Basis-Option'),
          const SizedBox(height: 10),
          Material(color: Colors.transparent, child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isBaseLocation,
            title: const Text('Hauptstandort (Basis)'),
            subtitle: const Text('Für längeren Aufenthalt mit Ausflügen'),
            onChanged: (v) => setState(() => _isBaseLocation = v),
          )),
          if (_isBaseLocation) ...[
            const SizedBox(height: 10),
            TextField(controller: _baseTransportController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Transportkosten für Ausflüge')),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: TextField(controller: _transportController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Transport'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _otherController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Sonstiges'))),
          ]),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(_existing == null ? 'Hinzufügen' : 'Speichern'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _foodSuggestionChip(FoodPriceData data) {
    final color = data.isCountryLevel ? const Color(0xFFE5A000) : AppColors.green;
    final label = data.isCountryLevel ? '${data.country} (Durchschnitt)' : data.city;

    String priceText;
    if (data.hasLocalPrices) {
      final info = CurrencyService.getInfo(data.localCurrency!);
      priceText = '$label: ~${info.symbol}${data.localMealInexpensive!.toStringAsFixed(0)} sparsam, ~${info.symbol}${data.localMealMidRange!.toStringAsFixed(0)} mittel';
    } else {
      priceText = '$label: ~${data.mealInexpensive.toStringAsFixed(0)}€ sparsam, ~${data.mealMidRange.toStringAsFixed(0)}€ mittel';
    }

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
          priceText,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        )),
        TextButton(
          onPressed: () => setState(() => _foodController.text = ((data.mealInexpensive + data.mealMidRange) / 2).toStringAsFixed(2)),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Übernehmen', style: TextStyle(fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _countryPickerChip() {
    return InkWell(
      onTap: _showCountryPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Land für Essenskosten wählen...',
            style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: .7), fontWeight: FontWeight.w500),
          )),
          const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primary),
        ]),
      ),
    );
  }

  Future<void> _showCountryPicker() async {
    final countries = FoodPriceService.availableCountries;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountryPickerSheet(countries: countries),
    );
    if (selected == null) return;
    final data = FoodPriceService.lookup(selected);
    if (data == null) return;
    setState(() => _foodController.text = ((data.mealInexpensive + data.mealMidRange) / 2).toStringAsFixed(2));
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
            Text('$nights ${nights == 1 ? 'Nacht' : 'Nächte'}', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : AppColors.lightMuted)),
          ])),
          const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
        ]),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: _earliestStart,
      lastDate: widget.trip.endsOn,
      initialDateRange: DateTimeRange(start: _startsOn, end: _endsOn),
      saveText: 'Übernehmen',
    );
    if (picked == null) return;
    setState(() {
      _startsOn = picked.start;
      _endsOn = picked.end;
    });
  }

  void _save() {
    final food = CurrencyUtils.parseCents(_foodController.text);
    if (_locationController.text.trim().isEmpty || _hotelController.text.trim().isEmpty || food <= 0) return;
    final segment = TripSegment(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty ? _locationController.text.trim() : _nameController.text.trim(),
      location: _locationController.text.trim(),
      startsOn: _startsOn,
      endsOn: _endsOn,
      accommodationName: _hotelController.text.trim(),
      accommodationCostCents: CurrencyUtils.parseCents(_hotelCostController.text),
      dailyFoodBudgetCents: food,
      transportCostCents: CurrencyUtils.parseCents(_transportController.text),
      otherCostCents: CurrencyUtils.parseCents(_otherController.text),
      accommodationPaid: _paid,
      latitude: _lat != null && _lat! > 0 ? _lat : null,
      longitude: _lng != null && _lng! > 0 ? _lng : null,
      isBaseLocation: _isBaseLocation,
      baseTransportCostCents: _isBaseLocation ? CurrencyUtils.parseCents(_baseTransportController.text) : 0,
    );
    Navigator.pop(context, segment);
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : AppColors.lightMuted)),
    ]);
  }

  List<Widget> _buildFoodChips(FoodPriceData? data) {
    if (data != null) {
      final budget = data.budgetCents / 100;
      final suggested = data.suggestedBudgetCents / 100;
      final comfortable = data.comfortableCents / 100;

      if (data.hasLocalPrices) {
        final info = CurrencyService.getInfo(data.localCurrency!);
        final localBudget = data.localMealInexpensive! * 2;
        final localSuggested = (data.localMealInexpensive! + data.localMealMidRange!) / 2;
        final localComfortable = data.localMealMidRange!;
        return [
          ActionChip(label: Text('${info.symbol}${localBudget.toStringAsFixed(0)} sparsam'), onPressed: () => setState(() => _foodController.text = budget.toStringAsFixed(2))),
          ActionChip(label: Text('${info.symbol}${localSuggested.toStringAsFixed(0)} normal'), onPressed: () => setState(() => _foodController.text = suggested.toStringAsFixed(2))),
          ActionChip(label: Text('${info.symbol}${localComfortable.toStringAsFixed(0)} komfortabel'), onPressed: () => setState(() => _foodController.text = comfortable.toStringAsFixed(2))),
        ];
      }

      return [
        ActionChip(label: Text('${budget.toStringAsFixed(0)}€ sparsam'), onPressed: () => setState(() => _foodController.text = budget.toStringAsFixed(2))),
        ActionChip(label: Text('${suggested.toStringAsFixed(0)}€ normal'), onPressed: () => setState(() => _foodController.text = suggested.toStringAsFixed(2))),
        ActionChip(label: Text('${comfortable.toStringAsFixed(0)}€ komfortabel'), onPressed: () => setState(() => _foodController.text = comfortable.toStringAsFixed(2))),
      ];
    }
    return [
      ActionChip(label: const Text('20€ sparsam'), onPressed: () => setState(() => _foodController.text = '20')),
      ActionChip(label: const Text('35€ normal'), onPressed: () => setState(() => _foodController.text = '35')),
      ActionChip(label: const Text('55€ komfortabel'), onPressed: () => setState(() => _foodController.text = '55')),
    ];
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<String> countries;
  const _CountryPickerSheet({required this.countries});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _query.isEmpty
        ? widget.countries
        : widget.countries.where((c) => c.toLowerCase().contains(_query.toLowerCase())).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightDivider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        const Text('Land auswählen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Suchen...', isDense: true),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final country = filtered[i];
              final data = FoodPriceService.lookup(country);
              return ListTile(
                dense: true,
                title: Text(country),
                subtitle: data != null ? Text('~${data.mealInexpensive.toStringAsFixed(0)}–${data.mealMidRange.toStringAsFixed(0)}€ / Tag', style: const TextStyle(fontSize: 12)) : null,
                onTap: () => Navigator.pop(context, country),
              );
            },
          ),
        ),
      ]),
    );
  }
}
