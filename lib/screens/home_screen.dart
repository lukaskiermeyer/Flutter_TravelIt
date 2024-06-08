import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  Marker? _currentMarker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interactive World Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Handle menu button press
              print("Menu button pressed");
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(51.509364, -0.128928),
                initialZoom: 9.2,
                onTap: (point, latLng) {
                  setState(() {
                    _currentMarker = Marker(
                      point: latLng,
                      width: 30,
                      height: 30,
                      child: Icon(Icons.location_pin),
                    );
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_currentMarker != null) {
                      setState(() {
                        _markers.add(_currentMarker!);
                        _currentMarker = null;
                      });
                    }
                  },
                  child: Text('Save Marker'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle button press
                    print("Button 2 pressed");
                  },
                  child: Text('Button 2'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}