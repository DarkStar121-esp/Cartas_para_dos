import 'package:flutter/material.dart';
import '../../models/gender.dart';

/// Alta de cuenta individual. El login con Google pasa antes que esta
/// pantalla (en el AuthGate de la app) — acá solo se completan los datos
/// que Google no provee: apellido, edad, sexo.
class CreateAccountScreen extends StatefulWidget {
  final String firstNameFromGoogle;
  final void Function({
    required String firstName,
    required String lastName,
    required int age,
    required Gender gender,
  }) onSubmit;

  const CreateAccountScreen({
    super.key,
    required this.firstNameFromGoogle,
    required this.onSubmit,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(text: widget.firstNameFromGoogle);
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  Gender? _gender;

  static const _minAge = 18;

  void _submit() {
    if (!_formKey.currentState!.validate() || _gender == null) {
      if (_gender == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Elegí una opción de sexo para continuar.')));
      }
      return;
    }
    widget.onSubmit(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creá tu cuenta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Apellido'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Edad'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null) return 'Ingresá un número';
                if (n < _minAge) return 'Tenés que ser mayor de $_minAge años';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Sexo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.female, label: Text('Mujer')),
                ButtonSegment(value: Gender.male, label: Text('Hombre')),
              ],
              selected: _gender == null ? {} : {_gender!},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) => setState(() => _gender = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _submit, child: const Text('Continuar')),
          ],
        ),
      ),
    );
  }
}
