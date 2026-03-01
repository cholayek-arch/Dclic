import 'dart:convert';

class Client {
  final int id;
  String name;
  String gender; // 'male' or 'female'
  Map<String, double> measurements;
  List<String> photos;
  DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    this.gender = 'male',
    Map<String, double>? measurements,
    List<String>? photos,
    DateTime? createdAt,
  })  : measurements = measurements ?? {},
        photos = photos ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'measurements': measurements.map((k, v) => MapEntry(k, v)),
      'photos': photos,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    final rawMeasurements = map['measurements'] as Map?;
    final rawPhotos = map['photos'] as List?;
    return Client(
      id: map['id'] as int,
      name: map['name'] as String,
      gender: map['gender'] as String? ?? 'male',
      measurements: rawMeasurements != null
          ? rawMeasurements.map((k, v) => MapEntry(k as String, (v as num).toDouble()))
          : {},
      photos: rawPhotos != null ? List<String>.from(rawPhotos.map((e) => e.toString())) : [],
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) => Client.fromMap(json.decode(source));
}
