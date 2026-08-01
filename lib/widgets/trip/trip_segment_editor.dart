import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/finance_models.dart';
import '../../services/food_price_service.dart';
import '../../utils/app_theme.dart';
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
  late DateTime _startsOn;
  late DateTime _endsOn;
  bool _paid = false;
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
    _hotelCostController = TextEditingController(text: _existing == null ? '' : _euros(_existing!.accommodationCostCents));
    _foodController = TextEditingController(text: _existing == null ? '' : _euros(_existing!.dailyFoodBudgetCents));
    _transportController = TextEditingController(text: _existing == null ? '0' : _euros(_existing!.transportCostCents));
    _otherController = TextEditingController(text: _existing == null ? '0' : _euros(_existing!.otherCostCents));
    _startsOn = _existing?.startsOn ?? _earliestStart;
    _endsOn = _existing?.endsOn ?? _earliestStart.add(const Duration(days: 2));
    _paid = _existing?.accommodationPaid ?? false;
    _lat = _existing?.latitude;
    _lng = _existing?.longitude;
  }

  @override
  void dispose() {
    for (final c in [_nameController, _locationController, _hotelController, _hotelCostController, _foodController, _transportController, _otherController]) {
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
          Wrap(spacing: 6, children: [
            ActionChip(label: const Text('20€ sparsam'), onPressed: () => setState(() => _foodController.text = '20')),
            ActionChip(label: const Text('35€ normal'), onPressed: () => setState(() => _foodController.text = '35')),
            ActionChip(label: const Text('55€ komfortabel'), onPressed: () => setState(() => _foodController.text = '55')),
          ]),
          const SizedBox(height: 10),
          Material(color: Colors.transparent, child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _paid,
            title: const Text('Hotel bereits bezahlt'),
            onChanged: (v) => setState(() => _paid = v),
          )),
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
          '${data.city}: ~${data.mealInexpensive.toStringAsFixed(0)}€ sparsam, ~${data.mealMidRange.toStringAsFixed(0)}€ mittel',
          style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600),
        )),
        TextButton(
          onPressed: () => setState(() => _foodController.text = ((data.mealInexpensive + data.mealMidRange) / 2).toStringAsFixed(2)),
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
    final food = _parseAmount(_foodController.text);
    if (_locationController.text.trim().isEmpty || _hotelController.text.trim().isEmpty || food <= 0) return;
    final segment = TripSegment(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty ? _locationController.text.trim() : _nameController.text.trim(),
      location: _locationController.text.trim(),
      startsOn: _startsOn,
      endsOn: _endsOn,
      accommodationName: _hotelController.text.trim(),
      accommodationCostCents: _parseAmount(_hotelCostController.text),
      dailyFoodBudgetCents: food,
      transportCostCents: _parseAmount(_transportController.text),
      otherCostCents: _parseAmount(_otherController.text),
      accommodationPaid: _paid,
      latitude: _lat != null && _lat! > 0 ? _lat : null,
      longitude: _lng != null && _lng! > 0 ? _lng : null,
    );
    Navigator.pop(context, segment);
  }

  String _euros(int cents) => (cents / 100).toStringAsFixed(2);
  int _parseAmount(String value) => ((double.tryParse(value.replaceAll(',', '.')) ?? 0) * 100).round();
}
