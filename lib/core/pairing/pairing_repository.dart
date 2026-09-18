import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_account.dart';
import '../../models/gender.dart';
import 'pairing_models.dart';

abstract class PairingRepository {
  Future<String> generatePairingCode(String userId);
  Future<PairingResult> sendPairingRequest(String code, UserAccount currentUser);
  Stream<PairingRequest?> watchIncomingRequest(String userId);
  Future<void> acceptPairingRequest(PairingRequest request);
  Future<void> confirmPairing(dynamic request);
  Future<void> rejectPairingRequest(PairingRequest request);
  Stream<UserAccount> discoverOnLocalNetwork();
  Future<UserAccount?> findById(String userId);
}

class FirestorePairingRepository implements PairingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> generatePairingCode(String userId) async {
    final code = (100000 + (userId.hashCode.abs() % 900000)).toString();
    await _firestore.collection('pairing_codes').doc(code).set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  @override
  Future<PairingResult> sendPairingRequest(String code, UserAccount currentUser) async {
    final doc = await _firestore.collection('pairing_codes').doc(code).get();
    if (!doc.exists) {
      return PairingResult.error('Código no encontrado');
    }
    final targetUserId = doc.data()?['userId'] as String?;
    if (targetUserId == null) {
      return PairingResult.error('Código inválido');
    }

    await _firestore.collection('pairing_requests').doc(targetUserId).set({
      'fromUserId': currentUser.id,
      'fromUserName': currentUser.displayName,
      'code': code,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return PairingResult.success();
  }

  @override
  Stream<PairingRequest?> watchIncomingRequest(String userId) {
    return _firestore
        .collection('pairing_requests')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      return PairingRequest(
        id: snapshot.id,
        fromUserId: data['fromUserId'] ?? '',
        fromUserName: data['fromUserName'] ?? 'Usuario',
      );
    });
  }

  @override
  Future<void> acceptPairingRequest(PairingRequest request) async {
    await confirmPairing(request);
  }

  @override
  Future<void> confirmPairing(dynamic request) async {
    if (request is PairingRequest) {
      await _firestore.collection('couples').add({
        'users': [request.id, request.fromUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('pairing_requests').doc(request.id).delete();
    } else if (request is String) {
      await _firestore.collection('pairing_requests').doc(request).delete();
    }
  }

  @override
  Future<void> rejectPairingRequest(PairingRequest request) async {
    await _firestore.collection('pairing_requests').doc(request.id).delete();
  }

  @override
  Stream<UserAccount> discoverOnLocalNetwork() => const Stream.empty();

  @override
  Future<UserAccount?> findById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return UserAccount(
      id: doc.id,
      displayName: data['displayName'] ?? 'Usuario',
      email: data['email'] ?? '',
      gender: Gender.values.firstWhere(
        (g) => g.name == (data['gender'] ?? 'other'),
        orElse: () => Gender.other,
      ),
    );
  }
}

typedef InMemoryPairingRepository = FirestorePairingRepository;
