import 'package:flutter/material.dart';

/// Diálogo bloqueante que se muestra a quien RECIBE una solicitud de
/// pairing, antes de poder confirmarla. Tiene que aparecer siempre, no es
/// opcional — ver ACCOUNTS_AND_PROGRESSION.md sección 3.2.
Future<bool> showIrreversiblePairingWarning(
  BuildContext context, {
  required String partnerName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Esta conexión es permanente'),
      content: Text(
        'Una vez conectadas, tu cuenta y la de $partnerName no se van a poder '
        'desvincular desde la app. Todo el progreso (nivel, personalización, '
        'racha) va a ser compartido de acá en adelante.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Conectar para siempre'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
