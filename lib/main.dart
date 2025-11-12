// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

/// Replace with your API key (enable Maps SDK for Android/iOS + Places API)
const String kGoogleApiKey = 'YOUR_API_KEY_HERE';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Map with Search',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapSearchPage(),
    );
  }
}

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late GooglePlace _googlePlace;
  List<AutocompletePrediction> _predictions = [];

  Map<MarkerId, Marker> _markers = {};
  LatLng _initialCenter = const LatLng(40.7128, -74.0060); // New York default
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 13,
  );

  bool _isSearching = false;
  DetailsResult? _selectedPlaceDetails;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(kGoogleApiKey);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    // Clear existing markers and add a custom marker at tap location
    setState(() {
      _markers.clear();
      final markerId = MarkerId('custom-${position.latitude}-${position.longitude}');
      final marker = Marker(
        markerId: markerId,
        position: position,
        infoWindow: InfoWindow(
          title: 'Selected location',
          snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
        ),
      );
      _markers[markerId] = marker;
      _selectedPlaceDetails = null;
    });
  }

  Future<void> _onSearchChanged(String input) async {
    if (input.isEmpty) { 
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Request autocomplete predictions
    final result = await _googlePlace.autocomplete.get(input, language: "en");

    if (mounted) {
      setState(() {
        _predictions = result?.predictions ?? [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectPrediction(AutocompletePrediction p) async {
    // Hide keyboard & suggestions
    _searchFocus.unfocus();
    setState(() {
      _predictions = [];
      _searchController.text = p.description ?? '';
    });

    if (p.placeId == null) return;

    // Get place details (geometry)
    final details = await _googlePlace.details.get(p.placeId!);
    if (details == null || details.result == null) return;

    final result = details.result!;
    final location = result.geometry?.location;
    if (location == null) return;

    final lat = location.lat!;
    final lng = location.lng!;
    final placeLatLng = LatLng(lat, lng);

    // Clear existing markers and add a marker for this place
    setState(() {
      _markers.clear();
      final markerId = MarkerId(p.placeId!);
      final marker = Marker(
        markerId: markerId,
        position: placeLatLng,
        infoWindow: InfoWindow(
          title: result.name ?? p.description,
          snippet: result.formattedAddress ?? '',
          onTap: () {
            // Optionally display additional details in a bottom sheet
            _showPlaceDetailsSheet(result);
          },
        ),
      );
      _markers[markerId] = marker;
      _selectedPlaceDetails = result;
    });

    // Animate camera to the place
    final controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: placeLatLng, zoom: 16)));
  }

  void _showPlaceDetailsSheet(DetailsResult detailsResult) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                Text(detailsResult.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (detailsResult.formattedAddress != null) Text(detailsResult.formattedAddress!),
                if (detailsResult.formattedPhoneNumber != null) ...[
                  const SizedBox(height: 8),
                  Text('Phone: ${detailsResult.formattedPhoneNumber!}'),
                ],
                if (detailsResult.website != null) ...[
                  const SizedBox(height: 8),
                  Text('Website: ${detailsResult.website!}', style: const TextStyle(color: Colors.blue)),
                ],
                if (detailsResult.rating != null) ...[
                  const SizedBox(height: 8),
                  Text('Rating: ${detailsResult.rating} / 5'),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: 'Search places or addresses',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  // Optionally handle submit
                },
              ),
            ),
            // Suggestions list
            if (_predictions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _predictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(p.structuredFormatting?.mainText ?? p.description ?? ''),
                      subtitle: p.structuredFormatting?.secondaryText != null
                          ? Text(p.structuredFormatting!.secondaryText!)
                          : null,
                      onTap: () => _selectPrediction(p),
                    );
                  },
                ),
              )
            else if (_isSearching)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Searching...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_selectedPlaceDetails == null) return const SizedBox.shrink();

    final d = _selectedPlaceDetails!;
    return Positioned(
      right: 12,
      bottom: 12,
      child: Card(
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.all(12),
          width: MediaQuery.of(context).size.width * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (d.formattedAddress != null) Text(d.formattedAddress!),
              if (d.formattedPhoneNumber != null) ...[
                const SizedBox(height: 6),
                Text('Phone: ${d.formattedPhoneNumber!}'),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _showPlaceDetailsSheet(d);
                    },
                    child: const Text('Details'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markersSet = Set<Marker>.from(_markers.values);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: _onMapCreated,
            markers: markersSet,
            onTap: _onMapTap,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          // Search bar + predictions
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _buildSearchBar(),
          ),
          // Selected place info card (bottom right)
          _buildInfoCard(),
        ],
      ),
    );
  }
}