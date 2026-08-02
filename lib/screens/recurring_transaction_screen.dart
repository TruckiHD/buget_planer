import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_extensions.dart';
import '../widgets/shared/form_section.dart';
import '../widgets/shared/save_button.dart';

class RecurringTransactionScreen extends StatefulWidget {
  final RecurringTransaction? existing;

  const RecurringTransactionScreen({super.key, this.existing});

  @override
  State<RecurringTransactionScreen> createState() => _RecurringTransactionScreenState();
}

class _RecurringTransactionScreenState extends State<RecurringTransactionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TransactionKind _kind;
  late ExpenseCategory _expCat;
  late IncomeCategory _incCat;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _amountController = TextEditingController(
      text: widget.existing != null ? CurrencyUtils.formatCentsInput(widget.existing!.amountCents) : '',
    );
    _kind = widget.existing?.kind ?? TransactionKind.expense;
    _expCat = widget.existing?.expenseCategory ?? ExpenseCategory.sonstiges;
    _incCat = widget.existing?.incomeCategory ?? IncomeCategory.sonstiges;
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

    final item = RecurringTransaction(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amountCents: CurrencyUtils.parseCents(_amountController.text),
      kind: _kind,
      expenseCategory: _kind == TransactionKind.expense ? _expCat : null,
      incomeCategory: _kind == TransactionKind.income ? _incCat : null,
      frequency: widget.existing?.frequency ?? TransactionFrequency.monthly,
      dayOfMonth: widget.existing?.dayOfMonth ?? 1,
      startsOn: widget.existing?.startsOn ?? DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Bewegung bearbeiten' : 'Regelmäßige Bewegung'),
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
              children: [_buildKindSelector()],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.repeat_rounded,
              title: 'Details',
              children: [
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'z. B. Netflix, Miete, Gehalt',
                    hintStyle: TextStyle(color: context.mutedColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(
                      fontSize: 28,
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
              icon: Icons.category_outlined,
              title: 'Kategorie',
              showDivider: false,
              children: [
                _buildCategorySelector<ExpenseCategory>(
                  values: ExpenseCategory.values,
                  selected: _expCat,
                  onChanged: (cat) => setState(() => _expCat = cat),
                  label: (cat) => cat.label,
                  icon: (cat) => cat.icon,
                  color: (cat) => cat.color,
                ),
                const SizedBox(height: 12),
                _buildCategorySelector<IncomeCategory>(
                  values: IncomeCategory.values,
                  selected: _incCat,
                  onChanged: (cat) => setState(() => _incCat = cat),
                  label: (cat) => cat.label,
                  icon: (cat) => cat.icon,
                  color: (cat) => cat.color,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SaveButton(
              onPressed: _isValid ? _save : null,
              label: 'Speichern',
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
            Icon(icon, size: 22, color: isSelected ? color : context.mutedColor),
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
                Icon(icon(cat), size: 18, color: isSelected ? catColor : context.mutedColor),
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
