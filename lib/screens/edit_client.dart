import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/db_service.dart';
import '../widgets/measurement_field.dart';
import '../widgets/client_form_base.dart';
import 'dart:io';

class EditClientScreen extends StatefulWidget {
  final Client client;
  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends ClientFormState<EditClientScreen> {
  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.client.name;
    photoPaths.addAll(widget.client.photos);
    widget.client.measurements.forEach((key, value) {
      measureCtrls[key] = TextEditingController(text: value.toString());
    });
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    
    final name = nameCtrl.text.trim();
    final measurements = getValidatedMeasurements();

    final updated = Client(
      id: widget.client.id,
      userId: currentUserId,
      name: name,
      gender: widget.client.gender,
      measurements: measurements,
      photos: photoPaths,
      createdAt: widget.client.createdAt,
    );

    try {
      await DbService().updateClient(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour : $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Éditer le client  🧵')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final contentWidth = isWide ? 600.0 : constraints.maxWidth;
          
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom du client',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 24),
                      const Text('Champs personnalisés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      
                      // Adaptive layout for measurement fields
                      if (isWide)
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: measureCtrls.entries.map((e) => SizedBox(
                            width: (contentWidth - 48) / 2,
                            child: _buildMeasurementField(e),
                          )).toList(),
                        )
                      else
                        ...measureCtrls.entries.map((e) => _buildMeasurementField(e)),
                        
                      TextButton.icon(
                        onPressed: showAddCustomFieldDialog, 
                        icon: const Icon(Icons.add), 
                        label: const Text('Ajouter champ personnalisé')
                      ),
                      const SizedBox(height: 24),
                      const Text('Photos des pagnes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _buildPhotoGrid(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, 
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Sauvegarder les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeasurementField(MapEntry<String, TextEditingController> e) {
    return MeasurementField(
      label: e.key, 
      controller: e.value, 
      showDelete: true, 
      onDelete: () async {
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
            measureCtrls.remove(e.key);
          });
        }
      }
    );
  }

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...photoPaths.map((path) => Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12), 
              child: Image.file(File(path), width: 90, height: 90, fit: BoxFit.cover)
            ),
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: () => removePhoto(path),
                child: Container(
                  padding: const EdgeInsets.all(4), 
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
                  child: const Icon(Icons.close, size: 16, color: Colors.white)
                ),
              ),
            ),
          ],
        )),
        InkWell(
          onTap: takePhoto,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                SizedBox(height: 4),
                Text('Photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
