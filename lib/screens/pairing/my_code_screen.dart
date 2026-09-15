import 'package:flutter/material.dart';
import '../../models/user_account.dart';
import 'enter_partner_code_screen.dart';

class MyCodeScreen extends StatelessWidget {
  final UserAccount me;
  final Future<void> Function(String code) onSendRequest;

  const MyCodeScreen({super.key, required this.me, required this.onSendRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar con tu pareja')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Tu código', style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                me.pairingCode,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compartíselo a tu pareja para que lo ingrese en su app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnterPartnerCodeScreen(me: me, onSendRequest: onSendRequest),
                ),
              ),
              icon: const Icon(Icons.keyboard),
              label: const Text('Ingresar el código de mi pareja'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Buscando en la red WiFi… (falta implementar multicast_dns, ver PairingRepository.discoverOnLocalNetwork)',
                  ),
                ),
              ),
              icon: const Icon(Icons.wifi),
              label: const Text('Buscar por WiFi'),
            ),
          ],
        ),
      ),
    );
  }
}
