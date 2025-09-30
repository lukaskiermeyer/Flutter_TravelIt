// lib/screens/HomeScreen.dart
import 'dart:collection';
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
import 'package:zapp/utils/app_theme.dart';

import 'LoginPage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchTextController = TextEditingController();
  Marker? _temporaryMarker;
  bool _isPanelVisible = false;
  List<String> _suggestions = [];

  // State für den Filter
  Set<int> _selectedUserIds = {};
  LinkedHashMap<int, String> _uniqueUsersOnMap = LinkedHashMap();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final mapService = Provider.of<MapService>(context, listen: false);
      if (authService.currentUser != null) {
        mapService.loadInitialData(authService.currentUser!.id);
      }
    });
  }


  void _updateFilterState(MapService mapService) {
    final newUniqueUsers = LinkedHashMap<int, String>();
    for (var marker in mapService.markers) {
      newUniqueUsers[marker.userId] = marker.username ?? 'Unknown';
    }

    if (newUniqueUsers.keys.toSet().difference(_uniqueUsersOnMap.keys.toSet()).isNotEmpty ||
        _uniqueUsersOnMap.keys.toSet().difference(newUniqueUsers.keys.toSet()).isNotEmpty) {
      setState(() {
        _uniqueUsersOnMap = newUniqueUsers;
        _selectedUserIds = _uniqueUsersOnMap.keys.toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final geoService = Provider.of<GeoService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final mapService = Provider.of<MapService>(context);

    _updateFilterState(mapService);

    final filteredMarkers = mapService.markers
        .where((m) => _selectedUserIds.contains(m.userId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.map_outlined, size: 24),
            const SizedBox(width: 8),
            if (mapService.maps.isNotEmpty)
              DropdownButton<MapModel>(
                value: mapService.selectedMap,
                dropdownColor: AppTheme.primaryColor,
                iconEnabledColor: Colors.white,
                style: Theme.of(context).textTheme.labelLarge,
                underline: Container(),
                items: mapService.maps.map((map) {
                  return DropdownMenuItem<MapModel>(
                    value: map,
                    child: Text(map.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    Provider.of<MapService>(context, listen: false).selectMapAndLoadMarkers(value);
                  }
                },
              )
            else
              const Text("Keine Karten"),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              if (value == 'editMarker') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditMarkerPage()));
              } else if (value == 'findFriends') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchFriendsPage()));
              } else if (value == 'logout') {
                await authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'User: ${authService.currentUser?.username ?? 'N/A'} (ID: ${authService.currentUser?.id ?? 'N/A'})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'editMarker', child: Text('Edit Marker')),
              const PopupMenuItem<String>(value: 'findFriends', child: Text('Find Friends')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<ColorService>(
            builder: (context, colorService, child) {
              final List<Marker> markersToDisplay = filteredMarkers.map((markerData) {
                return Marker(
                  point: LatLng(markerData.latitude, markerData.longitude),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_pin,
                    color: colorService.getColorForUser(markerData.userId),
                    size: 40,
                  ),
                );
              }).toList();

              if (_temporaryMarker != null) {
                markersToDisplay.add(_temporaryMarker!);
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(51.509364, -0.128928),
                  initialZoom: 4,
                  onTap: (_, latLng) {
                    setState(() {
                      _temporaryMarker = Marker(
                        point: latLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.add_location_alt_outlined,
                          color: AppTheme.primaryColor,
                          size: 40,
                        ),
                      );
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.travelIt.app',
                  ),
                  MarkerLayer(markers: markersToDisplay),
                ],
              );
            },
          ),
          _buildSearchUI(geoService),
          _buildDetailsPanel(geoService, filteredMarkers),
          _buildPanelToggleButton(),
        ],
      ),
      floatingActionButton: _temporaryMarker != null
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'cancel_fab',
            onPressed: () => setState(() => _temporaryMarker = null),
            label: const Text('Cancel'),
            icon: const Icon(Icons.close),
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'save_fab',
            onPressed: () => _showSaveDialog(context),
            label: const Text('Save'),
            icon: const Icon(Icons.check),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildUserFilter(ColorService colorService) {
    if (_uniqueUsersOnMap.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: _uniqueUsersOnMap.length,
        itemBuilder: (context, index) {
          final userId = _uniqueUsersOnMap.keys.elementAt(index);
          final username = _uniqueUsersOnMap.values.elementAt(index);
          final color = colorService.getColorForUser(userId);
          final isSelected = _selectedUserIds.contains(userId);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedUserIds.remove(userId);
                } else {
                  _selectedUserIds.add(userId);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppTheme.primaryColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 8, backgroundColor: color),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsPanel(GeoService geoService, List<MarkerData> displayedMarkers) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: _isPanelVisible ? 0 : -MediaQuery.of(context).size.width,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Material(
        elevation: 8,
        child: Consumer<ColorService>(
          builder: (context, colorService, child) {
            return Column(
              children: [
                AppBar(
                  backgroundColor: AppTheme.primaryColor,
                  title: const Text('Marker Details'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _isPanelVisible = false),
                  ),
                ),
                _buildUserFilter(colorService),
                Expanded(
                  child: displayedMarkers.isEmpty
                      ? const Center(child: Text("No matching markers found."))
                      : ListView.builder(
                    itemCount: displayedMarkers.length,
                    itemBuilder: (context, index) {
                      final marker = displayedMarkers[index];
                      final color = colorService.getColorForUser(marker.userId);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.pin_drop, color: Colors.white)),
                          title: Text(marker.title ?? 'No Title'),
                          subtitle: Text(marker.username ?? 'Unknown'),
                          trailing: Chip(
                            label: Text(marker.ranking!.toStringAsFixed(1)),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchUI(GeoService geoService) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: _searchTextController,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchTextController.clear();
                    setState(() { _suggestions = []; });
                  },
                ),
              ),
              onChanged: (value) async {
                if (value.length > 2) {
                  _suggestions = await geoService.getAutoComplete(value);
                  setState(() {});
                } else {
                  setState(() { _suggestions = []; });
                }
              },
            ),
          ),
          if (_suggestions.isNotEmpty)
            Material(
              elevation: 4,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                    onTap: () async {
                      final coordinates = await geoService.getCoordinates(_suggestions[index]);
                      _mapController.move(coordinates, 17.0);
                      setState(() {
                        _suggestions = [];
                        _searchTextController.clear();
                        FocusScope.of(context).unfocus();
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanelToggleButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 80,
      right: _isPanelVisible ? MediaQuery.of(context).size.width * 0.85 + 16 : 16,
      child: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => _isPanelVisible = !_isPanelVisible),
        child: Icon(_isPanelVisible ? Icons.arrow_forward_ios : Icons.pin_drop_outlined),
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    double ranking = 5.0;

    final mapService = Provider.of<MapService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Marker Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Ranking [0.0-10.0]'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: '5.0',
                  validator: (value) {
                    final num = double.tryParse(value ?? '');
                    if (num == null || num < 0.0 || num > 10.0) {
                      return 'Enter a number between 0 and 10';
                    }
                    return null;
                  },
                  onChanged: (value) => ranking = double.tryParse(value) ?? 5.0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (_temporaryMarker != null) {
                    await mapService.saveMarker(
                      point: _temporaryMarker!.point,
                      title: title,
                      description: description,
                      ranking: ranking,
                      userId: authService.currentUser!.id,
                    );
                    setState(() {
                      _temporaryMarker = null;
                    });
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}