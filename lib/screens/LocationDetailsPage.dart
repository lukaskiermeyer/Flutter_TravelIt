// lib/screens/LocationDetailsPage.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapp/services/location_service.dart';

class LocationDetailPage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String cityName;

  const LocationDetailPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(CupertinoIcons.back),
        ),
        title: Text(_formatCityAndCountry(cityName)),
      ),
      body: FutureBuilder<List<List<String>>>(
        future: Future.wait([
          locationService.fetchImages(cityName),
          locationService.fetchRecommendations(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load details: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            final images = snapshot.data![0];
            final recommendations = snapshot.data![1];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Images of ${_formatCityAndCountry(cityName)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(images[index]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Recommendations',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...recommendations.map((rec) => ListTile(
                      leading: const Icon(Icons.recommend),
                      title: Text(rec),
                    )),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('No data available.'));
        },
      ),
    );
  }

  String _formatCityAndCountry(String cityName) {
    List<String> parts = cityName.split(',');
    if (parts.length >= 2) {
      return "${parts[parts.length - 2].trim()}, ${parts.last.trim()}";
    }
    return cityName;
  }
}