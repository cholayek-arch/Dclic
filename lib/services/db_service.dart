import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import 'storage.dart';



class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncClients(List<Client> clients) async {
    try{final batch = _firestore.batch();
    for (var c in clients) {
      final docRef = _firestore.collection('clients').doc(c.id.toString());
      batch.set(docRef, {
        'name': c.name,
        'gender': c.gender,
        'measurements': c.measurements,
        'photos': c.photos,
        'createdAt': Timestamp.fromDate(c.createdAt),
      });
    }
    await batch.commit();
  } catch (e) {
    print('Error syncing clients to Firestore: $e');
  }
}}


class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'delux.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            gender TEXT,
            measurements TEXT,
            photos TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Migrate clients from SharedPreferences storage if DB is empty.
  Future<void> migrateFromStorage(StorageService storage) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM clients'));
    if (count != null && count > 0) return;
    final old = await storage.loadClients();
    for (var c in old) {
      await insertClient(c);
    }
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final rows = await db.query('clients', orderBy: 'createdAt DESC');
    return rows.map((r) {
      final measurementsJson = r['measurements'] as String?;
      final measurements = measurementsJson != null && measurementsJson.isNotEmpty
          ? (jsonDecode(measurementsJson) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()))
          : <String, double>{};
      final photosJson = r['photos'] as String?;
      final photos = photosJson != null && photosJson.isNotEmpty
          ? List<String>.from(jsonDecode(photosJson) as List)
          : <String>[];
      return Client(
        id: r['id'] as int,
        name: r['name'] as String,
        gender: r['gender'] as String? ?? 'male',
        measurements: measurements,
        photos: photos,
        createdAt: DateTime.parse(r['createdAt'] as String),
      );
    }).toList();
  }

  Future<void> insertClient(Client c) async {
    final db = await database;
    await db.insert(
      'clients',
      {
        
        'name': c.name,
        'gender': c.gender,
        'measurements': jsonEncode(c.measurements),
        'photos': jsonEncode(c.photos),
        'createdAt': c.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateClient(Client c) async {
    final db = await database;
    await db.update(
      'clients',
      {
        'name': c.name,
        'gender': c.gender,
        'measurements': jsonEncode(c.measurements),
        'photos': jsonEncode(c.photos),
        'createdAt': c.createdAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }
}
