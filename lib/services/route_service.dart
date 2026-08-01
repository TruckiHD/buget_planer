import 'dart:math';

import '../models/finance_models.dart';

class RouteService {
  static List<TripTransport> generateMissingRoutes(TripPlan trip) {
    if (trip.segments.length < 2) return [];
    final sorted = [...trip.segments]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    final existing = trip.transports;
    final missing = <TripTransport>[];

    for (var i = 0; i < sorted.length - 1; i++) {
      final from = sorted[i];
      final to = sorted[i + 1];
      final hasRoute = existing.any((t) => t.fromSegmentId == from.id && t.toSegmentId == to.id);
      if (!hasRoute) {
        missing.add(_autoGenerate(from, to));
      }
    }
    return missing;
  }

  static TripTransport _autoGenerate(TripSegment from, TripSegment to) {
    final distance = _calculateDistance(from, to);
    final mode = _suggestMode(distance);
    final cost = _estimateCost(distance, mode);
    final duration = _estimateDuration(distance, mode);

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

  static double _calculateDistance(TripSegment from, TripSegment to) {
    if (from.hasCoordinates && to.hasCoordinates) {
      return _haversine(from.latitude!, from.longitude!, to.latitude!, to.longitude!);
    }
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

  static TransportMode _suggestMode(double distanceKm) {
    if (distanceKm > 800) return TransportMode.flug;
    if (distanceKm > 100) return TransportMode.zug;
    return TransportMode.bus;
  }

  static int _estimateCost(double distanceKm, TransportMode mode) {
    switch (mode) {
      case TransportMode.flug:
        return (5000 + distanceKm * 5).round();
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
        return (90 + distanceKm * 0.1).round();
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

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  static int totalTransportCostCents(TripPlan trip) {
    return trip.transports.fold<int>(0, (sum, t) => sum + t.estimatedCostCents);
  }
}
