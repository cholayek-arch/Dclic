import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


abstract class ClientFormState<T extends StatefulWidget> extends State<T> {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final Map<String, TextEditingController> measureCtrls = {};
  final List<String> photoPaths = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  void initDefaultMeasurements(String gender) {
    final Map<String, List<String>> defaults = {
      'male': [
        'Longueur',
        'Épaule',
        'Poitrine',
        'Manche',
        'Encolure',
        'Poignet',
        'Taille',
        'Hanche',
        'Pantalon',
        'Cuisse',
        'Bassin'
      ],
      'female': [
        'Longueur Robe',
        'Longueur Haut',
        'Épaule',
        'Poitrine',
        'Tour de taille',
        'Hanche',
        'Manche',
        'Encolure',
        'Tour de bras',
        'Longueur Jupe'
      ],
    };

    final labels = defaults[gender] ?? [];
    for (var label in labels) {
      measureCtrls[label] = TextEditingController();
    }
  }
  @override
  void dispose() {
    nameCtrl.dispose();
    for (var c in measureCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }


  Future<void> showAddCustomFieldDialog() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter champ personnalisé'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom du champ (ex: Épaule)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );

    if (res == null || res.isEmpty) return;
    if (measureCtrls.containsKey(res)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce champ existe déjà')));
      return;
    }
    setState(() => measureCtrls[res] = TextEditingController());
  }

  Future<void> takePhoto() async {
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
      setState(() => photoPaths.add(savedPath));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la prise de photo: $e')));
    }
  }

  Future<void> removePhoto(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (!mounted) return;
    setState(() => photoPaths.remove(path));
  }

  Map<String, double> getValidatedMeasurements() {
    final measurements = <String, double>{};
    for (var entry in measureCtrls.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text.replaceAll(',', '.'));
        if (value != null && value > 0 && value <= 1000) {
          measurements[entry.key] = value;
        }
      }
    }
    return measurements;
  }
}
