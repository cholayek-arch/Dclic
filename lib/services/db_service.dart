import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/client.dart';
import 'storage.dart';
import 'dart:developer' as dev;

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Check if the user has a Premium subscription.
  Future<bool> isUserPremium(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['isPremium'] == true;
      }
      return false;
    } catch (e) {
      dev.log('Error checking premium status', error: e);
      return false;
    }
  }

  /// Mark a user as Premium in the database.
  Future<void> activatePremium(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'isPremium': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      dev.log('Premium activated for user $userId');
    } catch (e) {
      dev.log('Error activating premium', error: e);
      rethrow;
    }
  }

  /// Upload photos to Firebase Storage and return the updated photo list (URLs).
  Future<List<String>> _uploadPhotos(int clientId, List<String> localPaths) async {
    List<String> cloudUrls = [];
    for (var path in localPaths) {
      if (path.startsWith('http')) {
        cloudUrls.add(path); // Already a URL
        continue;
      }
      final file = File(path);
      if (!await file.exists()) continue;

      try {
        final ref = _storage.ref().child('clients/$clientId/${basename(path)}');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        cloudUrls.add(url);
      } catch (e) {
        dev.log('Error uploading photo $path', error: e);
      }
    }
    return cloudUrls;
  }

  /// Download photos from URLs to local storage.
  Future<List<String>> _downloadPhotos(int clientId, List<String> urls) async {
    List<String> localPaths = [];
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(appDir.path, 'client_photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    for (var url in urls) {
      if (!url.startsWith('http')) {
        localPaths.add(url); // Already a local path
        continue;
      }
      try {
        final filename = url.split('%2F').last.split('?').first;
        final localPath = join(photosDir.path, filename);
        final file = File(localPath);
        
        if (!await file.exists()) {
          final ref = _storage.refFromURL(url);
          await ref.writeToFile(file);
        }
        localPaths.add(localPath);
      } catch (e) {
        dev.log('Error downloading photo $url', error: e);
      }
    }
    return localPaths;
  }

  /// Push local clients to Firestore (Upload photos first).
  Future<void> pushSync(String userId, List<Client> clients) async {
    if (clients.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (var c in clients) {
        final cloudPhotos = await _uploadPhotos(c.id, c.photos);
        final docRef = _firestore.collection('clients').doc(c.id.toString());
        batch.set(docRef, {
          'userId': userId,
          'name': c.name,
          'gender': c.gender,
          'measurements': c.measurements,
          'photos': cloudPhotos,
          'createdAt': Timestamp.fromDate(c.createdAt),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      dev.log('Successfully pushed ${clients.length} clients to Firestore');
    } catch (e, stack) {
      dev.log('Error pushing to Firestore', error: e, stackTrace: stack);
    }
  }

  /// Pull clients from Firestore and update local DB (Download photos).
  Future<void> pullSync(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('clients')
          .where('userId', isEqualTo: userId)
          .get();
      
      final db = DbService();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final cloudClient = Client.fromMap(data);
        final localPhotos = await _downloadPhotos(cloudClient.id, cloudClient.photos);
        
        final clientToSave = Client(
          id: cloudClient.id,
          userId: userId,
          name: cloudClient.name,
          gender: cloudClient.gender,
          measurements: cloudClient.measurements,
          photos: localPhotos,
          createdAt: cloudClient.createdAt,
        );
        
        await db.insertClient(clientToSave);
      }
      dev.log('Successfully pulled ${snapshot.docs.length} clients from Firestore');
    } catch (e, stack) {
      dev.log('Error pulling from Firestore', error: e, stackTrace: stack);
    }
  }
}

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'delux.db');
      _db = await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE clients(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId TEXT,
              name TEXT NOT NULL,
              gender TEXT,
              measurements TEXT,
              photos TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE clients ADD COLUMN userId TEXT');
          }
        },
      );
      return _db!;
    } catch (e, stack) {
      dev.log('Error opening database', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> migrateFromStorage(StorageService storage) async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM clients'));
      if (count != null && count > 0) return;
      
      final old = await storage.loadClients();
      if (old.isEmpty) return;
      
      for (var c in old) {
        await insertClient(c);
      }
      dev.log('Successfully migrated ${old.length} clients from SharedPreferences');
    } catch (e, stack) {
      dev.log('Error migrating from storage', error: e, stackTrace: stack);
    }
  }

  Future<List<Client>> getClients() async {
    try {
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
          userId: r['userId'] as String?,
          name: r['name'] as String,
          gender: r['gender'] as String? ?? 'male',
          measurements: measurements,
          photos: photos,
          createdAt: DateTime.parse(r['createdAt'] as String),
        );
      }).toList();
    } catch (e, stack) {
      dev.log('Error fetching clients', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<void> insertClient(Client c) async {
    try {
      final db = await database;
      await db.insert(
        'clients',
        {
          'id': c.id, // Ensure ID is preserved for sync
          'userId': c.userId,
          'name': c.name,
          'gender': c.gender,
          'measurements': jsonEncode(c.measurements),
          'photos': jsonEncode(c.photos),
          'createdAt': c.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stack) {
      dev.log('Error inserting client', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      final db = await database;
      await db.delete('clients', where: 'id = ?', whereArgs: [id]);
    } catch (e, stack) {
      dev.log('Error deleting client', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateClient(Client c) async {
    try {
      final db = await database;
      await db.update(
        'clients',
        {
          'userId': c.userId,
          'name': c.name,
          'gender': c.gender,
          'measurements': jsonEncode(c.measurements),
          'photos': jsonEncode(c.photos),
          'createdAt': c.createdAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [c.id],
      );
    } catch (e, stack) {
      dev.log('Error updating client', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
