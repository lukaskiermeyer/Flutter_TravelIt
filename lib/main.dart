// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:zapp/screens/LoginPage.dart';
import 'package:zapp/services/auth_service.dart';
import 'package:zapp/database_service.dart';
import 'package:zapp/services/color_service.dart';
import 'package:zapp/services/geo_service.dart';
import 'package:zapp/services/location_service.dart';
import 'package:zapp/services/map_service.dart';
import 'package:zapp/services/friend_service.dart';
import 'package:zapp/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Die Datenbankverbindung wird hier einmalig erstellt
  final databaseService = DatabaseService();

  // Starte die App mit einem Initialisierungs-Widget,
  // das auf die Datenbankverbindung wartet.
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(create: (_) => databaseService),
        ChangeNotifierProvider(create: (context) => AuthService(databaseService)),
        ChangeNotifierProvider(create: (context) => MapService(databaseService)),
        Provider(create: (context) => GeoService()),
        Provider(create: (context) => ColorService()),
        ChangeNotifierProvider(create: (context) => FriendService(databaseService)),
        Provider(create: (context) => LocationService()),
      ],
      child: const InitializationWrapper(),
    ),
  );
}

class TravelitApp extends StatelessWidget {
  const TravelitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelit',
      theme: AppTheme.lightTheme,
      home: LoginPage(),
    );
  }
}

class InitializationWrapper extends StatelessWidget {
  const InitializationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Rufe den DatabaseService ab, um seine connect-Methode zu verwenden
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    // FutureBuilder wartet auf das Ergebnis von databaseService.connect()
    return FutureBuilder(
      future: databaseService.connect(),
      builder: (context, snapshot) {
        // Während die Verbindung hergestellt wird, zeige einen Ladeindikator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Wenn ein Fehler auftritt, zeige eine Fehlermeldung
        if (snapshot.hasError) {
          print("Fehler beim Herstellen der Datenbankverbindung: ${snapshot.error}");
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Fehler: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        // Wenn alles erfolgreich ist, starte die eigentliche App
        return const TravelitApp();
      },
    );
  }
}