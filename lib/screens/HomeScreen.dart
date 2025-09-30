import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:zapp/models/map_model.dart';
import 'package:zapp/models/marker_data_model.dart';
import 'package:zapp/screens/EditMarkerPage.dart';
import 'package:zapp/screens/LocationDetailsPage.dart';
import 'package:zapp/screens/SearchFriends.dart';
import 'package:zapp/services/auth_service.dart';
import 'package:zapp/services/color_service.dart';
import 'package:zapp/services/geo_service.dart';
import 'package:zapp/services/map_service.dart';

import 'LoginPage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchTextController = TextEditingController();
  final List<Marker> _currentMarker = [];
  bool _isPanelVisible = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Lade die initialen Daten, sobald das Widget erstellt wird
    final authService = Provider.of<AuthService>(context, listen: false);
    final mapService = Provider.of<MapService>(context, listen: false);
    mapService.loadInitialData(authService.currentUser!.id);
  }

  @override
  Widget build(BuildContext context) {
    // Services über Provider abrufen.
    final geoService = Provider.of<GeoService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Consumer<MapService>(
          builder: (context, mapService, child) {
            return DropdownButton<MapModel>(
              value: mapService.selectedMap,
              items: mapService.maps.map((map) {
                return DropdownMenuItem<MapModel>(
                  value: map,
                  child: Text(map.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  mapService.selectMapAndLoadMarkers (value);
                }
              },
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              final user = authService.currentUser;
              if (user == null) {
                // Führe nichts aus, wenn der Benutzer nicht eingeloggt ist.
                return;
              }

              if (value == 'editMarker') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditMarkerPage(),
                  ),
                );
              } else if (value == 'findFriends') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchFriendsPage(),
                  ),
                );
              } else if (value == 'logout') {
                await authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'userInfo',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'User: ${authService.currentUser?.username ?? 'N/A'}, ID: ${authService.currentUser?.id ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'editMarker',
                  child: Text('Edit Marker'),
                ),
                const PopupMenuItem<String>(
                  value: 'findFriends',
                  child: Text('Find Friends'),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<MapService>(
            builder: (context, mapService, child) {
              final colorService = Provider.of<ColorService>(context, listen: false);
              final List<Marker> markers = mapService.markers.map((markerData) {
                return Marker(
                  point: LatLng(markerData.latitude, markerData.longitude),
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.location_pin,
                    color: colorService.getColorForUser(markerData.userId),
                  ),
                );
              }).toList();

              return FlutterMap(
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
                    userAgentPackageName: 'com.travelIt.app',
                  ),
                  MarkerLayer(
                    markers: [...markers, ..._currentMarker],
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchTextController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        try {
                          final suggestions = await geoService.getAutoComplete(value);
                          setState(() {
                            _suggestions = suggestions;
                          });
                        } catch (e) {
                          print("Fehler beim Abrufen der Vorschläge: $e");
                        }
                      }
                    },
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_suggestions[index]),
                            onTap: () async {
                              try {
                                final coordinates = await geoService.getCoordinates(_suggestions[index]);
                                _mapController.move(coordinates, 17.0);
                                setState(() {
                                  _suggestions.clear();
                                  _searchTextController.clear();
                                });
                              } catch (e) {
                                print("Fehler beim Abrufen der Koordinaten: $e");
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentMarker.isNotEmpty) {
                        await _showSaveDialog(context);
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
          ),
          Positioned(
            right: 16,
            top: 100,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPanelVisible = !_isPanelVisible;
                });
              },
              child: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.person_pin_circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: _isPanelVisible ? 0 : -MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Column(
                children: [
                  AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _isPanelVisible = false;
                        });
                      },
                    ),
                    title: const Text('Marker Details'),
                  ),
                  Expanded(
                    child: Consumer<MapService>(
                      builder: (context, mapService, child) {
                        return ListView.builder(
                          itemCount: mapService.markers.length,
                          itemBuilder: (context, index) {
                            final marker = mapService.markers[index];
                            final color = Provider.of<ColorService>(context, listen: false).getColorForUser(marker.userId);
                            return ListTile(
                              title: Text("${marker.title} von ${marker.username}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Description: ${marker.description}"),
                                  Text("Ranking: ${marker.ranking}"),
                                  Text("Lat: ${marker.latitude}, Lng: ${marker.longitude}"),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: color,
                              ),
                              onTap: () async {
                                final cityName = await geoService.getCountyName(marker.latitude, marker.longitude);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationDetailPage(
                                      latitude: marker.latitude,
                                      longitude: marker.longitude,
                                      cityName: cityName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    String title = '';
    String description = '';
    double ranking = 0.0;

    final mapService = Provider.of<MapService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Marker Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (value) => title = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (value) => description = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Ranking [0.0-10.0]'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => ranking = double.tryParse(value) ?? 0.0,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (title.isEmpty || ranking < 0.0 || ranking > 10.0) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Invalid Input'),
                          content: const Text('Please provide a title and a valid ranking.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    await mapService.saveMarker(
                      point: _currentMarker.first.point,
                      title: title,
                      description: description,
                      ranking: ranking,
                      userId: authService.currentUser!.id,
                    );
                    setState(() {
                      _currentMarker.clear();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}