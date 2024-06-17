import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class UserResult {
  final String username;
  final int userId;

  UserResult({required this.username, required this.userId});
}

class MapResult {
  final int mapId;
  final String mapTitle;

  MapResult({required this.mapId, required this.mapTitle});
}

class SearchfriendsPage extends StatefulWidget {
  final String username;
  final int userId;

  const SearchfriendsPage({super.key, required this.username, required this.userId});

  @override
  _SearchfriendsPage createState() => _SearchfriendsPage();
}

class _SearchfriendsPage extends State<SearchfriendsPage> {
  late MySqlConnection _conn;
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _mapNameController = TextEditingController();
  List<UserResult> _searchResults = [];
  String? _selectedUsername;
  String? _mapName;
  int? _selectedUserId;
  List<MapResult> _mapResults = [];
  UserResult? _selectedUserResult;
  MapResult? _selectedMapResult;

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
  }

  Future<void> _addMapWithUser(String mapname, int userid) async {
    // Check if the map title already exists for the user
    final existingMap = await _conn.query(
      'SELECT id FROM travelit_maps WHERE title = ? AND created_by = ?',
      [mapname, widget.userId],
    );

    if (existingMap.isNotEmpty) {
      //alert that user is already in a map with this name
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a map with this name'),
        ),
      );

    } else {
      // Create a new map
      _conn.query(
        'INSERT INTO travelit_maps (title, created_by) VALUES (?, ?)',
        [mapname, widget.userId],
      );
      final mapId = await _conn.query('SELECT id FROM travelit_maps WHERE title = ? AND created_by = ?', [mapname, widget.userId]);
      final mapIdValue = mapId.first.fields['id'];

      await _conn.query(
        'INSERT INTO travelit_mapusers (map_id, user_id, invited_by) VALUES (?, ?, ?)',
        [mapIdValue, widget.userId, widget.userId],
      );
      await _conn.query(
        'INSERT INTO travelit_mapusers (map_id, user_id, invited_by) VALUES (?, ?, ?)',
        [mapIdValue, _selectedUserId, widget.userId],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map created successfully'),
        ),
      );
    }
  }

  Future<List<UserResult>> _searchForUser(String query) async {
    final results = await _conn.query('SELECT id, username FROM travelit_users WHERE id LIKE ?', ['%$query%']);
    List<UserResult> userResults = [];

    if (results.isNotEmpty) {
      for (var row in results) {
        String username = row.fields['username'];
        int userId = row.fields['id'];
        UserResult userResult = UserResult(username: username, userId: userId);
        userResults.add(userResult);
      }
    }
    return userResults;
  }

  Future<List<MapResult>> _getMapsForUser(int userId) async {
    final results = await _conn.query('SELECT DISTINCT tm.id, tm.title  FROM travelit_maps tm LEFT JOIN travelit_mapusers mu ON tm.id = mu.map_id WHERE tm.id NOT IN (SELECT map_id FROM travelit_mapusers WHERE user_id = ?) AND created_by = ? OR mu.user_id = ?;', [userId, widget.userId, widget.userId]);
    List<MapResult> mapResults = [];
    if (results.isNotEmpty) {
      for (var row in results) {
        int mapId = row.fields['id'];
        String mapTitle = row.fields['title'];
        MapResult mapResult = MapResult(mapId: mapId, mapTitle: mapTitle);
        mapResults.add(mapResult);
      }
    }
    return mapResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Friends')
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Your ID: ${widget.userId}'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search for Userid',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a userid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _selectedUsername = null;
                    _selectedUserId = null;
                    _selectedUserResult = null;
                    _searchResults = await _searchForUser(_searchController.text);
                    setState(() {
                    });
                  }
                },
                child: const Text('Search'),
              ),
              const SizedBox(height: 16),
              if (_searchResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select User"),
                    DropdownButton<UserResult>(
                      value: _selectedUserResult,
                      items: _searchResults.map((result) {
                        return DropdownMenuItem<UserResult>(
                          value: result,
                          child: Text(result.username),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        _selectedUserResult = value;
                        _mapResults = await _getMapsForUser(value!.userId);
                        setState(() {
                          if (value.userId != widget.userId) {
                            _selectedUsername = value.username;
                            _selectedUserId = value.userId;
                          } else {
                            _selectedUsername = null;
                            _selectedUserId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedUsername != null)
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              _mapName = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Create a new map'),
                                    content: TextFormField(
                                      controller: _mapNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Map name',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                           _mapName = _mapNameController.text;
                                          _addMapWithUser(_mapName!, _selectedUserId!);
                                          Navigator.pop(context);
                                          _searchController.clear();
                                          _mapNameController.clear();
                                          _searchResults = [];
                                          setState(() {});

                                        },
                                        child: const Text('Create'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text('Invite User to new Map'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: (){ //TODO Add to check if map is selected, then add user to map
                                          if(_selectedMapResult != null){
                                          _conn.query('INSERT INTO travelit_mapusers (map_id, user_id, invited_by) VALUES (?, ?, ?)', [_mapResults[0].mapId, _selectedUserId, widget.userId]);
                                          setState(() {
                                          _searchController.clear();
                                          _mapNameController.clear();
                                          _searchResults = [];
                                          _mapResults = [];
                                          _selectedMapResult = null;
                                          _selectedUsername = null;
                                          _selectedUserId = null;
                                          _selectedUserResult = null;
                                          });
                                          }
                                          else{
                                          //alert "SELECT MAP"
                                          ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select a map'), ), );
                                          }
                                          },
                            child: const Text('Invite User to existing Map'),
                          ),
                          const SizedBox(height: 16),
                          if (_mapResults.isNotEmpty)
                            DropdownButton(
                              value: _selectedMapResult,
                              items: _mapResults.map((result) {
                                return DropdownMenuItem<MapResult>(
                                  value: result,
                                  child: Text(result.mapTitle),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMapResult = value;
                                });
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              if (_searchResults.isEmpty)
                const Text('No results found'),
            ],
          ),
        ),
      ),
    );
  }
}

