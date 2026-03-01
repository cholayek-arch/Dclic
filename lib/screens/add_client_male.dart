import 'package:flutter/material.dart';

import '../models/client.dart';
import '../services/db_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../widgets/measurement_field.dart';

class AddClientMaleScreen extends StatefulWidget {
  const AddClientMaleScreen({super.key});

  @override
  State<AddClientMaleScreen> createState() => _AddClientMaleScreenState();
}

class _AddClientMaleScreenState extends State<AddClientMaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final Map<String, TextEditingController> _measureCtrls = {};
  final List<String> _photoPaths = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var c in _measureCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _showAddCustomFieldDialog() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter champ personnalisé'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom du champ')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );
    if (res == null || res.isEmpty) return;
    if (_measureCtrls.containsKey(res)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce champ existe déjà')));
      return;
    }
    if (!mounted) return;
    setState(() => _measureCtrls[res] = TextEditingController());
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (xfile == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'client_photos'));
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final filename = '${DateTime.now().millisecondsSinceEpoch}${p.extension(xfile.path)}';
      final savedPath = p.join(photosDir.path, filename);
      await File(xfile.path).copy(savedPath);
      if (!mounted) return;
      setState(() => _photoPaths.add(savedPath));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la prise de photo: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = DateTime.now().millisecondsSinceEpoch;
    final name = _nameCtrl.text.trim();
    final measurements = <String, double>{};
    for (var entry in _measureCtrls.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text.replaceAll(',', '.'));
        if (value == null || value <= 0 || value > 1000) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Valeur invalide pour "${entry.key}"')));
          return;
        }
        measurements[entry.key] = value;
      }
    }
    final client = Client(id: id, name: name, gender: 'male', measurements: measurements, photos: _photoPaths);
    await DbService().insertClient(client);
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter • Homme  🧵')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom du client'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              const Text('Champs personnalisés', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._measureCtrls.entries
                  .map((e) => MeasurementField(label: e.key, controller: e.value, showDelete: true, onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: Text('Supprimer le champ "${e.key}" ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          setState(() {
                            e.value.dispose();
                            _measureCtrls.remove(e.key);
                          });
                        }
                      })),
              TextButton.icon(onPressed: _showAddCustomFieldDialog, icon: const Icon(Icons.add), label: const Text('Ajouter champ personnalisé')),
              const SizedBox(height: 16),
              const Text('Photos des pagnes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._photoPaths.map((path) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), width: 84, height: 84, fit: BoxFit.cover)),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                final f = File(path);
                                if (await f.exists()) await f.delete();
                              } catch (_) {}
                              if (!mounted) return;
                              setState(() => _photoPaths.remove(path));
                            },
                            child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  }),
                  ElevatedButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Prendre photo'))
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Enregistrer'))),
            ],
          ),
        ),
      ),
    );
  }
}
