import '../services/currency_service.dart';

/// Centralized currency formatting and parsing utilities.
///
/// All monetary values in the app are stored as cents (int).
/// This class provides consistent formatting across the entire codebase.
class CurrencyUtils {
  CurrencyUtils._();

  /// Formats cents as "1.234 €" (no decimals, negative-aware).
  /// Example: 125000 → "1.250 €", -5000 → "-50 €"
  static String formatCents(int cents) {
    final prefix = cents < 0 ? '-' : '';
    return '$prefix${(cents.abs() / 100).toStringAsFixed(0)} €';
  }

  /// Formats cents as "1.250,00" (with decimals, no currency symbol).
  /// Used for text field controllers where prefixText already shows "€".
  /// Example: 125000 → "1250.00"
  static String formatCentsInput(int cents) {
    final prefix = cents < 0 ? '-' : '';
    return '$prefix${(cents.abs() / 100).toStringAsFixed(2)}';
  }

  /// Formats cents as "1.250,00 €" (with decimals and currency symbol).
  /// Example: 125000 → "1250.00 €"
  static String formatCentsDecimal(int cents) {
    return '${formatCentsInput(cents)} €';
  }

  /// Parses a euro-formatted string back to cents.
  /// Handles ".", "," as decimal separator and optional "€" suffix.
  /// Example: "1250.00", "1.250,00", "1.250,00 €" → 125000
  static int parseCents(String value) {
    final cleaned = value.replaceAll('€', '').replaceAll(' ', '').trim();
    return ((double.tryParse(cleaned.replaceAll(',', '.')) ?? 0) * 100)
        .round();
  }

  /// Formats cents as a short label (e.g. "1.2k €" for large amounts).
  /// Falls back to [formatCents] for amounts under 10,000€.
  static String formatCentsShort(int cents) {
    final euros = cents.abs() / 100;
    if (euros >= 1000000) {
      final prefix = cents < 0 ? '-' : '';
      return '$prefix${(euros / 1000000).toStringAsFixed(1)}M €';
    }
    if (euros >= 10000) {
      final prefix = cents < 0 ? '-' : '';
      return '$prefix${(euros / 1000).toStringAsFixed(1)}k €';
    }
    return formatCents(cents);
  }

  /// Formats EUR cents as local currency with EUR equivalent.
  /// Returns "¥1,200 (~€7)" for non-EUR currencies, "€7" for EUR.
  static String formatDual(int centsEur, String? targetCurrency) {
    if (targetCurrency == null || targetCurrency.toUpperCase() == 'EUR') {
      return formatCents(centsEur);
    }
    return CurrencyService.formatDual(centsEur, targetCurrency);
  }

  /// Formats EUR cents in local currency only (no EUR equivalent).
  static String formatLocal(int centsEur, String targetCurrency) {
    if (targetCurrency.toUpperCase() == 'EUR') {
      return formatCents(centsEur);
    }
    return CurrencyService.formatCentsAsLocal(centsEur, targetCurrency);
  }

  /// Formats a local currency amount (not cents) for display.
  static String formatLocalAmount(double amount, String currencyCode) {
    return CurrencyService.formatLocal(amount, currencyCode);
  }
}
