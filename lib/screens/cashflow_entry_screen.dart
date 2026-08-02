import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_extensions.dart';
import '../widgets/shared/form_section.dart';
import '../widgets/shared/save_button.dart';

class CashflowEntryScreen extends StatefulWidget {
  final CashFlowEntry? existing;

  const CashflowEntryScreen({super.key, this.existing});

  @override
  State<CashflowEntryScreen> createState() => _CashflowEntryScreenState();
}

class _CashflowEntryScreenState extends State<CashflowEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TransactionKind _kind;
  late bool _confirmed;
  late ExpenseCategory _expCat;
  late IncomeCategory _incCat;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _amountController = TextEditingController(
      text: widget.existing != null ? CurrencyUtils.formatCentsInput(widget.existing!.amountCents) : '',
    );
    _kind = widget.existing?.kind ?? TransactionKind.expense;
    _confirmed = widget.existing?.isConfirmed ?? true;
    _expCat = widget.existing?.expenseCategory ?? ExpenseCategory.sonstiges;
    _incCat = widget.existing?.incomeCategory ?? IncomeCategory.sonstiges;
    _selectedDate = widget.existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = CurrencyUtils.parseCents(_amountController.text);
    return _titleController.text.trim().isNotEmpty && amount > 0;
  }

  void _save() {
    if (!_isValid) return;

    final entry = CashFlowEntry(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amountCents: CurrencyUtils.parseCents(_amountController.text),
      date: _selectedDate,
      kind: _kind,
      expenseCategory: _kind == TransactionKind.expense ? _expCat : null,
      incomeCategory: _kind == TransactionKind.income ? _incCat : null,
      isConfirmed: _confirmed,
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Buchung bearbeiten' : 'Buchung hinzufügen'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              icon: _kind == TransactionKind.expense
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              title: 'Art',
              showDivider: false,
              children: [
                _buildKindSelector(),
              ],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.euro_rounded,
              title: 'Betrag',
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.receipt_long_outlined,
              title: 'Titel',
              children: [
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'z. B. Zugticket, Restaurant, Miete',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.calendar_today_rounded,
              title: 'Datum',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate.shortDate,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _selectedDate = DateTime.now()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Heute'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.category_outlined,
              title: 'Kategorie',
              children: [
                _buildCategorySelector<ExpenseCategory>(
                  values: ExpenseCategory.values,
                  selected: _expCat,
                  onChanged: (cat) => setState(() => _expCat = cat),
                  label: (cat) => cat.label,
                  icon: (cat) => cat.icon,
                  color: (cat) => cat.color,
                ),
                const SizedBox(height: 16),
                _buildCategorySelector<IncomeCategory>(
                  values: IncomeCategory.values,
                  selected: _incCat,
                  onChanged: (cat) => setState(() => _incCat = cat),
                  label: (cat) => cat.label,
                  icon: (cat) => cat.icon,
                  color: (cat) => cat.color,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => _confirmed = !_confirmed),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _confirmed
                          ? AppColors.green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _confirmed
                            ? AppColors.green.withValues(alpha: 0.3)
                            : context.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 22,
                          color: _confirmed ? AppColors.green : context.mutedColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bereits bezahlt',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
                                ),
                              ),
                              Text(
                                'Wird vom Guthaben abgezogen',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SaveButton(
              onPressed: _isValid ? _save : null,
              label: 'Buchung speichern',
              isEnabled: _isValid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKindSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleCard(
            icon: Icons.arrow_downward_rounded,
            label: 'Ausgabe',
            isSelected: _kind == TransactionKind.expense,
            color: AppColors.red,
            onTap: () => setState(() => _kind = TransactionKind.expense),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildToggleCard(
            icon: Icons.arrow_upward_rounded,
            label: 'Einnahme',
            isSelected: _kind == TransactionKind.income,
            color: AppColors.green,
            onTap: () => setState(() => _kind = TransactionKind.income),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? color : context.mutedColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : context.mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector<T>({
    required List<T> values,
    required T selected,
    required ValueChanged<T> onChanged,
    required String Function(T) label,
    required IconData Function(T) icon,
    required Color Function(T) color,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((cat) {
        final isSelected = cat == selected;
        final catColor = color(cat);
        return InkWell(
          onTap: () => onChanged(cat),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        catColor.withValues(alpha: 0.2),
                        catColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? catColor : context.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon(cat),
                  size: 18,
                  color: isSelected ? catColor : context.mutedColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label(cat),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? catColor : context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
