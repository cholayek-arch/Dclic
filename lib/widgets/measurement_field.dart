import 'package:flutter/material.dart';

class MeasurementField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool showDelete;
  final VoidCallback? onDelete;

  const MeasurementField({
    super.key,
    required this.label,
    required this.controller,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  border: InputBorder.none,
                  hintText: 'Valeur (cm)',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final value = double.tryParse(text.replaceAll(',', '.'));
                  if (value == null || value <= 0 || value > 1000) return 'Valeur invalide';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('cm', style: TextStyle(color: Colors.black54)),
            if (showDelete) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
                tooltip: 'Supprimer',
              ),
            ]
          ],
        ),
      ),
    );
  }
}
