import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_extensions.dart';
import '../widgets/shared/form_section.dart';
import '../widgets/shared/save_button.dart';

class SavingsGoalScreen extends StatefulWidget {
  final SavingsGoal? existing;

  const SavingsGoalScreen({super.key, this.existing});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _savedController;
  late TextEditingController _monthlyController;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _targetController = TextEditingController(
      text: widget.existing != null ? CurrencyUtils.formatCentsInput(widget.existing!.targetCents) : '',
    );
    _savedController = TextEditingController(
      text: widget.existing != null ? CurrencyUtils.formatCentsInput(widget.existing!.savedCents) : '0',
    );
    _monthlyController = TextEditingController(
      text: widget.existing != null ? CurrencyUtils.formatCentsInput(widget.existing!.monthlyAllocationCents) : '',
    );
    _deadline = widget.existing?.deadline ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final target = CurrencyUtils.parseCents(_targetController.text);
    final monthly = CurrencyUtils.parseCents(_monthlyController.text);
    return _nameController.text.trim().isNotEmpty && target > 0 && monthly > 0;
  }

  void _save() {
    if (!_isValid) return;

    final goal = SavingsGoal(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      targetCents: CurrencyUtils.parseCents(_targetController.text),
      savedCents: CurrencyUtils.parseCents(_savedController.text),
      deadline: _deadline,
      monthlyAllocationCents: CurrencyUtils.parseCents(_monthlyController.text),
    );

    Navigator.pop(context, goal);
  }

  @override
  Widget build(BuildContext context) {
    final target = CurrencyUtils.parseCents(_targetController.text);
    final monthly = CurrencyUtils.parseCents(_monthlyController.text);
    final saved = CurrencyUtils.parseCents(_savedController.text);
    final remaining = target - saved;
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final monthsNeeded = monthly > 0 ? (remaining / monthly).ceil() : 0;
    final targetDate = DateTime.now().add(Duration(days: monthsNeeded * 30));
    final onTime = targetDate.isBefore(_deadline);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Sparziel bearbeiten' : 'Sparziel anlegen'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (target > 0) ...[
              _buildProgressCard(progress, saved, target),
              const SizedBox(height: 24),
            ],
            FormSection(
              icon: Icons.flag_outlined,
              title: 'Name',
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'z. B. Neuer Laptop, Urlaub, Notgroschen',
                    hintStyle: TextStyle(color: context.mutedColor),
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
              icon: Icons.euro_rounded,
              title: 'Beträge',
              children: [
                _buildAmountRow(
                  label: 'Ziel',
                  controller: _targetController,
                  isHighlight: true,
                ),
                const SizedBox(height: 12),
                _buildAmountRow(
                  label: 'Bereits gespart',
                  controller: _savedController,
                ),
                const SizedBox(height: 12),
                _buildAmountRow(
                  label: 'Pro Monat',
                  controller: _monthlyController,
                  isHighlight: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormSection(
              icon: Icons.calendar_today_rounded,
              title: 'Zieltermin',
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      initialDate: _deadline,
                    );
                    if (picked != null) setState(() => _deadline = picked);
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
                        Text(
                          _deadline.shortDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded, color: context.mutedColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (target > 0 && monthly > 0) ...[
              const SizedBox(height: 20),
              FormSection(
                icon: Icons.insights_outlined,
                title: 'Vorschau',
                showDivider: false,
                children: [
                  _buildPreviewRow(
                    icon: Icons.savings_outlined,
                    label: 'Noch nötig',
                    value: CurrencyUtils.formatCents(remaining > 0 ? remaining : 0),
                    color: context.mutedColor,
                  ),
                  const SizedBox(height: 10),
                  _buildPreviewRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Dauer',
                    value: '$monthsNeeded Monate',
                    color: context.mutedColor,
                  ),
                  const SizedBox(height: 10),
                  _buildPreviewRow(
                    icon: onTime ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    label: 'Zielerreichung',
                    value: onTime ? 'Pünktlich' : 'Verspätet',
                    color: onTime ? AppColors.green : AppColors.amber,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SaveButton(
              onPressed: _isValid ? _save : null,
              label: 'Sparziel speichern',
              isEnabled: _isValid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress, int saved, int target) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fortschritt',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyUtils.formatCents(saved),
                style: TextStyle(fontSize: 13, color: context.mutedColor),
              ),
              Text(
                CurrencyUtils.formatCents(target),
                style: TextStyle(fontSize: 13, color: context.mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow({
    required String label,
    required TextEditingController controller,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.textColor,
            ),
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixText: '€ ',
              prefixStyle: TextStyle(
                fontSize: isHighlight ? 18 : 16,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.mutedColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
