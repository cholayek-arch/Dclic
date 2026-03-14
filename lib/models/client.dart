import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final int id;
  String name;
  String gender; 
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
      'measurements': measurements,
      'photos': photos,
      'createdAt': createdAt,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    final rawMeasurements = map['measurements'] as Map?;
    final rawPhotos = map['photos'] as List?;

    DateTime created;

    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else {
      created = DateTime.parse(map['createdAt']);
    }

    return Client(
      id: map['id'] as int,
      name: map['name'] as String,
      gender: map['gender'] as String? ?? 'male',
      measurements: rawMeasurements != null
          ? rawMeasurements.map(
              (k, v) => MapEntry(k as String, (v as num).toDouble()),
            )
          : {},
      photos: rawPhotos != null
          ? List<String>.from(rawPhotos.map((e) => e.toString()))
          : [],
      createdAt: created,
    );
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) =>
      Client.fromMap(json.decode(source));
}
