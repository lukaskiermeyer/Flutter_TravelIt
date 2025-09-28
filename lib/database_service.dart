// lib/database_service.dart
import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  late Connection _connection;

  Future<void> connect() async {
    final String? neonDbUrl = dotenv.env['NEON_DB_URL'];
    if (neonDbUrl == null) {
      throw Exception("NEON_DB_URL not found in .env file");
    }

    final uri = Uri.parse(neonDbUrl);

    if (uri.userInfo.isEmpty) {
      throw Exception("Invalid NEON_DB_URL: missing user info");
    }

    _connection = await Connection.open(
      Endpoint(
        host: uri.host,
        database: uri.pathSegments.first,
        username: uri.userInfo.split(':')[0],
        password: uri.userInfo.split(':')[1],
        port: 5432,
      ),
      settings: ConnectionSettings(sslMode: SslMode.verifyFull),
    );

    // Nach dem erfolgreichen Verbindungsaufbau die Tabellen erstellen
    await _ensureTablesExist();
  }

  // Neue Methode zur Tabellenerstellung
  Future<void> _ensureTablesExist() async {
    print('Prüfe und erstelle Datenbanktabellen...');
    try {
      await _connection.execute(
        // Benutzer-Tabelle
          "CREATE TABLE IF NOT EXISTS travelit_users ( "
              "id SERIAL PRIMARY KEY, "
              "username VARCHAR(50) NOT NULL UNIQUE, "
              "email VARCHAR(100) NOT NULL UNIQUE, "
              "password VARCHAR(255) NOT NULL, "
              "created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()"
              ");"
      );

      await _connection.execute(
        // Marker-Tabelle
          "CREATE TABLE IF NOT EXISTS markers ( "
              "id SERIAL PRIMARY KEY, "
              "latitude DOUBLE PRECISION NOT NULL, "
              "longitude DOUBLE PRECISION NOT NULL, "
              "userId INT NOT NULL, "
              "title VARCHAR(255), "
              "description TEXT, "
              "ranking DOUBLE PRECISION, "
              "created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()"
              ");"
      );

      await _connection.execute(
        // Map-Tabelle
          "CREATE TABLE IF NOT EXISTS travelit_maps ( "
              "id SERIAL PRIMARY KEY, "
              "title VARCHAR(255) NOT NULL, "
              "created_by INT NOT NULL, "
              "created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()"
              ");"
      );

      await _connection.execute(
        // Map-User-Verbindungstabelle
          "CREATE TABLE IF NOT EXISTS travelit_mapusers ( "
              "id SERIAL PRIMARY KEY, "
              "map_id INT NOT NULL, "
              "user_id INT NOT NULL, "
              "invited_by INT NOT NULL, "
              "created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()"
              ");"
      );

      print('Tabellen erfolgreich erstellt oder existieren bereits.');
    } catch (e) {
      print('Fehler beim Erstellen der Tabellen: $e');
      rethrow;
    }
  }

  // Korrigierte execute-Methode, die jetzt Sql-Objekte verarbeitet
  Future<Result> execute(dynamic sql,
      [Map<String, dynamic> params = const {}]) async {
    try {
      final Result result;
      if (sql is String) {
        result = await _connection.execute(Sql(sql), parameters: params);
      } else if (sql is Sql) {
        result = await _connection.execute(sql, parameters: params);
      } else {
        throw ArgumentError('Invalid SQL argument type. Must be String or Sql.');
      }
      return result;
    } catch (e) {
      print('Allgemeiner Datenbank-Fehler: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    await _connection.close();
  }
}