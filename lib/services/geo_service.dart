import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeoService {
  final String _apiKey = dotenv.env['GEOAPIFY_KEY']!;

  Future<String> getCountyName(double lat, double long) async {
    final url = "https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$long&type=city&apiKey=$_apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['features'][0]['properties']['formatted'];
    }
    throw Exception("Failed to fetch city name");
  }

  Future<LatLng> getCoordinates(String city) async {
    final url = "https://api.geoapify.com/v1/geocode/search?text=$city&format=json&apiKey=$_apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return LatLng(jsonData['results'][0]['lat'], jsonData['results'][0]['lon']);
    }
    throw Exception("Failed to get coordinates");
  }

  Future<List<String>> getAutoComplete(String city) async {
    final url = "https://api.geoapify.com/v1/geocode/autocomplete?text=$city&format=json&apiKey=$_apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return List<String>.from(jsonData['results'].map((result) => result['formatted']));
    } else {
      throw Exception("Failed to get autocomplete suggestions");
    }
  }
}
