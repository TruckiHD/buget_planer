import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_extensions.dart';

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
        if (trip.gaps.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGapList(),
        ],
        const SizedBox(height: 16),
        _buildWeekList(context),
      ],
    );
  }

  Widget _buildSummary() {
    final hasGaps = trip.gaps.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasGaps ? AppColors.amber.withValues(alpha: .08) : AppColors.green.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(
          hasGaps ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
          color: hasGaps ? AppColors.amber : AppColors.green,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            hasGaps ? '${trip.uncoveredDays} von ${trip.days} Nächte nicht gebucht' : 'Alle ${trip.days} Nächte abgedeckt!',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: hasGaps ? AppColors.amber : AppColors.green),
          ),
          if (hasGaps)
            Text(
              '${trip.segments.length} Abschnitte · ${trip.gaps.length} Lücken',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hasGaps ? AppColors.amber.withValues(alpha: .15) : AppColors.green.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${(trip.coveragePercent * 100).round()}%',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: hasGaps ? AppColors.amber : AppColors.green),
          ),
        ),
      ]),
    );
  }

  Widget _buildTimelineBar() {
    final totalDays = trip.days;
    if (totalDays <= 0) return const SizedBox.shrink();

    final sortedSegments = [...trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Timeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
      const SizedBox(height: 8),
      SizedBox(
        height: 48,
        child: LayoutBuilder(builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          return Stack(children: [
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.lightDivider,
                borderRadius: BorderRadius.circular(8),
              ),
            )),
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
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                ),
              );
            }),
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
          ]);
        }),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(trip.startsOn.shortDateNoYear, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
        if (trip.days > 4)
          Text(trip.startsOn.add(Duration(days: trip.days ~/ 2)).shortDateNoYear, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
        Text(trip.endsOn.shortDateNoYear, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
      ]),
    ]);
  }

  Widget _buildGapList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lücken im Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
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
          child: Row(children: [
            const Icon(Icons.hotel_outlined, size: 18, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${gap.days} ${gap.days == 1 ? 'Nacht' : 'Nächte'} nicht gebucht', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${gap.start.shortDate} → ${gap.end.shortDate}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
            ])),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildWeekList(BuildContext context) {
    final sortedSegments = [...trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    final weeks = _groupIntoWeeks(sortedSegments);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Woche für Woche', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
      const SizedBox(height: 8),
      ...weeks.map((week) => _buildWeekBlock(context, week)),
    ]);
  }

  List<_WeekData> _groupIntoWeeks(List<TripSegment> sortedSegments) {
    final weeks = <_WeekData>[];
    var current = trip.startsOn;
    var weekNum = 1;

    while (current.isBefore(trip.endsOn)) {
      final weekEnd = current.add(Duration(days: 7));
      final actualEnd = weekEnd.isAfter(trip.endsOn) ? trip.endsOn : weekEnd;

      final weekSegments = <TripSegment>[];
      for (final seg in sortedSegments) {
        if (seg.endsOn.isAfter(current) && seg.startsOn.isBefore(actualEnd)) {
          weekSegments.add(seg);
        }
      }

      final gapsInWeek = <_GapInWeek>[];
      var dayPointer = current;
      while (dayPointer.isBefore(actualEnd)) {
        final activeSegment = weekSegments.where((s) => !dayPointer.isBefore(s.startsOn) && dayPointer.isBefore(s.endsOn)).firstOrNull;
        if (activeSegment == null) {
          final gapStart = dayPointer;
          while (dayPointer.isBefore(actualEnd)) {
            final seg = weekSegments.where((s) => !dayPointer.isBefore(s.startsOn) && dayPointer.isBefore(s.endsOn)).firstOrNull;
            if (seg != null) break;
            dayPointer = dayPointer.add(const Duration(days: 1));
          }
          gapsInWeek.add(_GapInWeek(gapStart, dayPointer));
        } else {
          dayPointer = dayPointer.add(const Duration(days: 1));
        }
      }

      weeks.add(_WeekData(
        weekNumber: weekNum,
        start: current,
        end: actualEnd,
        segments: weekSegments,
        gaps: gapsInWeek,
      ));

      current = actualEnd;
      weekNum++;
    }

    return weeks;
  }

  Widget _buildWeekBlock(BuildContext context, _WeekData week) {
    final days = week.end.difference(week.start).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: week.gaps.isNotEmpty
            ? Border.all(color: AppColors.amber.withValues(alpha: .25))
            : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          initiallyExpanded: week.gaps.isNotEmpty,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('W${week.weekNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '${week.start.shortDate} – ${week.end.shortDate} · $days Tage',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            )),
          ]),
          children: [
            if (week.segments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text('Kein Hotel in dieser Woche', style: TextStyle(fontSize: 12, color: AppColors.amber)),
                ]),
              ),
            ...week.segments.map((seg) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.hotel_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${seg.location} · ${seg.accommodationName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '${seg.days} Nächte · ${CurrencyUtils.formatCents(seg.accommodationCostCents)} · Essen ${CurrencyUtils.formatCents(seg.dailyFoodBudgetCents)}/Tag',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  ),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: seg.accommodationPaid ? AppColors.green.withValues(alpha: .12) : AppColors.amber.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    seg.accommodationPaid ? 'Bezahlt' : 'Geplant',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: seg.accommodationPaid ? AppColors.green : AppColors.amber),
                  ),
                ),
              ]),
            )),
            if (week.gaps.isNotEmpty)
              ...week.gaps.map((gap) {
                final gapDays = gap.end.difference(gap.start).inDays;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.red),
                      const SizedBox(width: 8),
                      Text('$gapDays ${gapDays == 1 ? 'Nacht' : 'Nächte'} nicht gebucht', style: const TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }


}

class _WeekData {
  final int weekNumber;
  final DateTime start;
  final DateTime end;
  final List<TripSegment> segments;
  final List<_GapInWeek> gaps;
  const _WeekData({required this.weekNumber, required this.start, required this.end, required this.segments, required this.gaps});
}

class _GapInWeek {
  final DateTime start;
  final DateTime end;
  const _GapInWeek(this.start, this.end);
}
