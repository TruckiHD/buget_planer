import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const _baseUrl = 'https://api.frankfurter.dev/v2';
  static const _cacheKey = 'currency_rates_v2';
  static const _cacheDateKey = 'currency_rates_date_v2';

  static Map<String, double>? _rates;
  static final String _baseCurrency = 'EUR';

  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'EUR': CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', decimals: 2),
    'JPY': CurrencyInfo(code: 'JPY', name: 'Japanischer Yen', symbol: '¥', decimals: 0),
    'USD': CurrencyInfo(code: 'USD', name: 'US-Dollar', symbol: '\$', decimals: 2),
    'GBP': CurrencyInfo(code: 'GBP', name: 'Britisches Pfund', symbol: '£', decimals: 2),
    'CHF': CurrencyInfo(code: 'CHF', name: 'Schweizer Franken', symbol: 'CHF', decimals: 2),
    'CNY': CurrencyInfo(code: 'CNY', name: 'Chinesischer Yuan', symbol: '¥', decimals: 2),
    'KRW': CurrencyInfo(code: 'KRW', name: 'Südkoreanischer Won', symbol: '₩', decimals: 0),
    'THB': CurrencyInfo(code: 'THB', name: 'Thailändischer Baht', symbol: '฿', decimals: 2),
    'SGD': CurrencyInfo(code: 'SGD', name: 'Singapur-Dollar', symbol: 'S\$', decimals: 2),
    'AUD': CurrencyInfo(code: 'AUD', name: 'Australischer Dollar', symbol: 'A\$', decimals: 2),
    'CAD': CurrencyInfo(code: 'CAD', name: 'Kanadischer Dollar', symbol: 'C\$', decimals: 2),
    'MXN': CurrencyInfo(code: 'MXN', name: 'Mexikanischer Peso', symbol: 'MX\$', decimals: 2),
    'BRL': CurrencyInfo(code: 'BRL', name: 'Brasilianischer Real', symbol: 'R\$', decimals: 2),
    'INR': CurrencyInfo(code: 'INR', name: 'Indische Rupie', symbol: '₹', decimals: 2),
    'TRY': CurrencyInfo(code: 'TRY', name: 'Türkische Lira', symbol: '₺', decimals: 2),
    'PLN': CurrencyInfo(code: 'PLN', name: 'Polnischer Złoty', symbol: 'zł', decimals: 2),
    'CZK': CurrencyInfo(code: 'CZK', name: 'Tschechische Krone', symbol: 'Kč', decimals: 2),
    'HUF': CurrencyInfo(code: 'HUF', name: 'Ungarischer Forint', symbol: 'Ft', decimals: 0),
    'SEK': CurrencyInfo(code: 'SEK', name: 'Schwedische Krone', symbol: 'kr', decimals: 2),
    'NOK': CurrencyInfo(code: 'NOK', name: 'Norwegische Krone', symbol: 'kr', decimals: 2),
    'DKK': CurrencyInfo(code: 'DKK', name: 'Dänische Krone', symbol: 'kr', decimals: 2),
    'NZD': CurrencyInfo(code: 'NZD', name: 'Neuseeland-Dollar', symbol: 'NZ\$', decimals: 2),
    'ZAR': CurrencyInfo(code: 'ZAR', name: 'Südafrikanischer Rand', symbol: 'R', decimals: 2),
    'EGP': CurrencyInfo(code: 'EGP', name: 'Ägyptisches Pfund', symbol: 'E£', decimals: 2),
    'AED': CurrencyInfo(code: 'AED', name: 'VAE-Dirham', symbol: 'د.إ', decimals: 2),
    'IDR': CurrencyInfo(code: 'IDR', name: 'Indonesische Rupie', symbol: 'Rp', decimals: 0),
    'VND': CurrencyInfo(code: 'VND', name: 'Vietnamesischer Dong', symbol: '₫', decimals: 0),
    'PHP': CurrencyInfo(code: 'PHP', name: 'Philippinischer Peso', symbol: '₱', decimals: 2),
    'MYR': CurrencyInfo(code: 'MYR', name: 'Malaysischer Ringgit', symbol: 'RM', decimals: 2),
    'TWD': CurrencyInfo(code: 'TWD', name: 'Taiwan-Dollar', symbol: 'NT\$', decimals: 2),
  };

  static CurrencyInfo getInfo(String code) {
    return supportedCurrencies[code.toUpperCase()] ??
        CurrencyInfo(code: code.toUpperCase(), name: code, symbol: code, decimals: 2);
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);
    final cachedDate = prefs.getString(_cacheDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (cachedJson != null && cachedDate == today) {
      try {
        final data = jsonDecode(cachedJson) as Map<String, dynamic>;
        _rates = data.map((k, v) => MapEntry(k, (v as num).toDouble()));
        return;
      } catch (_) {}
    }

    await refresh();
  }

  static Future<bool> refresh() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rates?base=$_baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ratesData = data['rates'] as Map<String, dynamic>;
        _rates = ratesData.map((k, v) => MapEntry(k, (v as num).toDouble()));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(_rates));
        await prefs.setString(_cacheDateKey, DateTime.now().toIso8601String().substring(0, 10));
        return true;
      }
    } catch (_) {}
    return false;
  }

  static double? eurTo(String targetCurrency, double amountEur) {
    if (_rates == null) return null;
    final rate = _rates![targetCurrency.toUpperCase()];
    if (rate == null) return null;
    return amountEur * rate;
  }

  static double? toEur(String sourceCurrency, double amount) {
    if (_rates == null) return null;
    final rate = _rates![sourceCurrency.toUpperCase()];
    if (rate == null) return null;
    return amount / rate;
  }

  static double? convert(double amount, String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return amount;
    final inEur = toEur(from, amount);
    if (inEur == null) return null;
    return eurTo(to, inEur);
  }

  static double? getRate(String targetCurrency) {
    return _rates?[targetCurrency.toUpperCase()];
  }

  static String formatLocal(double amount, String currencyCode) {
    final info = getInfo(currencyCode);
    final formatted = amount.toStringAsFixed(info.decimals);
    return '${info.symbol}$formatted';
  }

  static String formatCentsAsLocal(int centsEur, String targetCurrency) {
    final eurAmount = centsEur / 100;
    final localAmount = eurTo(targetCurrency, eurAmount);
    if (localAmount == null) return '';
    return formatLocal(localAmount, targetCurrency);
  }

  static String formatDual(int centsEur, String targetCurrency) {
    if (targetCurrency.toUpperCase() == 'EUR') {
      return '€${(centsEur / 100).toStringAsFixed(0)}';
    }
    final local = formatCentsAsLocal(centsEur, targetCurrency);
    final eur = '€${(centsEur / 100).toStringAsFixed(0)}';
    return '$local (~$eur)';
  }

  static String? detectCurrency(String countryOrCity) {
    final lower = countryOrCity.toLowerCase();
    const map = {
      'japan': 'JPY', 'tokyo': 'JPY', 'kyoto': 'JPY', 'osaka': 'JPY',
      'hiroshima': 'JPY', 'nagoya': 'JPY', 'sapporo': 'JPY', 'fukuoka': 'JPY',
      'nara': 'JPY', 'yokohama': 'JPY', 'kobe': 'JPY', 'nikko': 'JPY',
      'hakone': 'JPY', 'nagano': 'JPY', 'kanazawa': 'JPY', 'sendai': 'JPY',
      'usa': 'USD', 'new york': 'USD', 'los angeles': 'USD', 'san francisco': 'USD',
      'chicago': 'USD', 'miami': 'USD', 'las vegas': 'USD', 'seattle': 'USD',
      'england': 'GBP', 'großbritannien': 'GBP', 'london': 'GBP', 'uk': 'GBP',
      'great britain': 'GBP',
      'schweiz': 'CHF', 'zürich': 'CHF', 'zurich': 'CHF', 'switzerland': 'CHF',
      'china': 'CNY', 'peking': 'CNY', 'beijing': 'CNY', 'shanghai': 'CNY',
      'südkorea': 'KRW', 'south korea': 'KRW', 'seoul': 'KRW',
      'thailand': 'THB', 'bangkok': 'THB',
      'singapur': 'SGD', 'singapore': 'SGD',
      'australien': 'AUD', 'australia': 'AUD', 'sydney': 'AUD', 'melbourne': 'AUD',
      'kanada': 'CAD', 'canada': 'CAD', 'toronto': 'CAD', 'vancouver': 'CAD',
      'mexiko': 'MXN', 'mexico': 'MXN', 'mexiko-stadt': 'MXN',
      'brasilien': 'BRL', 'brazil': 'BRL', 'rio de janeiro': 'BRL',
      'indien': 'INR', 'india': 'INR', 'mumbai': 'INR', 'delhi': 'INR',
      'türkei': 'TRY', 'turkey': 'TRY', 'istanbul': 'TRY',
      'polen': 'PLN', 'poland': 'PLN', 'krakau': 'PLN', 'krakow': 'PLN', 'warschau': 'PLN',
      'tschechien': 'CZK', 'czechia': 'CZK', 'czech republic': 'CZK', 'prag': 'CZK', 'prague': 'CZK',
      'ungarn': 'HUF', 'hungary': 'HUF', 'budapest': 'HUF',
      'schweden': 'SEK', 'sweden': 'SEK', 'stockholm': 'SEK',
      'norwegen': 'NOK', 'norway': 'NOK', 'oslo': 'NOK',
      'dänemark': 'DKK', 'denmark': 'DKK', 'kopenhagen': 'DKK', 'copenhagen': 'DKK',
      'neuseeland': 'NZD', 'new zealand': 'NZD', 'auckland': 'NZD',
      'südafrika': 'ZAR', 'south africa': 'ZAR', 'kapstadt': 'ZAR',
      'ägypten': 'EGP', 'egypt': 'EGP', 'kairo': 'EGP',
      'vae': 'AED', 'u.a.e.': 'AED', 'united arab emirates': 'AED', 'dubai': 'AED',
      'indonesien': 'IDR', 'indonesia': 'IDR', 'bali': 'IDR',
      'vietnam': 'VND', 'hanoi': 'VND', 'ho chi minh': 'VND',
      'philippinen': 'PHP', 'philippines': 'PHP',
      'malaysia': 'MYR',
      'taiwan': 'TWD',
    };
    for (final entry in map.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static bool get isLoaded => _rates != null;
}

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final int decimals;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimals,
  });
}
