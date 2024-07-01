import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mysql1/mysql1.dart';
import 'EditMarkerPage.dart';
import 'SearchFriends.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  final String username;
  final int userid;

   const MyHomePage({super.key, required this.username, required this.userid});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _map {
  late final int id;
  late final String name;
  late List<int> users;

  _map({required this.id, required this.name});

  void setUsers(List<int> users) {
    this.users = users;
  }
}

class _userMarker{
  late final int id;
  late final String username;
  late final String? title;
  late final String? description;
  late final String? ranking;
  late final LatLng point;
  late final Color color;

  _userMarker({required this.id, required this.username, required this.title, required this.description, required this.ranking, required this.point, required this.color});

}



class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchTextController = TextEditingController();
  final List<Marker> _markers = [];
  final List<Marker> _currentMarker = [];
  final List<_userMarker> _userMarkers = [];
  late List<String> _suggestions = [];
  late MySqlConnection _conn;
  late final List<_map> _maps = [_map(id:0, name:'Meine Map')];
  late _map _selectedMap;
  static const String apiKey = "b95c8ec314774f969029f107534ead70";
  bool _isPanelVisible = false;

  final List<Color> _userColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
  ];


  @override
  void initState() {
    super.initState();
    _maps[0].setUsers([widget.userid]);
    _selectedMap = _maps[0];
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

    _fillMaps();
    _loadMarkersFromDatabase();

  }


  Future<void> _loadMarkersFromDatabase() async {
    _markers.clear();
    _userMarkers.clear();

    for (var i = 0; i < _selectedMap.users.length; i++) {
      final results = await _conn.query(
          'SELECT m.id, m.latitude, m.longitude, m.title, m.description, m.ranking, tu.username FROM markers m JOIN travelit_users tu ON tu.id = m.userId WHERE userid = ?;', [_selectedMap.users[i]]);
        for (var row in results) {
        _markers.add(
          Marker(
            point: LatLng(row[1], row[2]),
            width: 30,
            height: 30,
            child: Icon(
              Icons.location_pin,
              color: _userColors[i],
            ),
          ),
        );
        late String ranking;
        late String description;
        if (row[5] != null) {
          ranking = row[5].toStringAsFixed(1);
        }
        else {
          ranking = " ";
        }
        if (row[4] != null) {
          description = row[4].toString();
        }
        else {
          description = " ";
        }

        _userMarkers.add(
          _userMarker(
            id: row[0],
            point: LatLng(row[1], row[2]),
            title:  row[3] ?? '',
            description: description,
            ranking: ranking,
            username: row[6],
            color: _userColors[i],
          ),
        );
      }
    }

    setState(() {});
  }


  Future<LatLng> _getCoordinates(String city) async {
    final url = "https://api.geoapify.com/v1/geocode/search?text=$city&format=json&apiKey=$apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return LatLng(jsonData['results'][0]['lat'], jsonData['results'][0]['lon']);
    } else {
      throw Exception("Failed to get coordinates");
    }
  }

  Future<List<String>> _getAutoComplete(String city) async {
    final url = "https://api.geoapify.com/v1/geocode/autocomplete?text=$city&format=json&apiKey=$apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return List<String>.from(jsonData['results'].map((result) => result['formatted']));
    } else {
      throw Exception("Failed to get autocomplete suggestions");
    }
  }


  Future<void> _fillMaps() async {
    final results = await _conn.query('SELECT DISTINCT tu.map_id, tm.title FROM travelit_mapusers tu JOIN travelit_maps tm ON tu.map_id = tm.id WHERE user_id = ?;', [widget.userid]);
    for (var row in results) {
      final map = _map(
        id: row[0],
        name: row[1],
      );
      _maps.add(map);

    }

    for(var i = 1; i < _maps.length; i++) {

      final results = await _conn.query('SELECT user_id FROM travelit_mapusers WHERE map_id = ?', [_maps[i].id]);
      List<int> users = [];
      for (var row in results) {
        users.add(row[0]);
      }
      _maps[i].setUsers(users);
    }

    _selectedMap = _maps[0];
    setState(() {});
  }

  Future<void> _saveMarkerToDatabase({required String title, required String description, required double ranking}) async {
    if (_currentMarker.isNotEmpty) {
      await _conn.query(
        'INSERT INTO markers (latitude, longitude, userid, title, description, ranking) VALUES (?, ?, ?, ?, ?, ?)',
        [_currentMarker[0].point.latitude, _currentMarker[0].point.longitude, widget.userid, title, description, ranking],
      );
      _loadMarkersFromDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            DropdownButton<_map>(
              value: _selectedMap,
              items: _maps.map((map) {
                return DropdownMenuItem<_map>(
                  value: map,
                  child: Text(map.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMap = value!;
                  _loadMarkersFromDatabase();
                });
              },
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'Edit Marker') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMarkerPage(
                      username: widget.username,
                      userId: widget.userid,
                    ),
                  ),
                );
              } else if (value == 'Find Friends') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchfriendsPage(
                      username: widget.username,
                      userId: widget.userid,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'User Info',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'User: ${widget.username}, ID: ${widget.userid}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'Edit Marker',
                child: Text('Edit Marker'),
              ),
              const PopupMenuItem(
                value: 'Find Friends',
                child: Text('Find Friends'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
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
                        var suggestions = await _getAutoComplete(value);
                        setState(() {
                          _suggestions = suggestions;
                        });
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
                              LatLng coordinates = await _getCoordinates(_suggestions[index]);
                              _mapController.move(coordinates, 17.0);
                              setState(() {
                                _suggestions.clear();
                                _searchTextController.clear();
                              });
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
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            String title = '';
                            String description = '';
                            double ranking = 0.0;

                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('Enter Marker Details'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Title'),
                                        onChanged: (value) {
                                          title = value;
                                        },
                                      ),
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Description'),
                                        onChanged: (value) {
                                          description = value;
                                        },
                                      ),
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Ranking [0.0-10.0]'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          ranking = double.tryParse(value) ?? 0.0;
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Validierung der Eingaben
                                        if (title.isEmpty || description.isEmpty || ranking < 0.0 || ranking > 10.0) {
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Ungültige Eingabe'),
                                                content: const Text('Die eingegebene Zahl ist ungültig!'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          return; // Beende die Methode, wenn die Eingabe ungültig ist
                                        }

                                        await _saveMarkerToDatabase(
                                          title: title,
                                          description: description,
                                          ranking: ranking,
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
          // Sliding panel
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
                    child: ListView.builder(
                      itemCount: _userMarkers.length,
                      itemBuilder: (context, index) {
                        final marker = _userMarkers[index];
                        return ListTile(
                          title: Text("${marker.title} von ${marker.username}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Description: ${marker.description}"),
                              Text("Ranking: ${marker.ranking}"),
                              Text("Lat: ${marker.point.latitude}, Lng: ${marker.point.longitude}"),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: marker.color,
                          ),
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
}





