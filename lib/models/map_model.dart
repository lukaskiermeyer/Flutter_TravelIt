class MapModel {
  final int id;
  final String name;
  List<int> userIds;

  MapModel({required this.id, required this.name, this.userIds = const []});


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MapModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory MapModel.fromMap(Map<String, dynamic> map) {
    return MapModel(
      id: map['id'] as int,
      name: map['title'] as String,
    );
  }
}