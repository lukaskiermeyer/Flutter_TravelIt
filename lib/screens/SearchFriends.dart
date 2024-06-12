import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

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
  List<String> _searchResults = [];
  String? _selectedUsername;

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

  Future<List<String>> _searchForUser(String query) async {
    final results = await _conn.query('SELECT username FROM travelit_users WHERE id = ?', [query]);
    return results.map((row) => row.fields['username'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Bar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search for User ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _searchController.text = _searchController.text.trim();
                    _searchController.text = _searchController.text.toLowerCase();
                    _searchResults = await _searchForUser(_searchController.text);
                    _showSearchResults();
                  }
                },
                child: Text('Search'),
              ),
              SizedBox(height: 16),
              _searchResults.isEmpty
                  ? Text('No results found')
                  : DropdownButton<String>(
                value: _searchResults.isEmpty ? null : _searchResults[0],
                items: _searchResults.map((result) {
                  return DropdownMenuItem<String>(
                    value: result,
                    child: Text(result),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUsername = value;
                  });
                },
              ),
              SizedBox(height: 16),
              if (_selectedUsername != null)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Invite user to new map
                      },
                      child: Text('Invite User to new Map'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Invite user to existing map
                      },
                      child: Text('Invite User to existing Map'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchResults() {
    setState(() {
      if (_searchResults.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _searchResults;
      }
    });
  }
}