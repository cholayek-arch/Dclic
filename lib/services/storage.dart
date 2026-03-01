import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';

class StorageService {
  static const _key = 'clients_v1';

  Future<List<Client>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString) as List;
    return decoded.map((e) => Client.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(clients.map((c) => c.toMap()).toList());
    await prefs.setString(_key, encoded);
  }
}
