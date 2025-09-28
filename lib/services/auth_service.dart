// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:zapp/database_service.dart';
import 'package:zapp/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final DatabaseService _databaseService;

  AuthService(this._databaseService);
  bool _isLoggedIn = false;
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;


  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      final Result result = await _databaseService.execute(
        // Korrigierte SQL-Abfrage mit Sql.named
        Sql.named("SELECT id, username, email FROM travelit_users WHERE (username = @usernameOrEmail OR email = @usernameOrEmail) AND password = @password"),
        {
          "usernameOrEmail": usernameOrEmail,
          "password": password,
        },
      );

      if (result.isNotEmpty) {
        final ResultRow row = result.first;
        _currentUser = User(
          id: row[0] as int,
          username: row[1] as String,
          email: row[2] as String,
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Allgemeiner Fehler: $e");
    }
    return false;
  }

  Future<bool> register(String email, String username, String password) async {
    try {
      final existingUser = await _databaseService.execute(
        Sql.named("SELECT id FROM travelit_users WHERE email = @email OR username = @username"),
        {"email": email, "username": username},
      );
      if (existingUser.isNotEmpty) {
        return false;
      }

      await _databaseService.execute(
        Sql.named("INSERT INTO travelit_users (email, username, password) VALUES (@email, @username, @password)"),
        {"email": email, "username": username, "password": password},
      );

      return true;
    }catch (e) {
      print("Allgemeiner Fehler: $e");
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}