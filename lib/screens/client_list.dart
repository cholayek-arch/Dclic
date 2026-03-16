import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client.dart';
import '../services/storage.dart';
import '../services/db_service.dart';
import 'edit_client.dart';
import 'login_page.dart';
import 'premium_purchase_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final StorageService _storage = StorageService();
  final DbService _db = DbService();
  final FirestoreService _firestore = FirestoreService();
  
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  final TextEditingController _searchCtrl = TextEditingController();
  
  bool _isSearching = false;
  bool _isSyncing = false;
  bool _isPremium = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isPrem = await _firestore.isUserPremium(user.uid);
      if (mounted) {
        setState(() {
          _currentUserId = user.uid;
          _isPremium = isPrem;
        });
        // Automatiquement synchroniser les données au démarrage ou après connexion
        if (isPrem) {
          _manualSync();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentUserId = null;
          _isPremium = false;
        });
      }
    }
  }

  Future<void> _load() async {
    try {
      await _db.migrateFromStorage(_storage);
      final loaded = await _db.getClients();
      if (!mounted) return;
      setState(() {
        _allClients = loaded;
        _filteredClients = loaded;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des clients : $e'))
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _allClients;
      } else {
        _filteredClients = _allClients.where((c) {
          return c.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _manualSync() async {
    if (_currentUserId == null) {
      _cloudBackup();
      return;
    }
    
    if (!_isPremium) {
      final bought = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
      );
      if (bought == true) {
        await _checkAuthStatus();
      } else {
        return;
      }
    }

    setState(() => _isSyncing = true);
    try {
      // Pull latest from cloud
      await _firestore.pullSync(_currentUserId!);
      // Get all local data (merged)
      final latest = await _db.getClients();
      // Push merge result to cloud
      await _firestore.pushSync(_currentUserId!, latest);
      
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronisation réussie')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de synchronisation : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _removeClient(Client c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le client "${c.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _db.deleteClient(c.id);
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e'))
        );
      }
    }
  }

  Future<void> _cloudBackup() async {
    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cloud_upload, color: Colors.teal),
              SizedBox(width: 8),
              Text("Sauvegarde cloud", style: TextStyle(fontSize: 20)),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Cette fonctionnalité est disponible en version Premium.\n"),
                _FeatureRow(icon: Icons.security, color: Colors.green, text: "Sécurisez vos clients et leurs mesures"),
                SizedBox(height: 8),
                _FeatureRow(icon: Icons.phone_android, color: Colors.blue, text: "Accès multi-appareils"),
                SizedBox(height: 8),
                _FeatureRow(icon: Icons.sync, color: Colors.orange, text: "Synchronisation automatique"),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Plus tard")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage())).then((_) => _checkAuthStatus());
              },
              child: const Text("Activer Premium"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un client...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
              )
            : const Text('Clients - Mesures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          if (_currentUserId != null && _isPremium)
            IconButton(
              icon: _isSyncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _manualSync,
              tooltip: 'Synchroniser',
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchCtrl.clear();
              });
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF80CBC4)]),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _filteredClients.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧵', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text(
                      _searchCtrl.text.isEmpty ? 'Aucun client enrégistré' : 'Aucun résultat trouvé',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final crossAxisCount = isWide ? (constraints.maxWidth / 350).floor() : 1;
                  
                  if (isWide) {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, i) => _buildClientCard(_filteredClients[i]),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, i) => _buildClientCard(_filteredClients[i]),
                    );
                  }
                },
              ),
      ),
    );
  }

  Widget _buildClientCard(Client c) {
    final isMale = c.gender == 'male';
    final heroTag = 'client_avatar_${c.id}';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Hero(
              tag: heroTag,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: isMale ? Colors.blueAccent : Colors.pinkAccent,
                child: Icon(isMale ? Icons.male : Icons.female, color: Colors.white, size: 24),
              ),
            ),
            title: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMale ? 'Homme' : 'Femme', style: TextStyle(color: isMale ? Colors.blueAccent : Colors.pinkAccent, fontSize: 12)),
                Text('${c.measurements.length} mesures', style: const TextStyle(fontSize: 12)),
                if (c.photos.isNotEmpty)
                  Text('${c.photos.length} photos', style: const TextStyle(color: Colors.teal, fontSize: 12)),
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
              if (changed == true) await _load();
            },
          ),
          if (c.photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.photos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final path = c.photos[idx];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: path.startsWith('http')
                        ? Image.network(path, width: 60, height: 60, fit: BoxFit.cover)
                        : Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _FeatureRow({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
