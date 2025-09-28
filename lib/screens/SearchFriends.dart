// lib/screens/SearchFriends.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapp/services/friend_service.dart';
import 'package:zapp/services/auth_service.dart';

class SearchFriendsPage extends StatefulWidget {
  const SearchFriendsPage({super.key});

  @override
  _SearchFriendsPageState createState() => _SearchFriendsPageState();
}

class _SearchFriendsPageState extends State<SearchFriendsPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _mapNameController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _mapResults = [];
  Map<String, dynamic>? _selectedUserResult;
  Map<String, dynamic>? _selectedMapResult;

  @override
  Widget build(BuildContext context) {
    final friendService = Provider.of<FriendService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Your ID: $currentUserId'),
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
                    final userIdToSearch = int.tryParse(_searchController.text);
                    if (userIdToSearch != null) {
                      _searchResults = await friendService.searchForUser(userIdToSearch);
                      setState(() {
                        _selectedUserResult = _searchResults.isNotEmpty ? _searchResults.first : null;
                        _mapResults = [];
                        _selectedMapResult = null;
                      });
                    }
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
                    DropdownButton<Map<String, dynamic>>(
                      value: _selectedUserResult,
                      items: _searchResults.map((result) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: result,
                          child: Text(result['username']),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        _selectedUserResult = value;
                        if (value != null) {
                          _mapResults = await friendService.getMapsForUser(currentUserId);
                        } else {
                          _mapResults = [];
                        }
                        setState(() {
                          _selectedMapResult = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedUserResult != null && _selectedUserResult!['id'] != currentUserId)
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final mapName = await _showCreateMapDialog(context);
                              if (mapName != null) {
                                final success = await friendService.addMapWithUser(
                                    mapName, _selectedUserResult!['id'], currentUserId);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Map created and user invited successfully!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to create map or map name exists.')),
                                  );
                                }
                                setState(() {
                                  _searchResults = [];
                                  _mapResults = [];
                                  _selectedUserResult = null;
                                  _searchController.clear();
                                });
                              }
                            },
                            child: const Text('Invite User to new Map'),
                          ),
                          const SizedBox(height: 8),
                          if (_mapResults.isNotEmpty)
                            ElevatedButton(
                              onPressed: () async {
                                if (_selectedMapResult != null) {
                                  final success = await friendService.addUserToExistingMap(
                                      _selectedMapResult!['id'], _selectedUserResult!['id'], currentUserId);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('User added to map successfully!')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to add user to map.')),
                                    );
                                  }
                                  setState(() {
                                    _searchResults = [];
                                    _mapResults = [];
                                    _selectedUserResult = null;
                                    _selectedMapResult = null;
                                    _searchController.clear();
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a map')),
                                  );
                                }
                              },
                              child: const Text('Invite User to existing Map'),
                            ),
                          const SizedBox(height: 16),
                          if (_mapResults.isNotEmpty)
                            DropdownButton<Map<String, dynamic>>(
                              value: _selectedMapResult,
                              items: _mapResults.map((result) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: result,
                                  child: Text(result['title']),
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
              if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                const Text('No results found'),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showCreateMapDialog(BuildContext context) async {
    return showDialog<String>(
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final mapName = _mapNameController.text;
                Navigator.pop(context, mapName);
                _mapNameController.clear();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}