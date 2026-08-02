import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_utils.dart';

class TripSegmentTile extends StatelessWidget {
  final TripSegment segment;
  final VoidCallback onEdit;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  const TripSegmentTile({
    super.key,
    required this.segment,
    required this.onEdit,
    required this.onTogglePaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final totalSegmentCost = segment.accommodationCostCents + segment.foodCostCents + segment.transportCostCents + segment.otherCostCents + segment.baseTransportCostCents;

    return Dismissible(
      key: ValueKey(segment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.red.withValues(alpha: .12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(segment.isBaseLocation ? Icons.home_rounded : Icons.hotel_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(segment.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (segment.isBaseLocation) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.green.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Basis', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.green)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 13, color: mutedColor),
                const SizedBox(width: 3),
                Text(segment.location, style: TextStyle(fontSize: 12, color: mutedColor)),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined, size: 12, color: mutedColor),
                const SizedBox(width: 3),
                Text('${segment.days} Tage', style: TextStyle(fontSize: 12, color: mutedColor)),
              ]),
            ])),
            GestureDetector(
              onTap: onTogglePaid,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: segment.accommodationPaid ? AppColors.green.withValues(alpha: .12) : AppColors.amber.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  segment.accommodationPaid ? 'Bezahlt' : 'Offen',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: segment.accommodationPaid ? AppColors.green : AppColors.amber),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Bearbeiten',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _miniStat('Hotel', segment.accommodationCostCents, AppColors.primary),
            _miniStat('Essen', segment.foodCostCents, AppColors.green),
            if (segment.transportCostCents > 0) _miniStat('Transport', segment.transportCostCents, AppColors.amber),
            if (segment.baseTransportCostCents > 0) _miniStat('Ausflüge', segment.baseTransportCostCents, const Color(0xFF00B8D9)),
            if (segment.otherCostCents > 0) _miniStat('Sonstiges', segment.otherCostCents, const Color(0xFF00B8D9)),
            const Spacer(),
            Text(CurrencyUtils.formatCents(totalSegmentCost), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          if (totalSegmentCost > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(children: [
                if (segment.accommodationCostCents > 0)
                  Expanded(flex: segment.accommodationCostCents, child: Container(height: 4, color: AppColors.primary)),
                if (segment.foodCostCents > 0)
                  Expanded(flex: segment.foodCostCents, child: Container(height: 4, color: AppColors.green)),
                if (segment.transportCostCents > 0)
                  Expanded(flex: segment.transportCostCents, child: Container(height: 4, color: AppColors.amber)),
                if (segment.baseTransportCostCents > 0)
                  Expanded(flex: segment.baseTransportCostCents, child: Container(height: 4, color: const Color(0xFF00B8D9))),
                if (segment.otherCostCents > 0)
                  Expanded(flex: segment.otherCostCents, child: Container(height: 4, color: const Color(0xFF00B8D9))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _miniStat(String label, int cents, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: .7))),
        Text(CurrencyUtils.formatCents(cents), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

}
