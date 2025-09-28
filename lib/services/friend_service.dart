import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:zapp/database_service.dart';


class FriendService extends ChangeNotifier {
  final DatabaseService _databaseService;
  FriendService(this._databaseService);

  Future<List<Map<String, dynamic>>> searchForUser(int userId) async {
    try {
      final results = await _databaseService.execute(
          Sql.named("SELECT id, username FROM travelit_users WHERE id = @userId"),
          {"userId": userId});
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      print("Error searching for user: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMapsForUser(int userId) async {
    try {
      final results = await _databaseService.execute(Sql.named(
          "SELECT DISTINCT tm.id, tm.title FROM travelit_maps tm JOIN travelit_mapusers mu ON tm.id = mu.map_id WHERE mu.user_id = @userId AND tm.created_by = @userId"),
          {"userId": userId});
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      print("Error getting maps for user: $e");
      return [];
    }
  }

  Future<bool> addMapWithUser(String mapName, int newUserId, int invitedByUserId) async {
    try {
      final existingMap = await _databaseService.execute(Sql.named(
          "SELECT id FROM travelit_maps WHERE title = @mapName AND created_by = @createdById"),
          {"mapName": mapName, "createdById": invitedByUserId});

      if (existingMap.isNotEmpty) {
        return false; // Map already exists
      }

      await _databaseService.execute(Sql.named(
          "INSERT INTO travelit_maps (title, created_by) VALUES (@mapName, @createdById)"),
          {"mapName": mapName, "createdById": invitedByUserId});

      final mapIdResult = await _databaseService.execute(Sql.named(
          "SELECT id FROM travelit_maps WHERE title = @mapName AND created_by = @createdById"),
          {"mapName": mapName, "createdById": invitedByUserId});
      final mapId = mapIdResult.first.toColumnMap()['id'];

      await _databaseService.execute(Sql.named(
          "INSERT INTO travelit_mapusers (map_id, user_id, invited_by) VALUES (@mapId, @currentUserId, @invitedById)"),
          {"mapId": mapId, "currentUserId": invitedByUserId, "invitedById": invitedByUserId});

      await _databaseService.execute(Sql.named(
          "INSERT INTO travelit_mapusers (map_id, user_id, invited_by) VALUES (@mapId, @newUserId, @invitedById)"),
          {"mapId": mapId, "newUserId": newUserId, "invitedById": invitedByUserId});

      return true;
    } catch (e) {
      print("Error adding map with user: $e");
      return false;
    }
  }
  Future<bool> addUserToExistingMap(int mapId, int newUserId, int invitedByUserId) async {
    try {
      // 1. Prüfen, ob der Benutzer bereits in der Map ist
      final existingUser = await _databaseService.execute(Sql.named(
        "SELECT map_id FROM travelit_mapusers WHERE map_id = @mapId AND user_id = @newUserId"),
        {
          "mapId": mapId,
          "newUserId": newUserId,
        },
      );

      if (existingUser.isNotEmpty) {
        // Benutzer ist bereits in der Map, also Fehler
        print("User is already in this map.");
        return false;
      }

      // 2. Benutzer zur Map hinzufügen
      await _databaseService.execute(Sql.named(
        "INSERT INTO travelit_mapusers (map_id, user_id, invited_by) VALUES (@mapId, @newUserId, @invitedByUserId)"),
        {
          "mapId": mapId,
          "newUserId": newUserId,
          "invitedByUserId": invitedByUserId,
        },
      );

      return true;
    } catch (e) {
      print("Error adding user to existing map: $e");
      return false;
    }
  }
}