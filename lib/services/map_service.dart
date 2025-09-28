import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:postgres/postgres.dart';
import 'package:zapp/database_service.dart';
import 'package:zapp/models/map_model.dart';
import 'package:zapp/models/marker_data_model.dart';

class MapService extends ChangeNotifier {
  final DatabaseService _databaseService;
  MapService(this._databaseService);

  final List<MapModel> _maps = [];
  MapModel? _selectedMap;
  final List<MarkerData> _markers = [];

  List<MapModel> get maps => _maps;
  MapModel? get selectedMap => _selectedMap;
  List<MarkerData> get markers => _markers;


  Future<void> loadInitialData(int userId) async {
    await _loadMaps(userId);
    if (_selectedMap != null) {
      await _loadMarkersForSelectedMap(_selectedMap!.userIds);
    }
  }

  Future<void> selectMapAndLoadMarkers(MapModel newMap) async {
    if (_selectedMap != newMap) {
      _selectedMap = newMap;
      await _loadMarkersForSelectedMap(newMap.userIds);
      notifyListeners();
    }
  }
  Future<List<MarkerData>> loadUserMarkers(int userId) async {
    try {
      final results = await _databaseService.execute(
        Sql.named("SELECT m.id, m.latitude, m.longitude, m.title, m.description, m.ranking, tu.username FROM markers m JOIN travelit_users tu ON tu.id = m.userId WHERE m.userId = @userId"),
        {"userId": userId},
      );
      return results.map((row) {
        final rowMap = row.toColumnMap();
        return MarkerData(
          id: rowMap['id'] as int,
          latitude: rowMap['latitude'] as double,
          longitude: rowMap['longitude'] as double,
          title: rowMap['title'] as String?,
          description: rowMap['description'] as String?,
          ranking: rowMap['ranking']?.toDouble(),
          username: rowMap['username'] as String,
          userId: userId,
        );
      }).toList();
    } catch (e) {
      print("Error loading user markers: $e");
      return [];
    }
  }

  Future<void> _loadMaps(int userId) async {
    _maps.clear();

    final myMap = MapModel(id: userId, name: 'Meine Map', userIds: [userId]);
    _maps.add(myMap);

    try {
      final results = await _databaseService.execute(
        Sql.named('SELECT DISTINCT tm.id, tm.title FROM travelit_maps tm JOIN travelit_mapusers mu ON tm.id = mu.map_id WHERE mu.user_id = @userId;'),
        {'userId': userId},
      );

      for (final row in results) {
        final rowMap = row.toColumnMap();
        final mapId = rowMap['id'] as int;
        final mapTitle = rowMap['title'] as String;

        final userIdsResult = await _databaseService.execute(
          Sql.named('SELECT user_id FROM travelit_mapusers WHERE map_id = @mapId;'),
          {'mapId': mapId},
        );
        final userIds = userIdsResult.map((row) => row.toColumnMap()['user_id'] as int).toList();

        final map = MapModel(id: mapId, name: mapTitle, userIds: userIds);

        // Füge nur Maps hinzu, die nicht "Meine Map" sind
        if (map.name != 'Meine Map') {
          _maps.add(map);
        }
      }

      // Wählt das erste Element als Standard-Map
      if (_maps.isNotEmpty) {
        _selectedMap = _maps.first;
      } else {
        _selectedMap = null;
      }
    } catch (e) {
      print("Fehler beim Laden der Maps: $e");
    }

    notifyListeners();
  }

  Future<void> _loadMarkersForSelectedMap(List<int> userIdsToLoad) async {
    _markers.clear();
    for (final userId in userIdsToLoad) {
      final userMarkers = await _loadUserMarkers(userId);
      _markers.addAll(userMarkers);
    }
    notifyListeners();
  }

  Future<List<MarkerData>> _loadUserMarkers(int userId) async {
    try {
      final results = await _databaseService.execute(
        Sql.named("SELECT m.id, m.latitude, m.longitude, m.title, m.description, m.ranking, tu.username FROM markers m JOIN travelit_users tu ON tu.id = m.userId WHERE m.userId = @userId"),
        {"userId": userId},
      );
      return results.map((row) {
        final rowMap = row.toColumnMap();
        return MarkerData(
          id: rowMap['id'] as int,
          latitude: rowMap['latitude'] as double,
          longitude: rowMap['longitude'] as double,
          title: rowMap['title'] as String?,
          description: rowMap['description'] as String?,
          ranking: rowMap['ranking']?.toDouble(),
          username: rowMap['username'] as String,
          userId: userId,
        );
      }).toList();
    } catch (e) {
      print("Error loading user markers: $e");
      return [];
    }
  }

  Future<void> saveMarker({
    required LatLng point,
    required String title,
    required String description,
    required double ranking,
    required int userId,
  }) async {
    try {
      await _databaseService.execute(Sql.named(
          'INSERT INTO markers (latitude, longitude, userid, title, description, ranking) VALUES (@lat, @long, @userId, @title, @desc, @ranking)'),
        {
          'lat': point.latitude,
          'long': point.longitude,
          'userId': userId,
          'title': title,
          'desc': description,
          'ranking': ranking,
        },
      );
    } catch (e) {
      print("Error saving marker: $e");
    }

    // Die Marker der aktuell ausgewählten Map neu laden
    if (_selectedMap != null) {
      await _loadMarkersForSelectedMap(_selectedMap!.userIds);
    }
  }

  Future<void> updateMarker({
    required int markerId,
    required String title,
    required String description,
    required double ranking,
  }) async {
    try {
      await _databaseService.execute(Sql.named(
          'UPDATE markers SET title = @title, description = @desc, ranking = @ranking WHERE id = @markerId'),
        {
          'title': title,
          'desc': description,
          'ranking': ranking,
          'markerId': markerId,
        },
      );
    } catch (e) {
      print("Error updating marker: $e");
    }

    // Die Marker der aktuell ausgewählten Map neu laden
    if (_selectedMap != null) {
      await _loadMarkersForSelectedMap(_selectedMap!.userIds);
    }
  }

  Future<void> deleteMarker(int markerId) async {
    try {
      await _databaseService.execute(Sql.named(
          'DELETE FROM markers WHERE id = @markerId'),
        {'markerId': markerId},
      );
    } catch (e) {
      print("Error deleting marker: $e");
    }

    // Die Marker der aktuell ausgewählten Map neu laden
    if (_selectedMap != null) {
      await _loadMarkersForSelectedMap(_selectedMap!.userIds);
    }
  }
}