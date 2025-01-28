import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  // Example method to create a marker
  final String _mapsKey = 'AIzaSyCJiBFO3Tsaejbu8kG1m3vvXFy47OMt9sg';

  Marker createMarker({
    required String markerId,
    required LatLng position,
    String? infoWindowTitle,
    String? infoWindowSnippet,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: infoWindowTitle,
        snippet: infoWindowSnippet,
      ),
    );
  }

  Future<String> getLocationName(double latitude, double longitude) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_mapsKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['results'][0]['formatted_address'];
      return address;
    } else {
      throw Exception('Failed to fetch location name');
    }
  }
}
