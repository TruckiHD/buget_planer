import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeocodingResult {
  final String displayName;
  final LatLng coords;

  const GeocodingResult({required this.displayName, required this.coords});
}

class GeocodingService {
  static const _cachePrefix = 'geocode_';
  static const _userAgent = 'BudgetPlannerApp/1.0 (contact: budgetplanner@example.com)';

  static Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      });
      if (response.statusCode != 200) {
        debugPrint('Nominatim search failed: ${response.statusCode} ${response.body}');
        return [];
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) {
        final lat = double.tryParse(item['lat'] as String) ?? 0;
        final lon = double.tryParse(item['lon'] as String) ?? 0;
        final name = item['display_name'] as String? ?? '';
        return GeocodingResult(displayName: name, coords: LatLng(lat, lon));
      }).where((r) => r.coords.latitude != 0 && r.coords.longitude != 0).toList();
    } catch (e, st) {
      debugPrint('Nominatim search error: $e\n$st');
      return [];
    }
  }

  static Future<LatLng?> geocodeCity(String city, {String? country}) async {
    final key = '${city.toLowerCase().trim()}${country != null ? ',${country.toLowerCase().trim()}' : ''}';
    final cached = await _getFromCache(key);
    if (cached != null) return cached;

    try {
      final query = country != null ? '$city, $country' : city;
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent});
      if (response.statusCode != 200) return null;

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;

      final lat = double.tryParse(list[0]['lat'] as String);
      final lon = double.tryParse(list[0]['lon'] as String);
      if (lat == null || lon == null) return null;

      final coords = LatLng(lat, lon);
      await _setCache(key, coords);
      return coords;
    } catch (_) {
      return null;
    }
  }

  static Future<LatLng?> _getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_cachePrefix$key');
      if (data == null) return null;
      final parts = data.split(',');
      if (parts.length != 2) return null;
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  static Future<void> _setCache(String key, LatLng coords) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', '${coords.latitude},${coords.longitude}');
    } catch (_) {}
  }
}
