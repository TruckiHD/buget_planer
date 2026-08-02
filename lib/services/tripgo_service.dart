import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';

class TripGoService {
  static const _apiKey = 'e919937371d9a56bc6f1a0566566756a';
  static const _baseUrl = 'https://api.tripgo.com/v1/routing.json';
  static const _cachePrefix = 'tripgo_cache_';
  static const _cacheDuration = Duration(hours: 24);

  static String _modeString(TransportMode mode) {
    switch (mode) {
      case TransportMode.zug:
        return 'pt_pub_train,pt_pub_regionaltrain';
      case TransportMode.bus:
        return 'pt_pub_bus,pt_pub_coach';
      case TransportMode.flug:
        return 'pt_pub';
      case TransportMode.faehre:
        return 'pt_pub_ferry';
      case TransportMode.auto:
        return 'me_car';
    }
  }

  static String _cacheKey(double fromLat, double fromLng, double toLat, double toLng, TransportMode mode) {
    return '$_cachePrefix${fromLat.toStringAsFixed(4)}_${fromLng.toStringAsFixed(4)}_${toLat.toStringAsFixed(4)}_${toLng.toStringAsFixed(4)}_${mode.name}';
  }

  static Future<TripGoResult?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required TransportMode mode,
  }) async {
    final key = _cacheKey(fromLat, fromLng, toLat, toLng, mode);

    // 1. Check cache
    final cached = await _getFromCache(key);
    if (cached != null) {
      debugPrint('TripGo: Cache hit for $key');
      return cached;
    }

    // 2. Call API
    try {
      final modes = _modeString(mode);
      final url = '$_baseUrl?from=($fromLat,$fromLng)&to=($toLat,$toLng)&modes=$modes&v=11&locale=de';
      
      debugPrint('TripGo: Calling API for ${mode.name}: $fromLat,$fromLng -> $toLat,$toLng');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'X-TripGo-Key': _apiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = _parseResponse(data);
        
        if (result != null) {
          debugPrint('TripGo: Got result - fare=${result.fareCents}cents, duration=${result.durationMinutes}min');
          await _saveToCache(key, result);
          return result;
        } else {
          debugPrint('TripGo: No fare data in response');
        }
      } else {
        debugPrint('TripGo: API error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('TripGo: Exception: $e');
    }

    return null;
  }

  static TripGoResult? _parseResponse(Map<String, dynamic> data) {
    try {
      final trips = data['trips'] as List<dynamic>?;
      if (trips == null || trips.isEmpty) return null;

      // Find the best trip (lowest weighted score)
      TripGoResult? bestResult;
      double bestScore = double.infinity;

      for (final trip in trips) {
        final tripMap = trip as Map<String, dynamic>;
        final score = (tripMap['weightedScore'] as num?)?.toDouble() ?? double.infinity;
        
        if (score < bestScore) {
          final result = _parseTrip(tripMap);
          if (result != null) {
            bestResult = result;
            bestScore = score;
          }
        }
      }

      return bestResult;
    } catch (e) {
      debugPrint('TripGo: Parse error: $e');
      return null;
    }
  }

  static TripGoResult? _parseTrip(Map<String, dynamic> trip) {
    try {
      final duration = (trip['duration'] as num?)?.toInt();
      if (duration == null) return null;

      int? fareCents;
      String? currency;

      // Look for fare in segments
      final segments = trip['segments'] as List<dynamic>?;
      if (segments != null) {
        for (final seg in segments) {
          final segMap = seg as Map<String, dynamic>;
          final cost = segMap['cost'] as Map<String, dynamic>?;
          if (cost != null) {
            final price = (cost['price'] as num?)?.toDouble();
            final curr = cost['currency'] as String?;
            if (price != null && price > 0) {
              // Convert to cents
              fareCents = (price * 100).round();
              currency = curr;
              break;
            }
          }
        }
      }

      return TripGoResult(
        durationMinutes: (duration / 60).round(),
        fareCents: fareCents,
        currency: currency ?? 'EUR',
      );
    } catch (e) {
      debugPrint('TripGo: Trip parse error: $e');
      return null;
    }
  }

  static Future<TripGoResult?> _getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached == null) return null;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      
      if (age > _cacheDuration.inMilliseconds) {
        await prefs.remove(key);
        return null;
      }

      return TripGoResult(
        durationMinutes: data['durationMinutes'] as int,
        fareCents: data['fareCents'] as int?,
        currency: data['currency'] as String? ?? 'EUR',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveToCache(String key, TripGoResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'durationMinutes': result.durationMinutes,
        'fareCents': result.fareCents,
        'currency': result.currency,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

class TripGoResult {
  final int durationMinutes;
  final int? fareCents;
  final String currency;

  const TripGoResult({
    required this.durationMinutes,
    this.fareCents,
    this.currency = 'EUR',
  });

  bool get hasFare => fareCents != null && fareCents! > 0;
}
