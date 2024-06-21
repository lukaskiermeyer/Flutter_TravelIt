import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mysql1/mysql1.dart';
import 'EditMarkerPage.dart';
import 'SearchFriends.dart';

class MyHomePage extends StatefulWidget {
  final String username;
  final int userid;

   const MyHomePage({super.key, required this.username, required this.userid});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _userColorsClass {
  late final String username;
  late final Color color;
  _userColorsClass({required this.username, required this.color});
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



class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<Marker> _currentMarker = [];
  late MySqlConnection _conn;
  late final List<_map> _maps = [_map(id:0, name:'Meine Map')];
  late final List<_userColorsClass> _userColorsList = [];
  late _map _selectedMap;

  List<Color> _userColors = [
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

  Future<String> _getUsername(var id) async{
    final results = await _conn.query('SELECT username FROM travelit_users WHERE id = ?', [id]);
    return results.first[0];
  }

  Future<void> _loadMarkersFromDatabase() async {
    _markers.clear();
    _userColorsList.clear();

    for (var i = 0; i < _selectedMap.users.length; i++) {
      //TODO: change color of marker depending on user
      String username = await _getUsername(_selectedMap.users[i]);
      _userColorsList.add(_userColorsClass(username: username, color: _userColors[i]));

      final results = await _conn.query(
          'SELECT * FROM markers WHERE userid = ?', [_selectedMap.users[i]]);

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
      }
    }

    setState(() {});
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

  Future<void> _saveMarkerToDatabase() async {
    if (_currentMarker.isNotEmpty) {
      await _conn.query(
        'INSERT INTO markers (latitude, longitude, userid) VALUES (?, ?, ?)',
        [_currentMarker[0].point.latitude, _currentMarker[0].point.longitude, widget.userid],
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
              }
              else if (value == 'Find Friends') {
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
                ),),),),
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
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 120,
                    height: 180,
                    color: Colors.white.withOpacity(0.5),
                    child: ListView.builder(
                      itemCount: _userColors.length,
                      itemBuilder: (context, index) {
                        final username = _userColorsList[index].username;
                        final color = _userColorsList[index].color;
                        return ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            color: color,
                          ),
                          title: Text('$username',
                              style: TextStyle(fontSize: 11),),
                        );
                      },
                    ),
                  ),
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


