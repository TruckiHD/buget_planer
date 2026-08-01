# Budget Planer

Eine lokale Flutter-App für Monatsbudget, Sparziele und Reiseprognosen.

## Funktionen

- Aktuelles Guthaben, Sicherheitsreserve und frei planbares Geld
- Monatliche Einnahmen und regelmäßige Fixkosten
- Bestätigte und geplante einzelne Buchungen
- Reisebudget mit festen Kosten, Tagesbudget und Puffer
- Reiseabschnitte mit eigenen Zeiträumen, Hotels und Hotelpreisen
- Eigene Reise-Detailseite zum Bearbeiten und Löschen aller Reisedaten
- Essensbudget pro Reisetag mit Sparsam-/Normal-/Komfort-Vorschlägen
- Einzelne geplante Reisekosten wie Züge, Tickets und SIM-Karten
- Prognose des verfügbaren Geldes am Reisetag
- Vorsichtiges, realistisches und optimistisches Szenario
- Sparziele mit Deadline und monatlicher Zuteilung
- Geplante zukünftige Anschaffungen mit Termin und reserviertem Betrag
- Monatsnavigation mit Prognose für Einnahmen, Fixkosten, Reisezahlungen und Käufe
- Responsive Navigation für iPhone, iPad und Mac
- Lokale Speicherung mit `shared_preferences`

## Starten

```bash
flutter pub get
flutter run
```

Für Desktop:

```bash
flutter run -d macos
```

Die Berechnungen verwenden Integer-Cents und liegen unabhängig von der UI in `lib/services/projection_service.dart`.
