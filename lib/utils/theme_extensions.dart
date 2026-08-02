import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Extension on BuildContext for quick access to theme-aware colors.
///
/// Usage: `context.textColor`, `context.surfaceColor`, etc.
/// Eliminates the duplicated `_isDark` / `_surfaceColor` / etc. getters
/// that were previously copy-pasted in every widget.
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surfaceColor =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;

  Color get surface2Color =>
      isDark ? AppColors.darkSurface2 : const Color(0xFFF8F9FC);

  Color get textColor =>
      isDark ? AppColors.darkText : AppColors.lightText;

  Color get secondaryColor =>
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

  Color get mutedColor =>
      isDark ? AppColors.darkMuted : AppColors.lightMuted;

  Color get dividerColor =>
      isDark ? AppColors.darkDivider : AppColors.lightDivider;

  Color get chipBgColor =>
      isDark ? AppColors.darkChipBg : AppColors.lightChipBg;

  Color get shadowColor =>
      isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow;

  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;

  Color get scaffoldBg =>
      isDark ? AppColors.darkBg : AppColors.lightBg;
}

/// Extension on DateTime for consistent German date formatting.
extension DateFormatter on DateTime {
  /// Formats as "02.08.2026"
  String get shortDate =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';

  /// Formats as "02.08." (day.month only)
  String get shortDateNoYear =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}';

  /// German month name + year, e.g. "August 2026"
  static const _monthNames = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  String get monthLabel => '${_monthNames[month - 1]} $year';

  /// German month name only, e.g. "August"
  String get monthName => _monthNames[month - 1];

  /// Relative date string: "Heute", "Morgen", "in 5 Tagen", "vor 3 Tagen"
  String get relative {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(year, month, day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Morgen';
    if (diff == -1) return 'Gestern';
    if (diff > 0) return 'in $diff Tagen';
    return 'vor ${-diff} Tagen';
  }

  /// German weekday abbreviation
  String get weekdayShort {
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return days[weekday - 1];
  }
}
