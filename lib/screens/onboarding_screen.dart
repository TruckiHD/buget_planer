import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/squircle_container.dart';

class OnboardingScreen extends StatefulWidget {
  final FinancialProfile profile;
  final ValueChanged<FinancialProfile> onComplete;

  const OnboardingScreen({
    super.key,
    required this.profile,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _balanceController = TextEditingController();
  final _incomeController = TextEditingController();
  final _rentController = TextEditingController();
  final _subscriptionsController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _balanceController.dispose();
    _incomeController.dispose();
    _rentController.dispose();
    _subscriptionsController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surfaceColor => _isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get _textColor => _isDark ? AppColors.darkText : AppColors.lightText;
  Color get _mutedColor => _isDark ? AppColors.darkMuted : AppColors.lightMuted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _currentPage ? AppColors.primary : (_isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text('Überspringen', style: TextStyle(color: _mutedColor)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildBalancePage(),
                  _buildIncomePage(),
                  _buildExpensesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancePage() {
    return _buildPage(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.primary,
      title: 'Wie viel hast du aktuell?',
      subtitle: 'Dein aktuelles Guthaben auf allen Konten. Dies ist der Ausgangspunkt für deine Prognosen.',
      child: TextField(
        controller: _balanceController,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          prefixText: '€ ',
          prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _mutedColor),
          hintText: '0',
          hintStyle: TextStyle(color: _mutedColor),
          border: InputBorder.none,
        ),
      ),
      onNext: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
    );
  }

  Widget _buildIncomePage() {
    return _buildPage(
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.green,
      title: 'Was kommt regelmäßig rein?',
      subtitle: 'Dein monatliches Nettoeinkommen (Gehalt, Kindergeld, etc.). Du kannst es später anpassen.',
      child: TextField(
        controller: _incomeController,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          prefixText: '€ / Monat',
          prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _mutedColor),
          hintText: '0',
          hintStyle: TextStyle(color: _mutedColor),
          border: InputBorder.none,
        ),
      ),
      onNext: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
    );
  }

  Widget _buildExpensesPage() {
    return _buildPage(
      icon: Icons.receipt_long_rounded,
      iconColor: AppColors.red,
      title: 'Was sind deine Fixkosten?',
      subtitle: 'Miete, Abos, Versicherungen – alles, was jeden Monat automatisch abgebucht wird.',
      child: Column(
        children: [
          TextField(
            controller: _rentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '€ ',
              labelText: 'Miete & Wohnen',
              hintText: 'z. B. 800',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subscriptionsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '€ ',
              labelText: 'Abos & Verträge',
              hintText: 'z. B. 50 (Netflix, Spotify, Handy...)',
            ),
          ),
        ],
      ),
      onNext: _complete,
      nextLabel: 'Los geht\'s!',
    );
  }

  Widget _buildPage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onNext,
    String nextLabel = 'Weiter',
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 15, color: _mutedColor, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SquircleContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            backgroundColor: _surfaceColor,
            boxShadow: [BoxShadow(color: _isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow, blurRadius: 20, offset: const Offset(0, 8))],
            child: child,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(nextLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _skip() {
    widget.onComplete(widget.profile);
  }

  Future<void> _complete() async {
    final balance = CurrencyUtils.parseCents(_balanceController.text);
    final income = CurrencyUtils.parseCents(_incomeController.text);
    final rent = CurrencyUtils.parseCents(_rentController.text);
    final subs = CurrencyUtils.parseCents(_subscriptionsController.text);

    final recurring = <RecurringTransaction>[];
    if (income > 0) {
      recurring.add(RecurringTransaction(
        id: 'onboarding_income',
        title: 'Gehalt',
        amountCents: income,
        kind: TransactionKind.income,
        incomeCategory: IncomeCategory.gehalt,
        startsOn: DateTime.now(),
      ));
    }
    if (rent > 0) {
      recurring.add(RecurringTransaction(
        id: 'onboarding_rent',
        title: 'Miete',
        amountCents: rent,
        kind: TransactionKind.expense,
        expenseCategory: ExpenseCategory.wohnen,
        startsOn: DateTime.now(),
      ));
    }
    if (subs > 0) {
      recurring.add(RecurringTransaction(
        id: 'onboarding_subs',
        title: 'Abos & Verträge',
        amountCents: subs,
        kind: TransactionKind.expense,
        expenseCategory: ExpenseCategory.vertrag,
        startsOn: DateTime.now(),
      ));
    }

    final updated = widget.profile.copyWith(
      currentBalanceCents: balance,
      recurringTransactions: [...widget.profile.recurringTransactions, ...recurring],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    widget.onComplete(updated);
  }
}
