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
  List<Marker> _currentMarker = [];

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
                    if (_currentMarker.isNotEmpty) {
                      _currentMarker[0] = Marker(
                        point: latLng,
                        width: 200,
                        height: 200,
                        child: Icon(Icons.location_on_outlined),
                      );
                    } else {
                      _currentMarker.add(
                        Marker(
                          point: latLng,
                          width: 200,
                          height: 200,
                          child: Icon(Icons.location_on_outlined),
                        ),
                      );
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [..._markers, ..._currentMarker],
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
                    if (_currentMarker.isNotEmpty) {
                      setState(() {
                        _currentMarker.add(
                          Marker(
                            point: _currentMarker.last.point,
                            width: 100,
                            height: 100,
                            child: Icon(Icons.location_pin),
                          ),
                        );
                        _markers.add(_currentMarker[1]);
                        _currentMarker.clear();
                      });
                    }
                  },
                  child: Text('Save Marker'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentMarker.clear();
                    });
                  },
                  child: Text('Cancel Marker'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}