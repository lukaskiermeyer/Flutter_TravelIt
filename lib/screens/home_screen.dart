import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mysql1/mysql1.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<Marker> _currentMarker = [];
  late MySqlConnection _conn;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();

  }

  Future<void> _connectToDatabase() async {
    _conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'sql7.freesqldatabase.com',
      port: 3306,
      user: 'sql7712971',
      db: 'sql7712971',
      password: 'YnYC9zjPM1',
    ));
    _loadMarkersFromDatabase();
  }

  Future<void> _loadMarkersFromDatabase() async {
    final results = await _conn.query('SELECT * FROM markers');

    for (var row in results) {
      _markers.add(
        Marker(
          point: LatLng(row[1], row[2]),
          width: 30,
          height: 30,
          child: const Icon(Icons.location_pin),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _saveMarkerToDatabase() async {
    if (_currentMarker.isNotEmpty) {
      await _conn.query(
        'INSERT INTO markers (latitude, longitude) VALUES (?, ?)',
        [_currentMarker[0].point.latitude,_currentMarker[0].point.longitude]
      );
      _loadMarkersFromDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive World Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Handle menu button press
              
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
                initialCenter: const LatLng(51.509364, -0.128928),
                initialZoom: 4,
                onTap: (point, latLng) {
                  setState(() {
                    if (_currentMarker.isNotEmpty) {
                      _currentMarker[0] = Marker(
                        point: latLng,
                        width: 200,
                        height: 200,
                        child: const Icon(Icons.location_on_outlined),
                      );
                    } else {
                      _currentMarker.add(
                        Marker(
                          point: latLng,
                          width: 200,
                          height: 200,
                          child: const Icon(Icons.location_on_outlined),
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
                  onPressed: () async {
                    if (_currentMarker.isNotEmpty) {
                      setState(() async {
                        _currentMarker.add(
                          Marker(
                            point: _currentMarker.last.point,
                            width: 100,
                            height: 100,
                            child: const Icon(Icons.location_pin),
                          ),
                        );
                        //sql query to insert marker
                        await _saveMarkerToDatabase();
                        _currentMarker.clear();
                      });
                    }
                  },
                  child: const Text('Save Marker'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentMarker.clear();
                    });
                  },
                  child: const Text('Cancel Marker'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}