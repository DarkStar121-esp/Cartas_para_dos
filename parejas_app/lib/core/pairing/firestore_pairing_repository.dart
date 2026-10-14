import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/couple.dart';
import '../../models/relationship_type.dart';
import '../../models/user_account.dart';
import 'pairing_models.dart';
import 'pairing_repository.dart';

/// Implementación real de [PairingRepository] con Firestore. Colecciones:
///  - `users/{uid}` — ya la usa FirebaseAuthService.
///  - `pairing_requests/{id}` — solicitudes pendientes; se guarda también
///    `toUserId` (no solo el código) para poder escuchar por
///    destinatario sin depender de una query por campo cada vez.
///  - `couples/{coupleId}` — la pareja creada al confirmar.
///
/// Usa `extends` (no `implements`) por costumbre/seguridad a futuro: si
/// algún día PairingRepository vuelve a tener un método con cuerpo por
/// defecto, `extends` lo hereda solo — con `implements` el build fallaría
/// por "falta implementar la función" (el bug real que tuvo
/// InMemoryPairingRepository, ver FIREBASE_SETUP.md).
///
/// El descubrimiento por WiFi NO vive acá ni en la interfaz — es
/// LocalNetworkDiscoveryService, puramente de red local, sin tocar
/// Firestore para nada (ver local_network_discovery_service.dart).
///
/// Ver FIREBASE_SETUP.md para las reglas de seguridad recomendadas y el
/// índice compuesto que pide `watchIncomingRequest`.
class FirestorePairingRepository extends PairingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('pairing_requests');
  CollectionReference<Map<String, dynamic>> get _couples => _db.collection('couples');

  @override
  Future<UserAccount?> findByPairingCode(String code) async {
    final query = await _users.where('pairingCode', isEqualTo: code).limit(1).get();
    if (query.docs.isEmpty) return null;
    return UserAccount.fromJson(query.docs.first.data());
  }

  @override
  Future<UserAccount?> findById(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserAccount.fromJson(doc.data()!);
  }

  @override
  Future<PairingRequest> sendPairingRequest(String fromUserId, String toPairingCode) async {
    final target = await findByPairingCode(toPairingCode);
    if (target == null) {
      throw StateError('No existe ninguna cuenta con ese código.');
    }
    if (target.isPaired) {
      throw StateError('Esa cuenta ya está conectada con otra pareja.');
    }

    final doc = _requests.doc();
    final request = PairingRequest(
      id: doc.id,
      fromUserId: fromUserId,
      toPairingCode: toPairingCode,
      createdAt: DateTime.now(),
    );
    await doc.set({
      'fromUserId': request.fromUserId,
      'toPairingCode': request.toPairingCode,
      'toUserId': target.id,
      'createdAt': request.createdAt.toIso8601String(),
      'status': request.status.name,
    });
    return request;
  }

  @override
  Stream<PairingRequest?> watchIncomingRequest(String userId) {
    return _requests
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: PairingRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      return PairingRequest(
        id: snap.docs.first.id,
        fromUserId: data['fromUserId'] as String,
        toPairingCode: data['toPairingCode'] as String,
        createdAt: DateTime.parse(data['createdAt'] as String),
        status: PairingRequestStatus.values.byName(data['status'] as String),
      );
    });
  }

  @override
  Future<Couple> confirmPairing(
    PairingRequest request, {
    required RelationshipType relationshipType,
    required DateTime relationshipStartDate,
  }) async {
    final toAccount = await findByPairingCode(request.toPairingCode);
    if (toAccount == null) {
      throw StateError('La cuenta destino ya no existe.');
    }

    final fromDoc = _users.doc(request.fromUserId);
    final toDoc = _users.doc(toAccount.id);
    final coupleDoc = _couples.doc();
    final requestDoc = _requests.doc(request.id);

    late final Couple couple;
    await _db.runTransaction((tx) async {
      final fromSnap = await tx.get(fromDoc);
      final toSnap = await tx.get(toDoc);
      if (!fromSnap.exists || !toSnap.exists) {
        throw StateError('Una de las dos cuentas ya no existe.');
      }
      final fromAccount = UserAccount.fromJson(fromSnap.data()!);

      couple = Couple(
        id: coupleDoc.id,
        user1Id: fromAccount.id,
        user2Id: toAccount.id,
        relationshipType: relationshipType,
        relationshipStartDate: relationshipStartDate,
        pairedAt: DateTime.now(),
      );

      // Todo en la misma transacción: si algo falla a mitad de camino,
      // Firestore no aplica NINGUNO de estos cambios — no puede quedar
      // una cuenta emparejada y la otra no.
      tx.set(coupleDoc, couple.toJson());
      tx.update(fromDoc, {'coupleId': couple.id});
      tx.update(toDoc, {'coupleId': couple.id});
      tx.update(requestDoc, {'status': PairingRequestStatus.accepted.name});
    });

    return couple;
  }

  @override
  Future<Couple?> fetchCouple(String coupleId) async {
    final doc = await _couples.doc(coupleId).get();
    if (!doc.exists) return null;
    return Couple.fromJson(doc.data()!);
  }
}
