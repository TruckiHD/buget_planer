import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_extensions.dart';
import '../widgets/shared/form_section.dart';
import '../widgets/shared/save_button.dart';

class PlannedPurchaseScreen extends StatefulWidget {
  final PlannedPurchase? existing;

  const PlannedPurchaseScreen({super.key, this.existing});

  @override
  State<PlannedPurchaseScreen> createState() => _PlannedPurchaseScreenState();
}

class _PlannedPurchaseScreenState extends State<PlannedPurchaseScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _desiredDate;
  late bool _reserveNow;
  late ExpenseCategory _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _amountController = TextEditingController(
      text: widget.existing != null ? CurrencyUtils.formatCentsInput(widget.existing!.amountCents) : '',
    );
    _desiredDate = widget.existing?.desiredDate ?? DateTime.now().add(const Duration(days: 90));
    _reserveNow = widget.existing?.isReserved ?? false;
    _category = widget.existing?.category ?? ExpenseCategory.sonstiges;
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

    final purchase = PlannedPurchase(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      amountCents: CurrencyUtils.parseCents(_amountController.text),
      desiredDate: _desiredDate,
      isReserved: _reserveNow,
      isPurchased: widget.existing?.isPurchased ?? false,
    );

    Navigator.pop(context, purchase);
  }

  @override
  Widget build(BuildContext context) {
    final daysUntil = _desiredDate.difference(DateTime.now()).inDays;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Anschaffung bearbeiten' : 'Anschaffung planen'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              icon: Icons.shopping_bag_outlined,
              title: 'Was?',
              children: [
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'z. B. neuer Laptop, Fahrrad, Urlaub',
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ExpenseCategory.values.map((cat) {
                    final isSelected = cat == _category;
                    return InkWell(
                      onTap: () => setState(() => _category = cat),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    cat.color.withValues(alpha: 0.2),
                                    cat.color.withValues(alpha: 0.1),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat.color : context.borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 18, color: isSelected ? cat.color : context.mutedColor),
                            const SizedBox(width: 8),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? cat.color : context.mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.event_outlined,
              title: 'Wann?',
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      initialDate: _desiredDate,
                    );
                    if (picked != null) setState(() => _desiredDate = picked);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, size: 22, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _desiredDate.shortDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                              ),
                            ),
                            Text(
                              daysUntil > 0 ? 'in $daysUntil Tagen' : 'Heute',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.mutedColor,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded, color: context.mutedColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => _reserveNow = !_reserveNow),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _reserveNow
                          ? AppColors.amber.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _reserveNow
                            ? AppColors.amber.withValues(alpha: 0.3)
                            : context.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _reserveNow ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 22,
                          color: _reserveNow ? AppColors.amber : context.mutedColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jetzt reservieren',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
                                ),
                              ),
                              Text(
                                'Blockiert Geld vom freien Guthaben',
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
              label: 'Anschaffung speichern',
              isEnabled: _isValid,
            ),
          ],
        ),
      ),
    );
  }
}
