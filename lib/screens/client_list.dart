import 'package:flutter/material.dart';
import 'dart:io';

import '../models/client.dart';
import '../services/storage.dart';
import '../services/db_service.dart';


import 'edit_client.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final StorageService _storage = StorageService();
  final DbService _db = DbService();
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Try migrating from old storage if DB is empty
    await _db.migrateFromStorage(_storage);
    final loaded = await _db.getClients();
    setState(() => _clients = loaded);
  }

  Future<void> _removeClient(Client c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le client "${c.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteClient(c.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [Text('🧵  '), Text('Clients - Prise de mesures')],
        ),
        toolbarHeight: 90,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF80CBC4)]),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Gestion des clients et mesures', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _clients.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧵', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text('Aucun client', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Vous n\'avez encore aucun client enregistré.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _clients.length,
                itemBuilder: (context, i) {
                  final c = _clients[i];
                  final isMale = c.gender == 'male';
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: isMale ? Colors.blueAccent : Colors.pinkAccent,
                            child: Icon(isMale ? Icons.male : Icons.female, color: Colors.white, size: 24),
                          ),
                          title: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isMale ? 'Homme' : 'Femme', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isMale ? Colors.blueAccent : Colors.pinkAccent)),
                              Text('${c.measurements.length} mesures', style: Theme.of(context).textTheme.bodySmall),
                              Text('${c.photos.length} photos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.teal)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            onPressed: () => _removeClient(c),
                          ),
                          onTap: () async {
                            final changed = await Navigator.of(context).push<bool?>(
                              MaterialPageRoute(builder: (_) => EditClientScreen(client: c)),
                            );
                            if (!mounted) return;
                            if (changed == true) await _load();
                          },
                        ),
                        if (c.photos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Wrap(
                              spacing: 8,
                              children: c.photos
                                  .map(
                                    (path) => ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
