import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/geocoding_service.dart';
import '../../utils/app_theme.dart';

class TripLocationPicker extends StatelessWidget {
  final double? initialLat;
  final double? initialLng;
  final bool isDark;
  final LatLng? fallbackCenter;
  final void Function(double lat, double lng) onPicked;

  const TripLocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.isDark,
    this.fallbackCenter,
    required this.onPicked,
  });

  bool get _hasCoords => initialLat != null && initialLng != null && initialLat! > 0 && initialLng! > 0;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(
          _hasCoords ? 'Position gesetzt' : 'Hotel-Position auswählen',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
        )),
        if (_hasCoords)
          TextButton(
            onPressed: () => onPicked(0, 0),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Entfernen', style: TextStyle(fontSize: 11)),
          ),
      ]),
      const SizedBox(height: 8),
      if (_hasCoords) ...[
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: .2), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(initialLat!, initialLng!),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.budgetplanner.app',
                      maxZoom: 18,
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(initialLat!, initialLng!),
                        width: 28,
                        height: 28,
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 28),
                      ),
                    ]),
                  ],
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface2 : Colors.white).withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Tippe zum Ändern', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ] else
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openPicker(context),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Auf Karte wählen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
    ]);
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _LocationPickerPage(
          initialLat: initialLat,
          initialLng: initialLng,
          fallbackCenter: fallbackCenter,
          isDark: isDark,
        ),
      ),
    );
    if (result != null) {
      onPicked(result.latitude, result.longitude);
    }
  }
}

class _LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final LatLng? fallbackCenter;
  final bool isDark;

  const _LocationPickerPage({this.initialLat, this.initialLng, this.fallbackCenter, required this.isDark});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  LatLng? _picked;
  List<GeocodingResult> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null && widget.initialLat! > 0) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      final results = await GeocodingService.search(query);
      if (mounted) setState(() { _results = results; _searching = false; });
    });
  }

  void _selectResult(GeocodingResult result) {
    setState(() {
      _picked = result.coords;
      _results = [];
      _searchController.text = result.displayName.split(',').first.trim();
    });
    _mapController.move(result.coords, 15);
    _searchFocus.unfocus();
  }

  void _onTapMap(TapPosition pos, LatLng point) {
    setState(() {
      _picked = point;
      _results = [];
    });
  }

  void _confirm() {
    if (_picked != null) Navigator.pop(context, _picked);
  }

  LatLng get _initialCenter {
    if (_picked != null) return _picked!;
    if (widget.fallbackCenter != null) return widget.fallbackCenter!;
    return const LatLng(48.1351, 11.5820);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(child: Text('Ort auswählen', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : const Color(0xFFF0F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Hotel, Adresse oder Stadt suchen...',
                    hintStyle: TextStyle(color: mutedColor),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searching
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _results = []);
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_results.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(children: _results.map((r) {
                    final shortName = r.displayName.split(',').take(2).join(', ');
                    return InkWell(
                      onTap: () => _selectResult(r),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(shortName, style: TextStyle(fontSize: 13, color: textColor))),
                        ]),
                      ),
                    );
                  }).toList()),
                ),
            ]),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _picked != null ? 14 : (widget.fallbackCenter != null ? 8 : 5),
                onTap: _onTapMap,
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
                if (_picked != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _picked!,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 44),
                    ),
                  ]),
                const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: Column(children: [
              if (_picked != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 12, color: mutedColor, fontFamily: 'monospace'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _picked != null ? _confirm : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(_picked != null ? 'Position übernehmen' : 'Tippe auf die Karte'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
