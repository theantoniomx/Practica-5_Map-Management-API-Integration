import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:practica5/models/place.dart';
import 'package:practica5/services/geoapify_service.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  late MapController _mapController;

  String _currentMapStyle = 'osm-carto';
  final Map<String, String> _mapStyles = {
    'NORMAL': 'osm-carto',
    'LIMPIO': 'klokantech-basic',
    'NOCHE': 'dark-matter-brown',
    'HIBRIDO': 'dark-matter-yellow-roads',
  };

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'commercial.supermarket',
      'label': 'Tiendas',
      'icon': Icons.shopping_cart,
    },
    {
      'value': 'catering.restaurant',
      'label': 'Restaurantes',
      'icon': Icons.restaurant,
    },
    {'value': 'accommodation.hotel', 'label': 'Hoteles', 'icon': Icons.hotel},
    {
      'value': 'healthcare.pharmacy',
      'label': 'Farmacias',
      'icon': Icons.local_pharmacy,
    },
    {
      'value': 'parking.cars',
      'label': 'Estacionamientos',
      'icon': Icons.local_parking,
    },
    {'value': 'leisure.park', 'label': 'Parques', 'icon': Icons.park},
  ];
  Map<String, IconData> _categoryIcons = {};

  String? _selectedCategory;
  final String _apiKey = '01795da06586466682d8a4ee56e253bf';
  final _geoapifyService = GeoapifyService(
    apiKey: '01795da06586466682d8a4ee56e253bf',
  );
  List<Place> _places = [];
  Place? _selectedPlace;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _determinePosition();
    for (var cat in _categories) {
      _categoryIcons[cat['value']] = cat['icon'];
    }
  }

  Future<void> _determinePosition() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _recenterMap() async {
    final position = await Geolocator.getCurrentPosition();
    final newLoc = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = newLoc;
      _selectedLocation = newLoc;
      _selectedCategory = null;
      _places.clear();
      _routePoints.clear();
    });
    _mapController.move(newLoc, 15);
  }

  Future<void> _fetchPlaces() async {
    if (_selectedLocation != null && _selectedCategory != null) {
      final places = await _geoapifyService.getNearbyPlaces(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _selectedCategory!,
      );
      setState(() {
        _places = places;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Practica 5: Geoapify API")),
      body: Stack(
        children: [
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation!,
                    minZoom: 5,
                    initialZoom: 15,
                    initialRotation: 0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                    onTap: (_, latLng) {
                      setState(() {
                        _selectedLocation = latLng;
                        _selectedCategory = null;
                        _places.clear();
                        _routePoints.clear();
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://maps.geoapify.com/v1/tile/$_currentMapStyle/{z}/{x}/{y}.png?apiKey=$_apiKey',
                      userAgentPackageName: 'com.example.app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: _selectedLocation!,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    if (_places.isNotEmpty)
                      MarkerLayer(
                        markers: _places
                            .map(
                              (place) => Marker(
                                width: 30,
                                height: 30,
                                point: LatLng(place.lat, place.lon),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPlace = place;
                                    });
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) =>
                                          _buildPlaceDetailSheet(place),
                                    );
                                  },
                                  child: Icon(
                                    _categoryIcons[_selectedCategory] ??
                                        Icons.place,
                                    color: Colors.lightGreen,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: DropdownButtonHideUnderline(
                child: IgnorePointer(
                  ignoring: _selectedLocation == null,
                  child: DropdownButton2(
                    isExpanded: true,
                    hint: Text(
                      _selectedLocation == null
                          ? "Toca el mapa o usa 'Mi ubicación'"
                          : "Selecciona categoría",
                      style: const TextStyle(color: Colors.black),
                    ),
                    value: _selectedCategory,
                    items: _categories
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['value'],
                            child: Row(
                              children: [
                                Icon(item['icon'], size: 20),
                                const SizedBox(width: 8),
                                Text(item['label']),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (_selectedLocation != null) {
                        setState(() {
                          _selectedCategory = value as String;
                          _routePoints.clear();
                        });
                        _fetchPlaces();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 80,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withOpacity(0.4),
        ),
        children: [
          _buildFabWithLabel('Mi ubicación', Icons.my_location, _recenterMap),

          _buildFabWithLabel('Normal', Icons.map, () {
            setState(() => _currentMapStyle = _mapStyles['NORMAL']!);
          }),

          _buildFabWithLabel('Limpio', Icons.filter_none, () {
            setState(() => _currentMapStyle = _mapStyles['LIMPIO']!);
          }),

          _buildFabWithLabel('Noche', Icons.nightlight_round, () {
            setState(() => _currentMapStyle = _mapStyles['NOCHE']!);
          }),

          _buildFabWithLabel('Híbrido', Icons.terrain, () {
            setState(() => _currentMapStyle = _mapStyles['HIBRIDO']!);
          }),
        ],
      ),
    );
  }

  Widget _buildFabWithLabel(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          tooltip: label,
          child: Icon(icon),
          onPressed: onPressed,
        ),
      ],
    );
  }

  Widget _buildPlaceDetailSheet(Place place) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(place.address)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final route = await _geoapifyService.getRoutePoints(
                  startLat: _selectedLocation!.latitude,
                  startLon: _selectedLocation!.longitude,
                  endLat: place.lat,
                  endLon: place.lon,
                );
                setState(() {
                  _routePoints = route;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo obtener la ruta')),
                );
              }
            },
            icon: const Icon(Icons.route),
            label: const Text("Ver Ruta"),
          ),
        ],
      ),
    );
  }
}
