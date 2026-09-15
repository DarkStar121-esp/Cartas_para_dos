import 'dart:async';
import '../../models/couple.dart';
import '../../models/relationship_type.dart';
import '../../models/user_account.dart';
import 'pairing_models.dart';

/// Contrato que usa toda la UI de pairing. La implementación real
/// (Firebase) tiene que garantizar:
///
///  - Validar que el pairingCode exista y la cuenta destino no esté ya
///    emparejada (isPaired == true rechaza la solicitud).
///  - Notificar al otro dispositivo en tiempo real (listener de Firestore
///    o push notification) para que vea la solicitud entrante.
///  - Al confirmar: crear el Couple Y setear coupleId en ambas cuentas
///    dentro de la MISMA transacción atómica de Firestore. Si se hace en
///    dos escrituras separadas, una falla a mitad de camino puede dejar
///    a una cuenta "emparejada" y a la otra no.
abstract class PairingRepository {
  Future<UserAccount?> findByPairingCode(String code);
  Future<PairingRequest> sendPairingRequest(String fromUserId, String toPairingCode);

  /// Emite la solicitud pendiente para [userId] (o null si no hay
  /// ninguna) — así la UI puede mostrar el diálogo de confirmación en
  /// cuanto llega, sin tener que hacer polling.
  Stream<PairingRequest?> watchIncomingRequest(String userId);

  Future<Couple> confirmPairing(
    PairingRequest request, {
    required RelationshipType relationshipType,
    required DateTime relationshipStartDate,
  });

  /// Descubrimiento por WiFi: busca otras cuentas de esta app anunciándose
  /// en la red local y devuelve candidatos para autocompletar el código.
  /// Nunca empareja directamente — siempre termina pasando por
  /// sendPairingRequest + confirmPairing, igual que el flujo manual.
  ///
  /// No implementado en este scaffold: requiere paquetes de plataforma
  /// (network_info_plus + multicast_dns) y probarse en dispositivos
  /// físicos reales — no tiene sentido simularlo acá. Ver
  /// ACCOUNTS_AND_PROGRESSION.md sección 3.1.
  Stream<UserAccount> discoverOnLocalNetwork() {
    throw UnimplementedError(
      'Implementar con multicast_dns/network_info_plus — ver ACCOUNTS_AND_PROGRESSION.md sección 3.1',
    );
  }
}

/// Implementación en memoria, solo para desarrollar y probar la UI de
/// pairing sin depender todavía de un proyecto de Firebase configurado.
class InMemoryPairingRepository implements PairingRepository {
  final List<UserAccount> accounts;
  final _requestsController = StreamController<PairingRequest?>.broadcast();
  PairingRequest? _pending;

  InMemoryPairingRepository(this.accounts);

  @override
  Future<UserAccount?> findByPairingCode(String code) async {
    for (final a in accounts) {
      if (a.pairingCode == code) return a;
    }
    return null;
  }

  @override
  Future<PairingRequest> sendPairingRequest(String fromUserId, String toPairingCode) async {
    final req = PairingRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromUserId: fromUserId,
      toPairingCode: toPairingCode,
      createdAt: DateTime.now(),
    );
    _pending = req;
    _requestsController.add(req);
    return req;
  }

  @override
  Stream<PairingRequest?> watchIncomingRequest(String userId) => _requestsController.stream;

  @override
  Future<Couple> confirmPairing(
    PairingRequest request, {
    required RelationshipType relationshipType,
    required DateTime relationshipStartDate,
  }) async {
    _pending = null;
    _requestsController.add(null);
    // TODO: conectar con Firestore para crear el Couple real y trabar
    // coupleId en ambas cuentas dentro de una transacción.
    throw UnimplementedError('Conectar con la implementación real (Firestore).');
  }

  void dispose() => _requestsController.close();
}
