import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/theme_extensions.dart';

class TripExpenseTile extends StatelessWidget {
  final TripExpense expense;
  final VoidCallback onEdit;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  const TripExpenseTile({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onTogglePaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.red.withValues(alpha: .12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _categoryColor(expense.category).withValues(alpha: .11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon(expense.category), size: 18, color: _categoryColor(expense.category)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${expense.category} · ${expense.date.shortDate}', style: TextStyle(fontSize: 11, color: context.mutedColor)),
          ])),
          GestureDetector(
            onTap: onTogglePaid,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: expense.isPaid ? AppColors.green.withValues(alpha: .12) : AppColors.amber.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                expense.isPaid ? 'Bezahlt' : 'Offen',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: expense.isPaid ? AppColors.green : AppColors.amber),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(CurrencyUtils.formatCents(expense.amountCents), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transport': return AppColors.amber;
      case 'unterkunft': return AppColors.primary;
      case 'essen': return AppColors.green;
      case 'aktivität': case 'aktivitaet': return AppColors.pink;
      case 'shopping': return const Color(0xFFFF6D00);
      case 'attraktion': return const Color(0xFF7B61FF);
      case 'visum & dokumente': case 'visum': return const Color(0xFF00B8D9);
      case 'versicherung': return const Color(0xFF20966A);
      case 'kommunikation': return const Color(0xFFE19A35);
      case 'gesundheit': return const Color(0xFFE05B9A);
      default: return const Color(0xFF78839A);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transport': return Icons.directions_bus_rounded;
      case 'unterkunft': return Icons.hotel_outlined;
      case 'essen': return Icons.restaurant_rounded;
      case 'aktivität': case 'aktivitaet': return Icons.local_activity_outlined;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'attraktion': return Icons.museum_rounded;
      case 'visum & dokumente': case 'visum': return Icons.description_rounded;
      case 'versicherung': return Icons.shield_rounded;
      case 'kommunikation': return Icons.sim_card_rounded;
      case 'gesundheit': return Icons.favorite_rounded;
      default: return Icons.receipt_long_outlined;
    }
  }

}
