import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:practica5/models/place.dart';
import 'package:latlong2/latlong.dart';

class GeoapifyService {
  final String apiKey;

  GeoapifyService({required this.apiKey});

  Future<List<Place>> getNearbyPlaces(
    double lat,
    double lon,
    String category,
  ) async {
    final url =
        'https://api.geoapify.com/v2/places?categories=$category&filter=circle:$lon,$lat,5000&limit=50&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['features'] as List).map((e) => Place.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar lugares cercanos');
    }
  }

  Future<List<LatLng>> getRoutePoints({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    final url =
        'https://api.geoapify.com/v1/routing?waypoints=$startLat,$startLon|$endLat,$endLon&mode=drive&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'];
      final geometry = features[0]['geometry'];

      if (geometry['type'] == 'MultiLineString') {
        final coordinates = geometry['coordinates'][0];
        return coordinates.map<LatLng>((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
      } else {
        throw Exception('Formato de geometría no esperado');
      }
    } else {
      throw Exception('Error al obtener la ruta');
    }
  }

}
