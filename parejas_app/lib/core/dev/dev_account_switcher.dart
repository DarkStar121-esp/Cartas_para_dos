import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_session.dart';
import '../auth/mock_auth_service.dart';

/// Botón flotante SOLO visible en modo debug (`kDebugMode`) Y solo
/// cuando la app está corriendo con `MockAuthService` (desarrollo sin
/// Firebase) — deja crear cuentas de prueba y saltar entre ellas. Es la
/// única forma razonable de probar el flujo de pairing y el multijugador
/// completo desde un solo dispositivo antes de tener Firebase conectado.
/// Una vez conectado Firebase de verdad (`FirebaseAuthService`), este
/// botón se oculta solo — ahí cada celular tiene su propia cuenta real y
/// no tiene sentido "saltar" entre cuentas.
class DevAccountSwitcherFab extends StatelessWidget {
  const DevAccountSwitcherFab({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    if (!kDebugMode || session.authService is! MockAuthService) {
      return const SizedBox.shrink();
    }
    final mockAuth = session.authService as MockAuthService;

    return Positioned(
      right: 12,
      bottom: 12,
      child: FloatingActionButton.small(
        heroTag: 'dev-account-switcher',
        backgroundColor: Colors.black87,
        onPressed: () => _openSheet(context, session, mockAuth),
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }

  void _openSheet(BuildContext context, AppSession session, MockAuthService mockAuth) {
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
            for (final account in mockAuth.allAccounts)
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
