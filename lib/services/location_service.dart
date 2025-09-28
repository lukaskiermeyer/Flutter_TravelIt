import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  final String _unsplashKey = dotenv.env['UNSPLASH_KEY']!;

  Future<List<String>> fetchImages(String location) async {
    final url = "https://api.unsplash.com/search/photos?query=$location&client_id=$_unsplashKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List images = jsonDecode(response.body)['results'];
      return images.map<String>((img) => img['urls']['small']).toList();
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<List<String>> fetchRecommendations() async {
    // Hier kannst du später die tatsächliche Logik für Empfehlungen
    // einfügen, die z.B. von einer Datenbank oder einer externen API stammen.
    return Future.delayed(
      const Duration(seconds: 2),
          () => [
        "Visit the museum",
        "Walk in the park",
        "Try local food",
      ],
    );
  }
}