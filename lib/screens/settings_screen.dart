import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/export_service.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_extensions.dart';
import '../widgets/shared/balance_hero_card.dart';
import '../widgets/shared/form_section.dart';
import '../widgets/shared/save_button.dart';

class SettingsScreen extends StatefulWidget {
  final FinancialProfile profile;

  const SettingsScreen({super.key, required this.profile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _balanceController;
  late TextEditingController _reserveController;
  late TextEditingController _variableController;
  late Map<ExpenseCategory, TextEditingController> _budgetControllers;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: CurrencyUtils.formatCentsInput(widget.profile.currentBalanceCents),
    );
    _reserveController = TextEditingController(
      text: CurrencyUtils.formatCentsInput(widget.profile.safetyReserveCents),
    );
    _variableController = TextEditingController(
      text: CurrencyUtils.formatCentsInput(widget.profile.monthlyVariableBudgetCents),
    );
    _budgetControllers = {};
    for (final cat in ExpenseCategory.values) {
      final existing = widget.profile.categoryBudgets
          .where((b) => b.category == cat)
          .isEmpty
          ? null
          : widget.profile.categoryBudgets.firstWhere((b) => b.category == cat);
      _budgetControllers[cat] = TextEditingController(
        text: existing != null ? CurrencyUtils.formatCentsInput(existing.monthlyLimitCents) : '',
      );
    }

    _balanceController.addListener(_onFieldChanged);
    _reserveController.addListener(_onFieldChanged);
    _variableController.addListener(_onFieldChanged);
    for (final c in _budgetControllers.values) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _reserveController.dispose();
    _variableController.dispose();
    for (final c in _budgetControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  FinancialProfile _buildUpdatedProfile() {
    final balance = CurrencyUtils.parseCents(_balanceController.text);
    final reserve = CurrencyUtils.parseCents(_reserveController.text);
    final variable = CurrencyUtils.parseCents(_variableController.text);

    final budgets = <CategoryBudget>[];
    for (final cat in ExpenseCategory.values) {
      final amount = CurrencyUtils.parseCents(_budgetControllers[cat]!.text);
      if (amount > 0) {
        budgets.add(CategoryBudget(category: cat, monthlyLimitCents: amount));
      }
    }

    return widget.profile.copyWith(
      currentBalanceCents: balance,
      safetyReserveCents: reserve,
      monthlyVariableBudgetCents: variable,
      categoryBudgets: budgets,
    );
  }

  void _save() {
    final updated = _buildUpdatedProfile();
    setState(() => _hasChanges = false);
    Navigator.pop(context, updated);
  }

  void _exportData() {
    final json = ExportService.exportToJson(widget.profile);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten exportieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dein Finanzprofil als JSON. Kopiere den Text und speichere ihn als Datei.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkSurface2 : const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                json,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                maxLines: 10,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _importData() async {
    final controller = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten importieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Füge den JSON-Text deines gespeicherten Profils ein.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'JSON hier einfügen...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );
    if (json == null || json.trim().isEmpty) return;
    final imported = ExportService.importFromJson(json);
    if (imported == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültiges Format. Bitte prüfe den JSON-Text.')),
      );
      return;
    }
    Navigator.pop(context, imported);
  }

  @override
  Widget build(BuildContext context) {
    final reserved = widget.profile.reservedTripCents +
        widget.profile.reservedGoalCents +
        widget.profile.reservedPurchaseCents +
        widget.profile.safetyReserveCents;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text('Finanzprofil'),
          centerTitle: false,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _save,
                child: const Text(
                  'Speichern',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalanceHeroCard(
                balanceCents: widget.profile.currentBalanceCents,
                freeCents: widget.profile.freeBalanceCents,
                reservedCents: reserved,
              ),
              const SizedBox(height: 24),
              FormSection(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Konto',
                children: [
                  _buildField(
                    controller: _balanceController,
                    label: 'Aktuelles Guthaben',
                    prefix: '€ ',
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _reserveController,
                    label: 'Sicherheitsreserve',
                    prefix: '€ ',
                    helpText: 'Geld das immer blockiert ist',
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _variableController,
                    label: 'Alltagspuffer pro Monat',
                    prefix: '€ ',
                    helpText: 'Budget für tägliche Ausgaben',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FormSection(
                icon: Icons.category_outlined,
                title: 'Kategorie-Budgets',
                trailing: TextButton(
                  onPressed: _clearAllBudgets,
                  child: Text(
                    'Alle löschen',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                children: [
                  Text(
                    'Monatliche Limits pro Kategorie. Leer = kein Budget.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.mutedColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ExpenseCategory.values.map((cat) => _buildBudgetRow(cat)),
                ],
              ),
              const SizedBox(height: 20),
              FormSection(
                icon: Icons.storage_outlined,
                title: 'Daten',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.upload_rounded,
                          label: 'Exportieren',
                          onTap: _exportData,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.download_rounded,
                          label: 'Importieren',
                          onTap: _importData,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SaveButton(
                onPressed: _hasChanges ? _save : null,
                label: 'Profil speichern',
                isEnabled: _hasChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? helpText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixText: prefix,
        labelText: label,
        helperText: helpText,
        helperStyle: TextStyle(
          fontSize: 12,
          color: context.mutedColor,
        ),
      ),
    );
  }

  Widget _buildBudgetRow(ExpenseCategory cat) {
    final existing = widget.profile.categoryBudgets
        .where((b) => b.category == cat)
        .isEmpty
        ? null
        : widget.profile.categoryBudgets.firstWhere((b) => b.category == cat);
    final currentAmount = existing?.monthlyLimitCents ?? 0;
    final hasBudget = currentAmount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cat.icon, size: 18, color: cat.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textColor,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _budgetControllers[cat],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixText: '€ ',
                    prefixStyle: TextStyle(fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 0.0,
                minHeight: 4,
                backgroundColor: cat.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(cat.color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllBudgets() {
    for (final cat in ExpenseCategory.values) {
      _budgetControllers[cat]!.clear();
    }
    _onFieldChanged();
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text('Du hast ungespeicherte Änderungen. Möchtest du sie verwerfen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
  }
}
