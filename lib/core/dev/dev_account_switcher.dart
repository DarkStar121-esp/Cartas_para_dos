import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_session.dart';

/// Botón flotante SOLO visible en modo debug (`kDebugMode`) que deja
/// crear cuentas de prueba y saltar entre ellas. Es la única forma
/// razonable de probar el flujo de pairing y el multijugador completo
/// desde un solo dispositivo, ya que el backend en memoria vive en un
/// único proceso (no hay dos celulares de verdad acá). No aparece en
/// builds de release — `kDebugMode` lo saca solo.
class DevAccountSwitcherFab extends StatelessWidget {
  const DevAccountSwitcherFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Positioned(
      right: 12,
      bottom: 12,
      child: FloatingActionButton.small(
        heroTag: 'dev-account-switcher',
        backgroundColor: Colors.black87,
        onPressed: () => _openSheet(context),
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    final session = context.read<AppSession>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('🧪 Modo desarrollo — cambiar de cuenta',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final account in session.authService.allAccounts)
              ListTile(
                title: Text(account.fullName),
                subtitle: Text('Código: ${account.pairingCode}'),
                trailing:
                    session.myAccount?.id == account.id ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  session.devSignInAs(account);
                },
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Crear cuenta de prueba nueva'),
              onTap: () async {
                Navigator.pop(ctx);
                await session.devCreateAndSwitchToTestAccount();
              },
            ),
          ],
        ),
      ),
    );
  }
}
