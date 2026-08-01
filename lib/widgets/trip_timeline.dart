import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';

class TripTimeline extends StatelessWidget {
  final TripPlan trip;
  final bool isDark;

  const TripTimeline({
    super.key,
    required this.trip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummary(),
        const SizedBox(height: 16),
        _buildTimelineBar(),
        const SizedBox(height: 16),
        if (trip.gaps.isNotEmpty) ...[
          _buildGapList(),
          const SizedBox(height: 16),
        ],
        _buildDayList(),
      ],
    );
  }

  Widget _buildSummary() {
    final hasGaps = trip.gaps.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasGaps
            ? AppColors.amber.withValues(alpha: .08)
            : AppColors.green.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            hasGaps ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            color: hasGaps ? AppColors.amber : AppColors.green,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasGaps
                      ? '${trip.uncoveredDays} von ${trip.days} Nächte nicht gebucht'
                      : 'Alle ${trip.days} Nächte abgedeckt!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: hasGaps ? AppColors.amber : AppColors.green,
                  ),
                ),
                if (hasGaps)
                  Text(
                    '${trip.segments.length} Abschnitte · ${trip.gaps.length} Lücken',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasGaps ? AppColors.amber.withValues(alpha: .15) : AppColors.green.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(trip.coveragePercent * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: hasGaps ? AppColors.amber : AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar() {
    final totalDays = trip.days;
    if (totalDays <= 0) return const SizedBox.shrink();

    final sortedSegments = [...trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                children: [
                  // Background bar
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.lightDivider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Segment blocks
                  ...sortedSegments.map((segment) {
                    final startOffset = segment.startsOn.difference(trip.startsOn).inDays / totalDays;
                    final segmentWidth = segment.days / totalDays;
                    return Positioned(
                      left: startOffset * barWidth,
                      width: segmentWidth * barWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: segmentWidth * barWidth > 40
                            ? Text(
                                '${segment.location} ${segment.days}T',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      ),
                    );
                  }),
                  // Gap indicators
                  ...trip.gaps.map((gap) {
                    final startOffset = gap.start.difference(trip.startsOn).inDays / totalDays;
                    final gapWidth = gap.days / totalDays;
                    return Positioned(
                      left: startOffset * barWidth,
                      width: gapWidth * barWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.red.withValues(alpha: .4), width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Date labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_shortDate(trip.startsOn), style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
            if (trip.days > 4)
              Text(_shortDate(trip.startsOn.add(Duration(days: trip.days ~/ 2))), style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
            Text(_shortDate(trip.endsOn), style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildGapList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lücken im Plan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
        ),
        const SizedBox(height: 8),
        ...trip.gaps.map((gap) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.red.withValues(alpha: .15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hotel_outlined, size: 18, color: AppColors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${gap.days} ${gap.days == 1 ? 'Nacht' : 'Nächte'} nicht gebucht',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${_shortDate(gap.start)} → ${_shortDate(gap.end)}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDayList() {
    final sortedSegments = [...trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tag für Tag',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
        ),
        const SizedBox(height: 8),
        ..._buildDayEntries(sortedSegments),
      ],
    );
  }

  List<Widget> _buildDayEntries(List<TripSegment> sortedSegments) {
    final entries = <Widget>[];
    final dayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    var currentDay = trip.startsOn;

    while (currentDay.isBefore(trip.endsOn)) {
      final dayOfWeek = dayLabels[currentDay.weekday - 1];
      final dateStr = '$dayOfWeek, ${currentDay.day}.${currentDay.month}.';

      // Check if this day is in a segment
      TripSegment? activeSegment;
      for (final seg in sortedSegments) {
        if (!currentDay.isBefore(seg.startsOn) && currentDay.isBefore(seg.endsOn)) {
          activeSegment = seg;
          break;
        }
      }

      // Check if this is the first day of a segment
      final isFirstDayOfSegment = activeSegment != null &&
          currentDay.year == activeSegment.startsOn.year &&
          currentDay.month == activeSegment.startsOn.month &&
          currentDay.day == activeSegment.startsOn.day;

      // Add segment header if first day
      if (isFirstDayOfSegment) {
        entries.add(_buildSegmentHeader(activeSegment));
      }

      if (activeSegment != null) {
        entries.add(_buildBookedDay(dateStr, activeSegment));
      } else {
        entries.add(_buildGapDay(dateStr));
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }

    return entries;
  }

  Widget _buildSegmentHeader(TripSegment segment) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${segment.location} · ${segment.accommodationName}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Text(
            '${segment.days} ${segment.days == 1 ? 'Nacht' : 'Nächte'}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedDay(String dateStr, TripSegment segment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: segment.accommodationPaid ? AppColors.green : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_money(segment.dailyFoodBudgetCents)} Essen/Tag',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: segment.accommodationPaid
                  ? AppColors.green.withValues(alpha: .12)
                  : AppColors.amber.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              segment.accommodationPaid ? 'Bezahlt' : 'Geplant',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: segment.accommodationPaid ? AppColors.green : AppColors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapDay(String dateStr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.red, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Kein Hotel gebucht',
              style: TextStyle(fontSize: 12, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.';

  String _money(int cents) => '${(cents / 100).toStringAsFixed(0)} €';
}
