import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';
import 'tripgo_service.dart';

class RouteService {
  static const _osrmUrl = 'https://router.project-osrm.org/route/v1/driving';
  static const _cacheKey = 'osrm_route_cache_v1';
  static Map<String, OsrmRouteResult>? _cache;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        _cache = data.map((k, v) => MapEntry(k, OsrmRouteResult.fromJson(Map<String, dynamic>.from(v as Map))));
      } catch (_) {
        _cache = {};
      }
    } else {
      _cache = {};
    }
  }

  static Future<void> _saveCache() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = _cache!.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  static String _cacheKeyFor(double lat1, double lon1, double lat2, double lon2) {
    return '${lat1.toStringAsFixed(4)},${lon1.toStringAsFixed(4)}-${lat2.toStringAsFixed(4)},${lon2.toStringAsFixed(4)}';
  }

  static Future<OsrmRouteResult?> _fetchOsrm(double lat1, double lon1, double lat2, double lon2) async {
    final key = _cacheKeyFor(lat1, lon1, lat2, lon2);
    if (_cache != null && _cache!.containsKey(key)) {
      return _cache![key];
    }

    try {
      final url = '$_osrmUrl/$lon1,$lat1;$lon2,$lat2?overview=false';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List).first as Map<String, dynamic>;
          final result = OsrmRouteResult(
            distanceKm: (route['distance'] as num) / 1000.0,
            durationMinutes: ((route['duration'] as num) / 60.0).round(),
          );
          _cache ??= {};
          _cache![key] = result;
          await _saveCache();
          return result;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<TripTransport>> generateMissingRoutes(TripPlan trip) async {
    if (trip.segments.length < 2) return [];
    final sorted = [...trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    final existing = trip.transports;
    final missing = <TripTransport>[];

    for (var i = 0; i < sorted.length - 1; i++) {
      final from = sorted[i];
      final to = sorted[i + 1];
      final hasRoute = existing.any((t) => t.fromSegmentId == from.id && t.toSegmentId == to.id);
      if (!hasRoute) {
        final transport = await _autoGenerateWithApi(from, to, trip);
        debugPrint('RouteService: ${from.location} → ${to.location}: mode=${transport.mode.label}, cost=${transport.estimatedCostCents}cents, duration=${transport.durationMinutes}min');
        missing.add(transport);
      }
    }
    debugPrint('RouteService: Generated ${missing.length} missing routes, existing=${existing.length}');
    return missing;
  }

  static Future<TripTransport> _autoGenerateWithApi(TripSegment from, TripSegment to, TripPlan trip) async {
    final haversineDist = _calculateDistance(from, to);
    final mode = _suggestMode(from, to, haversineDist, trip);

    // Skip TripGo API for Japan routes (unsupported region, always fails)
    if (!_isJapanTrip(trip) && from.hasCoordinates && to.hasCoordinates) {
      try {
        final result = await TripGoService.getRoute(
          fromLat: from.latitude!,
          fromLng: from.longitude!,
          toLat: to.latitude!,
          toLng: to.longitude!,
          mode: mode,
        );

        if (result != null) {
          debugPrint('RouteService: TripGo API result - fare=${result.fareCents}cents, duration=${result.durationMinutes}min');
          return TripTransport(
            id: 'auto_${from.id}_${to.id}',
            fromSegmentId: from.id,
            toSegmentId: to.id,
            fromLocation: from.location,
            toLocation: to.location,
            mode: mode,
            estimatedCostCents: result.fareCents ?? _estimateCost(haversineDist, mode),
            durationMinutes: result.durationMinutes,
            departureDate: from.endsOn,
            isBooked: false,
          );
        }
      } catch (e) {
        debugPrint('RouteService: TripGo API failed, using formula fallback: $e');
      }
    }

    // Fallback to formula-based estimation
    return _autoGenerate(from, to, trip);
  }

  static TripTransport _autoGenerate(TripSegment from, TripSegment to, TripPlan trip) {
    final haversineDist = _calculateDistance(from, to);
    final mode = _suggestMode(from, to, haversineDist, trip);
    final isJapan = _isJapanTrip(trip);

    int cost;
    int duration;

    if (mode == TransportMode.flug) {
      cost = _estimateFlightCost(haversineDist);
      duration = _estimateFlightDuration(haversineDist);
    } else if (isJapan && mode == TransportMode.zug) {
      cost = _estimateShinkansenCost(haversineDist);
      duration = _estimateShinkansenDuration(haversineDist);
    } else {
      cost = _estimateCost(haversineDist, mode);
      duration = _estimateDuration(haversineDist, mode);
    }

    return TripTransport(
      id: 'auto_${from.id}_${to.id}',
      fromSegmentId: from.id,
      toSegmentId: to.id,
      fromLocation: from.location,
      toLocation: to.location,
      mode: mode,
      estimatedCostCents: cost,
      durationMinutes: duration,
      departureDate: from.endsOn,
      isBooked: false,
    );
  }

  static Future<TripTransport> generateWithRealDistance(TripSegment from, TripSegment to, TripPlan trip) async {
    final haversineDist = _calculateDistance(from, to);
    final mode = _suggestMode(from, to, haversineDist, trip);
    final isJapan = _isJapanTrip(trip);

    double distanceKm = haversineDist;
    int? realDuration;

    if (from.hasCoordinates && to.hasCoordinates && mode != TransportMode.flug) {
      final osrm = await _fetchOsrm(from.latitude!, from.longitude!, to.latitude!, to.longitude!);
      if (osrm != null) {
        distanceKm = osrm.distanceKm;
        realDuration = osrm.durationMinutes;
      }
    }

    int cost;
    int duration;

    if (mode == TransportMode.flug) {
      cost = _estimateFlightCost(distanceKm);
      duration = _estimateFlightDuration(distanceKm);
    } else if (isJapan && mode == TransportMode.zug) {
      cost = _estimateShinkansenCost(distanceKm);
      duration = realDuration ?? _estimateShinkansenDuration(distanceKm);
    } else {
      cost = _estimateCost(distanceKm, mode);
      duration = realDuration ?? _estimateDuration(distanceKm, mode);
    }

    return TripTransport(
      id: 'auto_${from.id}_${to.id}',
      fromSegmentId: from.id,
      toSegmentId: to.id,
      fromLocation: from.location,
      toLocation: to.location,
      mode: mode,
      estimatedCostCents: cost,
      durationMinutes: duration,
      departureDate: from.endsOn,
      isBooked: false,
    );
  }

  static bool _isJapanTrip(TripPlan trip) {
    final dest = trip.destination.toLowerCase();
    return dest.contains('japan') || dest.contains('tokyo') ||
        dest.contains('kyoto') || dest.contains('osaka') ||
        dest.contains('hiroshima') || dest.contains('nagoya') ||
        dest.contains('sapporo') || dest.contains('fukuoka') ||
        dest.contains('matsumoto') || dest.contains('takayama') ||
        dest.contains('kanazawa') || dest.contains('nagano') ||
        dest.contains('toyama') || dest.contains('hakuba') ||
        dest.contains('yokohama') || dest.contains('sendai');
  }

  static bool _isJapanSegment(TripSegment seg) {
    final loc = seg.location.toLowerCase();
    return loc.contains('japan') || loc.contains('tokyo') ||
        loc.contains('kyoto') || loc.contains('osaka') ||
        loc.contains('hiroshima') || loc.contains('nagoya') ||
        loc.contains('sapporo') || loc.contains('fukuoka') ||
        loc.contains('nara') || loc.contains('yokohama') ||
        loc.contains('kobe') || loc.contains('nikko') ||
        loc.contains('hakone') || loc.contains('kanazawa') ||
        loc.contains('matsumoto') || loc.contains('takayama') ||
        loc.contains('toyama') || loc.contains('nagano') ||
        loc.contains('hakuba') || loc.contains('sendai') ||
        loc.contains('kamakura') || loc.contains('takasaki');
  }

  static TransportMode _suggestMode(TripSegment from, TripSegment to, double distanceKm, TripPlan trip) {
    final isJapanRoute = _isJapanSegment(from) && _isJapanSegment(to);

    if (isJapanRoute) {
      if (distanceKm > 800) return TransportMode.flug;
      if (distanceKm > 30) return TransportMode.zug;
      return TransportMode.bus;
    }

    if (distanceKm > 800) return TransportMode.flug;
    if (distanceKm > 100) return TransportMode.zug;
    return TransportMode.bus;
  }

  static int _estimateFlightCost(double distanceKm) {
    return (5000 + distanceKm * 5).round();
  }

  static int _estimateFlightDuration(double distanceKm) {
    return (90 + distanceKm * 0.1).round();
  }

  static int _estimateShinkansenCost(double distanceKm) {
    if (distanceKm <= 100) return (2000 + distanceKm * 15).round();
    if (distanceKm <= 250) return (3000 + distanceKm * 11).round();
    if (distanceKm <= 400) return (4500 + distanceKm * 8).round();
    return (6000 + distanceKm * 6).round();
  }

  static int _estimateShinkansenDuration(double distanceKm) {
    return (25 + distanceKm * 0.35).round();
  }

  static int _estimateCost(double distanceKm, TransportMode mode) {
    switch (mode) {
      case TransportMode.flug:
        return _estimateFlightCost(distanceKm);
      case TransportMode.zug:
        return (2000 + distanceKm * 10).round();
      case TransportMode.bus:
        return (1000 + distanceKm * 5).round();
      case TransportMode.faehre:
        return (3000 + distanceKm * 8).round();
      case TransportMode.auto:
        return (1500 + distanceKm * 7).round();
    }
  }

  static int _estimateDuration(double distanceKm, TransportMode mode) {
    switch (mode) {
      case TransportMode.flug:
        return _estimateFlightDuration(distanceKm);
      case TransportMode.zug:
        return (30 + distanceKm * 0.4).round();
      case TransportMode.bus:
        return (30 + distanceKm * 0.6).round();
      case TransportMode.faehre:
        return (60 + distanceKm * 0.5).round();
      case TransportMode.auto:
        return (30 + distanceKm * 0.5).round();
    }
  }

  static double _calculateDistance(TripSegment from, TripSegment to) {
    if (from.hasCoordinates && to.hasCoordinates) {
      final dist = _haversine(from.latitude!, from.longitude!, to.latitude!, to.longitude!);
      debugPrint('RouteService: Haversine ${from.location}(${from.latitude},${from.longitude}) → ${to.location}(${to.latitude},${to.longitude}) = ${dist}km');
      return dist;
    }
    debugPrint('RouteService: No coordinates for ${from.location} or ${to.location}, using fallback 300km');
    return 300.0;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180.0;

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  static int totalTransportCostCents(TripPlan trip) {
    return trip.transports.fold<int>(0, (sum, t) => sum + t.estimatedCostCents);
  }

  static String getTransportLabel(TransportMode mode, TripPlan? trip) {
    if (trip != null && _isJapanTrip(trip) && mode == TransportMode.zug) {
      return 'Shinkansen';
    }
    return mode.label;
  }
}

class OsrmRouteResult {
  final double distanceKm;
  final int durationMinutes;

  const OsrmRouteResult({required this.distanceKm, required this.durationMinutes});

  Map<String, dynamic> toJson() => {
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
  };

  factory OsrmRouteResult.fromJson(Map<String, dynamic> json) => OsrmRouteResult(
    distanceKm: (json['distanceKm'] as num).toDouble(),
    durationMinutes: json['durationMinutes'] as int,
  );
}
