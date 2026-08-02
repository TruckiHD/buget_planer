import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';

/// A gradient hero card displaying the user's current balance.
///
/// Used at the top of the SettingsScreen to provide an at-a-glance
/// financial overview with animated progress indicator.
class BalanceHeroCard extends StatelessWidget {
  final int balanceCents;
  final int freeCents;
  final int reservedCents;

  const BalanceHeroCard({
    super.key,
    required this.balanceCents,
    required this.freeCents,
    required this.reservedCents,
  });

  @override
  Widget build(BuildContext context) {
    final freePercent = balanceCents > 0
        ? (freeCents / balanceCents).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5669E8), Color(0xFF8290F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Dein Guthaben',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyUtils.formatCents(balanceCents),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: freePercent.toDouble(),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Frei ${CurrencyUtils.formatCents(freeCents)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Reserviert ${CurrencyUtils.formatCents(reservedCents)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
