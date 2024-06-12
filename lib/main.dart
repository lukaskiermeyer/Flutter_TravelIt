import 'package:flutter/material.dart';
import 'package:zapp/screens/LoginPage.dart';



void main() {
  runApp(const TravelitApp());
}

class TravelitApp extends StatelessWidget {
  const TravelitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

