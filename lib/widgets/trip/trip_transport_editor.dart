import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/finance_models.dart';
import '../../services/route_service.dart';
import '../../utils/app_theme.dart';

Future<TripTransport?> showTransportEditor(BuildContext context, TripTransport transport, {bool isDark = false}) {
  return showModalBottomSheet<TripTransport>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: _TransportEditorSheet(transport: transport, isDark: isDark),
    ),
  );
}

class _TransportEditorSheet extends StatefulWidget {
  final TripTransport transport;
  final bool isDark;
  const _TransportEditorSheet({required this.transport, required this.isDark});

  @override
  State<_TransportEditorSheet> createState() => _TransportEditorSheetState();
}

class _TransportEditorSheetState extends State<_TransportEditorSheet> {
  late TransportMode _mode;
  late TextEditingController _costController;
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  bool _isBooked = false;

  TripTransport get _original => widget.transport;

  @override
  void initState() {
    super.initState();
    _mode = _original.mode;
    _costController = TextEditingController(
      text: (_original.estimatedCostCents / 100).toStringAsFixed(2),
    );
    _durationController = TextEditingController(
      text: _original.durationMinutes?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: _original.notes ?? '',
    );
    _isBooked = _original.isBooked;
  }

  @override
  void dispose() {
    _costController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final costEuros = double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final costCents = (costEuros * 100).round();
    final duration = int.tryParse(_durationController.text);

    final updated = _original.copyWith(
      mode: _mode,
      estimatedCostCents: costCents,
      durationMinutes: duration,
      isBooked: _isBooked,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surface2Color = widget.isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC);
    final mutedColor = widget.isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _mode.color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_mode.icon, size: 20, color: _mode.color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_original.fromLocation} → ${_original.toLocation}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Verbindung bearbeiten', style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                )),
              ]),
              const SizedBox(height: 20),

              Text('Fortbewegungsmittel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedColor)),
              const SizedBox(height: 8),
              _modeSelector(),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preis (€)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '€ ',
                        prefixStyle: TextStyle(color: mutedColor),
                        filled: true,
                        fillColor: surface2Color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dauer (Min.)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'z.B. 90',
                        filled: true,
                        fillColor: surface2Color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 16),

              Text('Notizen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'z.B. JR Pass, reserviert, etc.',
                  filled: true,
                  fillColor: surface2Color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isBooked = !_isBooked),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isBooked ? AppColors.green.withValues(alpha: .12) : surface2Color,
                      borderRadius: BorderRadius.circular(10),
                      border: _isBooked ? Border.all(color: AppColors.green.withValues(alpha: .3)) : null,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_isBooked ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                          size: 18, color: _isBooked ? AppColors.green : mutedColor),
                      const SizedBox(width: 6),
                      Text('Gebucht', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _isBooked ? AppColors.green : mutedColor,
                      )),
                    ]),
                  ),
                )),
              ]),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Speichern', style: TextStyle(fontWeight: FontWeight.w600)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransportMode.values.map((mode) {
        final selected = _mode == mode;
        return GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? mode.color.withValues(alpha: .15) : widget.isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? mode.color.withValues(alpha: .4) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(mode.icon, size: 16, color: selected ? mode.color : AppColors.lightMuted),
              const SizedBox(width: 6),
              Text(RouteService.getTransportLabel(mode, null),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? mode.color : AppColors.lightMuted)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
