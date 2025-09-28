import 'package:flutter/material.dart';

class ColorService {
  final List<Color> _userColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
  ];

  Color getColorForUser(int userId) {
    // Einfache Logik, um eine Farbe basierend auf der user-ID zu vergeben
    return _userColors[userId % _userColors.length];
  }
}