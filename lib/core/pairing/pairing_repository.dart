import 'dart:async';
import '../../models/couple.dart';
import '../../models/relationship_type.dart';
import '../../models/user_account.dart';
import '../auth/mock_auth_service.dart';
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
  Future<UserAccount?> findById(String userId);
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

  /// Necesario para que quien MANDÓ la solicitud (no quien la confirma)
  /// pueda recuperar la pareja recién creada a partir del coupleId que
  /// le va a aparecer en su propia cuenta (ver AuthService.watchAccount
  /// + core/app_session.dart).
  Future<Couple?> fetchCouple(String coupleId);

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

/// Implementación en memoria — delega la búsqueda de cuentas en
/// [MockAuthService] (que es quien realmente las guarda) y agrega encima
/// la mensajería de solicitudes de pairing, una por cada usuario
/// destinatario (así dos pantallas escuchando `watchIncomingRequest` con
/// ids distintos no se pisan entre sí).
class InMemoryPairingRepository implements PairingRepository {
  @override
  Stream<UserAccount> discoverOnLocalNetwork() => const Stream.empty();
  @override
  @override
  @override
  final MockAuthService authService;
  final Map<String, StreamController<PairingRequest?>> _incomingByUserId = {};
  final Map<String, Couple> _couplesById = {};

  InMemoryPairingRepository(this.authService);

  @override
  Future<UserAccount?> findByPairingCode(String code) async => authService.findByPairingCode(code);

  @override
  Future<UserAccount?> findById(String userId) async => authService.findById(userId);

  @override
  Future<PairingRequest> sendPairingRequest(String fromUserId, String toPairingCode) async {
    final target = authService.findByPairingCode(toPairingCode);
    if (target == null) {
      throw StateError('No existe ninguna cuenta con ese código.');
    }
    if (target.isPaired) {
      throw StateError('Esa cuenta ya está conectada con otra pareja.');
    }

    final request = PairingRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: fromUserId,
      toPairingCode: toPairingCode,
      createdAt: DateTime.now(),
    );
    _controllerFor(target.id).add(request);
    return request;
  }

  @override
  Stream<PairingRequest?> watchIncomingRequest(String userId) => _controllerFor(userId).stream;

  @override
  Future<Couple> confirmPairing(
    PairingRequest request, {
    required RelationshipType relationshipType,
    required DateTime relationshipStartDate,
  }) async {
    final fromAccount = authService.findById(request.fromUserId);
    final toAccount = authService.findByPairingCode(request.toPairingCode);
    if (fromAccount == null || toAccount == null) {
      throw StateError('Una de las dos cuentas ya no existe.');
    }

    final couple = Couple(
      id: 'couple_${DateTime.now().millisecondsSinceEpoch}',
      user1Id: fromAccount.id,
      user2Id: toAccount.id,
      relationshipType: relationshipType,
      relationshipStartDate: relationshipStartDate,
      pairedAt: DateTime.now(),
    );

    authService.updateAccount(fromAccount.copyWith(coupleId: couple.id));
    authService.updateAccount(toAccount.copyWith(coupleId: couple.id));
    _couplesById[couple.id] = couple;

    _controllerFor(toAccount.id).add(null);
    return couple;
  }

  @override
  Future<Couple?> fetchCouple(String coupleId) async => _couplesById[coupleId];

  StreamController<PairingRequest?> _controllerFor(String userId) =>
      _incomingByUserId.putIfAbsent(userId, () => StreamController<PairingRequest?>.broadcast());

  void dispose() {
    for (final c in _incomingByUserId.values) {
      c.close();
    }
  }
}
