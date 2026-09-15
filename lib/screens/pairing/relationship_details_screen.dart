import 'package:flutter/material.dart';
import '../../models/relationship_type.dart';

/// Se muestra justo después de aceptar el aviso de irreversibilidad y
/// antes de confirmar el pairing definitivo — pide los datos básicos de
/// la pareja (sección 2 del diseño).
class RelationshipDetailsScreen extends StatefulWidget {
  final String partnerName;
  final void Function(RelationshipType type, DateTime startDate) onConfirm;

  const RelationshipDetailsScreen({
    super.key,
    required this.partnerName,
    required this.onConfirm,
  });

  @override
  State<RelationshipDetailsScreen> createState() => _RelationshipDetailsScreenState();
}

class _RelationshipDetailsScreenState extends State<RelationshipDetailsScreen> {
  RelationshipType? _type;
  DateTime? _startDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 60),
      lastDate: now,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _type != null && _startDate != null;
    return Scaffold(
      appBar: AppBar(title: Text('Vos y ${widget.partnerName}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué son?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RelationshipType.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('¿Desde cuándo?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _startDate == null
                    ? 'Elegir fecha'
                    : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: canConfirm ? () => widget.onConfirm(_type!, _startDate!) : null,
              child: const Text('Confirmar conexión'),
            ),
          ],
        ),
      ),
    );
  }
}
