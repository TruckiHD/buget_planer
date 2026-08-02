import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/theme_extensions.dart';

Future<TripExpense?> showExpenseEditor(BuildContext context, TripPlan trip, {TripExpense? existing}) async {
  return showModalBottomSheet<TripExpense>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: _ExpenseEditorSheet(trip: trip, existing: existing),
    ),
  );
}

class _ExpenseEditorSheet extends StatefulWidget {
  final TripPlan trip;
  final TripExpense? existing;
  const _ExpenseEditorSheet({required this.trip, this.existing});

  @override
  State<_ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<_ExpenseEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _attractionTypeController;
  late DateTime _date;
  bool _paid = false;
  bool _isAttraction = false;
  String? _segmentId;

  TripExpense? get _existing => widget.existing;

  static const _categories = [
    ('Transport', Icons.directions_bus_rounded, AppColors.amber),
    ('Unterkunft', Icons.hotel_outlined, AppColors.primary),
    ('Essen', Icons.restaurant_rounded, AppColors.green),
    ('Aktivität', Icons.local_activity_outlined, AppColors.pink),
    ('Shopping', Icons.shopping_bag_outlined, Color(0xFFFF6D00)),
    ('Attraktion', Icons.museum_rounded, Color(0xFF7B61FF)),
    ('Visum & Dokumente', Icons.description_rounded, Color(0xFF00B8D9)),
    ('Versicherung', Icons.shield_rounded, Color(0xFF20966A)),
    ('Kommunikation', Icons.sim_card_rounded, Color(0xFFE19A35)),
    ('Gesundheit', Icons.favorite_rounded, Color(0xFFE05B9A)),
    ('Sonstiges', Icons.more_horiz_rounded, Color(0xFF78839A)),
  ];

  static const _attractionTypes = [
    ('Museum', Icons.museum_rounded),
    ('Tour', Icons.tour_rounded),
    ('Show', Icons.theater_comedy_rounded),
    ('Themenpark', Icons.attractions_rounded),
    ('Aussichtspunkt', Icons.landscape_rounded),
    ('Führung', Icons.groups_rounded),
    ('Workshop', Icons.build_rounded),
    ('Sonstiges', Icons.more_horiz_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _existing?.title ?? '');
    _amountController = TextEditingController(text: _existing == null ? '' : CurrencyUtils.formatCentsInput(_existing!.amountCents));
    _categoryController = TextEditingController(text: _existing?.category ?? 'Transport');
    _attractionTypeController = TextEditingController(text: _existing?.attractionType ?? '');
    _date = _existing?.date ?? widget.trip.startsOn;
    _paid = _existing?.isPaid ?? false;
    _isAttraction = _existing?.isAttraction ?? false;
    _segmentId = _existing?.segmentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _attractionTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
          Text(_existing == null ? 'Neue Kosten planen' : 'Kosten bearbeiten', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Bezeichnung', hintText: 'z. B. Zug Tokyo → Kyoto')),
          const SizedBox(height: 10),
          Text('Kategorie', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: _categories.map((cat) {
            final selected = _categoryController.text == cat.$1;
            return ChoiceChip(
              label: Text(cat.$1),
              selected: selected,
              onSelected: (_) => setState(() {
                _categoryController.text = cat.$1;
                _isAttraction = cat.$1 == 'Attraktion';
              }),
              avatar: Icon(cat.$2, size: 16, color: selected ? Colors.white : cat.$3),
              selectedColor: cat.$3,
              labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
            );
          }).toList()),
          if (_isAttraction) ...[
            const SizedBox(height: 10),
            Text('Art der Attraktion', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _attractionTypes.map((type) {
              final selected = _attractionTypeController.text == type.$1;
              return ChoiceChip(
                label: Text(type.$1),
                selected: selected,
                onSelected: (_) => setState(() => _attractionTypeController.text = type.$1),
                avatar: Icon(type.$2, size: 16, color: selected ? Colors.white : AppColors.primary),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
              );
            }).toList()),
          ],
          if (widget.trip.segments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Verknüpft mit Abschnitt', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ChoiceChip(
                label: const Text('Keiner'),
                selected: _segmentId == null,
                onSelected: (_) => setState(() => _segmentId = null),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: _segmentId == null ? Colors.white : null, fontSize: 12),
              ),
              ...widget.trip.segments.map((s) => ChoiceChip(
                label: Text(s.name),
                selected: _segmentId == s.id,
                onSelected: (_) => setState(() => _segmentId = s.id),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: _segmentId == s.id ? Colors.white : null, fontSize: 12),
              )),
            ]),
          ],
          const SizedBox(height: 10),
          TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Preis')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text('Geplant für ${_date.shortDate}'),
          ),
          const SizedBox(height: 10),
          Material(color: Colors.transparent, child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _paid,
            title: const Text('Bereits bezahlt'),
            onChanged: (v) => setState(() => _paid = v),
          )),
          const SizedBox(height: 14),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: widget.trip.startsOn,
      lastDate: widget.trip.endsOn,
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amount = CurrencyUtils.parseCents(_amountController.text);
    if (_titleController.text.trim().isEmpty || amount <= 0) return;
    final expense = TripExpense(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'Sonstiges' : _categoryController.text.trim(),
      amountCents: amount,
      date: _date,
      isPaid: _paid,
      segmentId: _segmentId,
      isAttraction: _isAttraction,
      attractionType: _isAttraction ? _attractionTypeController.text.trim() : null,
    );
    Navigator.pop(context, expense);
  }
}
