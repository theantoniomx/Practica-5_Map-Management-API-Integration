class Place {
  final String name;
  final double lat;
  final double lon;
  final String category;
  final String address;

  Place({
    required this.name,
    required this.lat,
    required this.lon,
    required this.category,
    required this.address,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'];
    final geometry = json['geometry'];

    return Place(
      name: properties['name'] ?? 'Sin nombre',
      lat: geometry['coordinates'][1],
      lon: geometry['coordinates'][0],
      category: (properties['categories'] as List).isNotEmpty
          ? properties['categories'][0]
          : 'otro',
      address: properties['formatted'] ?? 'Dirección no disponible',
    );
  }
}
