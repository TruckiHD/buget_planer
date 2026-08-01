import 'dart:convert';

import '../models/finance_models.dart';

class ExportService {
  static String exportToJson(FinancialProfile profile) {
    final json = profile.toJson();
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  static FinancialProfile? importFromJson(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FinancialProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static String exportToCsv(FinancialProfile profile, {int? year}) {
    final y = year ?? DateTime.now().year;
    final buffer = StringBuffer();
    buffer.writeln('Datum,Titel,Kategorie,Typ,Betrag,Bestätigt');

    for (final entry in profile.entries) {
      if (entry.date.year == y) {
        buffer.writeln(
          '${_csvDate(entry.date)},'
          '${_escape(entry.title)},'
          '${_escape(entry.categoryLabel)},'
          '${entry.kind == TransactionKind.income ? "Einnahme" : "Ausgabe"},'
          '${(entry.amountCents / 100).toStringAsFixed(2)},'
          '${entry.isConfirmed ? "Ja" : "Nein"}',
        );
      }
    }

    for (final rec in profile.recurringTransactions) {
      buffer.writeln(
        '${_csvDate(rec.startsOn)},'
        '${_escape(rec.title)} (fällig),'
        '${_escape(rec.categoryLabel)},'
        '${rec.kind == TransactionKind.income ? "Einnahme" : "Ausgabe"},'
        '${(rec.amountCents / 100).toStringAsFixed(2)},'
        'Ja',
      );
    }

    return buffer.toString();
  }

  static String _csvDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
