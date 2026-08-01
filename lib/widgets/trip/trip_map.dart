import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/finance_models.dart';
import '../../utils/app_theme.dart';

class TripMap extends StatefulWidget {
  final TripPlan trip;
  final bool isDark;
  final bool forceShow;

  const TripMap({super.key, required this.trip, required this.isDark, this.forceShow = false});

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  final MapController _mapController = MapController();

  List<TripSegment> get _sortedSegments {
    return [...widget.trip.segments.where((s) => s.hasCoordinates)]
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
  }

  void _fitToRoute() {
    final sorted = _sortedSegments;
    if (sorted.length < 2) return;
    final bounds = LatLngBounds.fromPoints(
      sorted.map((s) => LatLng(s.latitude!, s.longitude!)).toList(),
    );
    _mapController.move(bounds.center, _zoomForBounds(bounds));
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _FullscreenMap(trip: widget.trip, isDark: widget.isDark)),
    );
  }

  static double _zoomForBounds(LatLngBounds bounds) {
    final ne = bounds.northEast;
    final sw = bounds.southWest;
    final latDiff = (ne.latitude - sw.latitude).abs();
    final lngDiff = (ne.longitude - sw.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    if (maxDiff > 50) return 3;
    if (maxDiff > 20) return 4;
    if (maxDiff > 10) return 5;
    if (maxDiff > 5) return 6;
    if (maxDiff > 2) return 7;
    if (maxDiff > 1) return 8;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    final segments = _sortedSegments;
    if (segments.isEmpty) {
      if (!widget.forceShow) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(children: [
          Icon(Icons.map_outlined, size: 32, color: AppColors.primary.withValues(alpha: .4)),
          const SizedBox(height: 8),
          Text(
            'Setze Koordinaten für deine Hotels\num die Route auf der Karte zu sehen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: widget.isDark ? AppColors.darkMuted : AppColors.lightMuted),
          ),
        ]),
      );
    }

    final markers = _buildMarkers(segments);
    final polylines = _buildPolylines(segments);
    final bounds = LatLngBounds.fromPoints(
      segments.map((s) => LatLng(s.latitude!, s.longitude!)).toList(),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow,
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 450,
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: bounds.center,
                initialZoom: _zoomForBounds(bounds),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: widget.isDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.budgetplanner.app',
                  maxZoom: 18,
                  minZoom: 2,
                  tileDisplay: const TileDisplay.fadeIn(),
                  evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                  keepBuffer: 2,
                ),
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
                const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 36,
              child: Column(children: [
                _mapButton(Icons.add_rounded, () {
                  final cam = _mapController.camera;
                  _mapController.move(cam.center, cam.zoom + 1);
                }),
                const SizedBox(height: 4),
                _mapButton(Icons.remove_rounded, () {
                  final cam = _mapController.camera;
                  _mapController.move(cam.center, cam.zoom - 1);
                }),
                const SizedBox(height: 10),
                if (segments.length >= 2)
                  _mapButton(Icons.fit_screen_rounded, _fitToRoute),
                const SizedBox(height: 4),
                _mapButton(Icons.fullscreen_rounded, _openFullscreen),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: widget.isDark ? AppColors.darkSurface2 : Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<TripSegment> sorted) {
    return List.generate(sorted.length, (i) {
      final s = sorted[i];
      return Marker(
        point: LatLng(s.latitude!, s.longitude!),
        width: 54,
        height: 54,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurface2 : Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Text(
              s.location,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: widget.isDark ? AppColors.darkText : AppColors.lightText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
    });
  }

  List<Polyline> _buildPolylines(List<TripSegment> sorted) {
    return List.generate(sorted.length - 1, (i) {
      return Polyline(
        points: [
          LatLng(sorted[i].latitude!, sorted[i].longitude!),
          LatLng(sorted[i + 1].latitude!, sorted[i + 1].longitude!),
        ],
        color: AppColors.primary.withValues(alpha: .5),
        strokeWidth: 3,
        pattern: const StrokePattern.dotted(),
      );
    });
  }
}

class _FullscreenMap extends StatelessWidget {
  final TripPlan trip;
  final bool isDark;

  const _FullscreenMap({required this.trip, required this.isDark});

  static double _zoomForBounds(LatLngBounds bounds) {
    final ne = bounds.northEast;
    final sw = bounds.southWest;
    final latDiff = (ne.latitude - sw.latitude).abs();
    final lngDiff = (ne.longitude - sw.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    if (maxDiff > 50) return 3;
    if (maxDiff > 20) return 4;
    if (maxDiff > 10) return 5;
    if (maxDiff > 5) return 6;
    if (maxDiff > 2) return 7;
    if (maxDiff > 1) return 8;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...trip.segments.where((s) => s.hasCoordinates)]
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));

    final markers = List.generate(sorted.length, (i) {
      final s = sorted[i];
      return Marker(
        point: LatLng(s.latitude!, s.longitude!),
        width: 60,
        height: 75,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface2 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Text(
              s.location,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
    });

    final polylines = List.generate(sorted.length - 1, (i) {
      return Polyline(
        points: [
          LatLng(sorted[i].latitude!, sorted[i].longitude!),
          LatLng(sorted[i + 1].latitude!, sorted[i + 1].longitude!),
        ],
        color: AppColors.primary.withValues(alpha: .5),
        strokeWidth: 3,
        pattern: const StrokePattern.dotted(),
      );
    });

    final bounds = sorted.length >= 2
        ? LatLngBounds.fromPoints(sorted.map((s) => LatLng(s.latitude!, s.longitude!)).toList())
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(trip.name)),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: bounds?.center ?? const LatLng(48.1351, 11.5820),
          initialZoom: bounds != null ? _zoomForBounds(bounds) : 5,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: isDark
                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.budgetplanner.app',
            maxZoom: 18,
            minZoom: 2,
            tileDisplay: const TileDisplay.fadeIn(),
            evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
          ),
          if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
          const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
        ],
      ),
    );
  }
}
