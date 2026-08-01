import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';

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
  late DateTime _date;
  bool _paid = false;

  TripExpense? get _existing => widget.existing;

  static const _categories = [
    ('Transport', Icons.directions_bus_rounded, AppColors.amber),
    ('Unterkunft', Icons.hotel_outlined, AppColors.primary),
    ('Essen', Icons.restaurant_rounded, AppColors.green),
    ('Aktivität', Icons.local_activity_outlined, AppColors.pink),
    ('Shopping', Icons.shopping_bag_outlined, Color(0xFFFF6D00)),
    ('Sonstiges', Icons.more_horiz_rounded, Color(0xFF78839A)),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _existing?.title ?? '');
    _amountController = TextEditingController(text: _existing == null ? '' : _euros(_existing!.amountCents));
    _categoryController = TextEditingController(text: _existing?.category ?? 'Transport');
    _date = _existing?.date ?? widget.trip.startsOn;
    _paid = _existing?.isPaid ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
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
              onSelected: (_) => setState(() => _categoryController.text = cat.$1),
              avatar: Icon(cat.$2, size: 16, color: selected ? Colors.white : cat.$3),
              selectedColor: cat.$3,
              labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
            );
          }).toList()),
          const SizedBox(height: 10),
          TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '€ ', labelText: 'Preis')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text('Geplant für ${_dateLabel(_date)}'),
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
    final amount = _parseAmount(_amountController.text);
    if (_titleController.text.trim().isEmpty || amount <= 0) return;
    final expense = TripExpense(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'Sonstiges' : _categoryController.text.trim(),
      amountCents: amount,
      date: _date,
      isPaid: _paid,
    );
    Navigator.pop(context, expense);
  }

  String _euros(int cents) => (cents / 100).toStringAsFixed(2);
  int _parseAmount(String value) => ((double.tryParse(value.replaceAll(',', '.')) ?? 0) * 100).round();
  String _dateLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
