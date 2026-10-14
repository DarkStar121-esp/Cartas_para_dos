import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Una cuenta encontrada en la red local, lista para mandarle una
/// solicitud de pairing (con su código, sin tener que tipearlo a mano).
class DiscoveredPeer {
  final String userId;
  final String pairingCode;
  final String name;
  final DateTime lastSeenAt;

  const DiscoveredPeer({
    required this.userId,
    required this.pairingCode,
    required this.name,
    required this.lastSeenAt,
  });
}

/// Descubrimiento por WiFi real, sin depender de paquetes de mDNS de
/// terceros (que en Flutter suelen ser solo para "buscar", no para
/// "anunciarse" — para esto último casi siempre hace falta código nativo
/// por plataforma). En cambio, esto usa un broadcast UDP simple con
/// `dart:io`: cada dispositivo anuncia su código cada 2 segundos a la
/// dirección de broadcast de la red (255.255.255.255) por un puerto
/// fijo, y a la vez escucha ese mismo puerto para encontrar anuncios de
/// otros. Como los dos lados son la MISMA app, no hace falta que el
/// protocolo sea compatible con nada más que consigo mismo.
///
/// Esto NUNCA empareja directo: solo arma la lista de candidatos para
/// autocompletar el código. La conexión real sigue pasando por
/// PairingRepository.sendPairingRequest + confirmPairing, como el flujo
/// manual — ver ACCOUNTS_AND_PROGRESSION.md sección 3.1.
///
/// Limitación conocida, real e inevitable: algunas redes WiFi (sobre
/// todo las públicas, o con "aislamiento de clientes/AP isolation"
/// activado en el router) bloquean el tráfico broadcast entre
/// dispositivos conectados. Ahí este descubrimiento no va a encontrar
/// nada — el código manual (sección "Ingresar el código de mi pareja")
/// sigue funcionando siempre, porque no depende de la red local.
class LocalNetworkDiscoveryService {
  static const int _port = 45678;
  static const String _magic = 'parejas_app_discovery_v1';
  static const _announceInterval = Duration(seconds: 2);
  static const _staleAfter = Duration(seconds: 7);

  RawDatagramSocket? _socket;
  Timer? _announceTimer;
  Timer? _pruneTimer;
  final Map<String, DiscoveredPeer> _peers = {};
  final _peersController = StreamController<List<DiscoveredPeer>>.broadcast();

  bool get isRunning => _socket != null;

  Stream<List<DiscoveredPeer>> get peers => _peersController.stream;

  /// Arranca a anunciarse Y a escuchar al mismo tiempo — cualquiera de
  /// los dos que abra esta pantalla encuentra al otro, sin que importe
  /// quién la abrió primero.
  Future<void> start({
    required String myUserId,
    required String myPairingCode,
    required String myName,
  }) async {
    if (_socket != null) return; // ya está corriendo

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port, reuseAddress: true);
    } on SocketException {
      // el puerto puede estar ocupado si ya hay otra instancia corriendo
      // (ej. hot restart en desarrollo) — reintentar con reuseAddress ya
      // debería alcanzar, pero si falla de nuevo no hay mucho más para
      // hacer que avisar y dejar el código manual como alternativa.
      rethrow;
    }
    _socket!.broadcastEnabled = true;

    _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket!.receive();
      if (datagram == null) return;
      _handleIncoming(datagram.data, myUserId);
    });

    void announce() => _broadcastAnnounce(myUserId, myPairingCode, myName);
    announce();
    _announceTimer = Timer.periodic(_announceInterval, (_) => announce());
    _pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pruneStale());
  }

  void _broadcastAnnounce(String userId, String code, String name) {
    final payload = utf8.encode(jsonEncode({
      'magic': _magic,
      'userId': userId,
      'pairingCode': code,
      'name': name,
    }));
    try {
      _socket?.send(payload, InternetAddress('255.255.255.255'), _port);
    } catch (_) {
      // Red que bloquea broadcast — no hay nada que hacer del lado del
      // cliente, el descubrimiento simplemente no va a encontrar a nadie.
    }
  }

  void _handleIncoming(List<int> data, String myUserId) {
    Map<String, dynamic> map;
    try {
      map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } catch (_) {
      return; // paquete corrupto o de otra cosa en la red, ignorar
    }
    if (map['magic'] != _magic) return;

    final userId = map['userId'] as String?;
    final pairingCode = map['pairingCode'] as String?;
    final name = map['name'] as String?;
    if (userId == null || pairingCode == null || name == null) return;
    if (userId == myUserId) return; // no mostrarme a mí mismo en la lista

    _peers[userId] = DiscoveredPeer(
      userId: userId,
      pairingCode: pairingCode,
      name: name,
      lastSeenAt: DateTime.now(),
    );
    _emit();
  }

  void _pruneStale() {
    final cutoff = DateTime.now().subtract(_staleAfter);
    final before = _peers.length;
    _peers.removeWhere((_, peer) => peer.lastSeenAt.isBefore(cutoff));
    if (_peers.length != before) _emit();
  }

  void _emit() {
    if (_peersController.isClosed) return;
    _peersController.add(_peers.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<void> stop() async {
    _announceTimer?.cancel();
    _pruneTimer?.cancel();
    _announceTimer = null;
    _pruneTimer = null;
    _socket?.close();
    _socket = null;
    _peers.clear();
  }

  void dispose() {
    stop();
    _peersController.close();
  }
}
