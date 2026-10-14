import 'package:flutter/material.dart';
import '../../core/pairing/local_network_discovery_service.dart';

/// Busca a tu pareja en la misma red WiFi (broadcast UDP local) y deja
/// mandarle la solicitud con un toque, sin tipear el código. Sigue
/// pasando por el mismo flujo de solicitud/confirmación que el código
/// manual — esto solo ahorra escribirlo.
class WifiDiscoveryScreen extends StatefulWidget {
  final String myUserId;
  final String myPairingCode;
  final String myName;
  final Future<void> Function(String code) onSendRequest;

  const WifiDiscoveryScreen({
    super.key,
    required this.myUserId,
    required this.myPairingCode,
    required this.myName,
    required this.onSendRequest,
  });

  @override
  State<WifiDiscoveryScreen> createState() => _WifiDiscoveryScreenState();
}

class _WifiDiscoveryScreenState extends State<WifiDiscoveryScreen> {
  final _service = LocalNetworkDiscoveryService();
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service
        .start(myUserId: widget.myUserId, myPairingCode: widget.myPairingCode, myName: widget.myName)
        .catchError((e) {
      if (mounted) setState(() => _error = 'No se pudo usar la red local: $e');
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _connectTo(DiscoveredPeer peer) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Conectar?'),
            content: Text('Le vas a mandar una solicitud de conexión a "${peer.name}".'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mandar solicitud')),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _sending = true);
    try {
      await widget.onSendRequest(peer.pairingCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud enviada a ${peer.name}. Esperando que la confirme…')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar por WiFi')),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Podés seguir usando "Ingresar el código de mi pareja" en vez de esto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          : StreamBuilder<List<DiscoveredPeer>>(
              stream: _service.peers,
              builder: (context, snapshot) {
                final peers = snapshot.data ?? const [];
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Buscando en tu red WiFi… tu pareja tiene que tener esta misma '
                              'pantalla abierta en su celular, conectado a la misma red.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (peers.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Todavía no encontramos a nadie.', style: TextStyle(color: Colors.black54)),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: peers.length,
                          itemBuilder: (context, i) {
                            final peer = peers[i];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(peer.name),
                              trailing: const Icon(Icons.chevron_right),
                              enabled: !_sending,
                              onTap: () => _connectTo(peer),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
