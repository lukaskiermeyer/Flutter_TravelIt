import 'package:latlong2/latlong.dart';

class MarkerData {
  final int id;
  final double latitude;
  final double longitude;
  final String? title;
  final String? description;
  final double? ranking;
  final String username;
  final int userId;

  MarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.title,
    this.description,
    this.ranking,
    required this.username,
    required this.userId,
  });

  factory MarkerData.fromMap(Map<String, dynamic> map) {
    return MarkerData(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      title: map['title'],
      description: map['description'],
      ranking: map['ranking']?.toDouble(),
      username: map['username'],
      userId: map['userId'],
    );
  }
}