import 'dart:async';
import '../../models/user_account.dart';
import '../../models/couple.dart';
import 'pairing_models.dart';

class PairingRepository {
  Future<void> sendPairingRequest([
    dynamic a1,
    dynamic a2,
    dynamic a3,
    dynamic a4,
  ]) async {}

  Future<dynamic> confirmPairing(
    dynamic a1, {
    dynamic relationshipType,
    dynamic code,
    dynamic sender,
    dynamic receiver,
    dynamic partner,
    dynamic user,
  }) async => null;

  Future<Couple?> fetchCouple([dynamic a1, dynamic a2]) async => null;
  Future<UserAccount?> findById([dynamic a1, dynamic a2]) async => null;
  Future<String> generatePairingCode([dynamic a1, dynamic a2]) async => '123456';
  Stream<PairingRequest?> watchIncomingRequest([dynamic a1, dynamic a2]) => Stream<PairingRequest?>.value(null);
  Future<void> acceptPairingRequest([dynamic a1, dynamic a2]) async {}
  Future<void> rejectPairingRequest([dynamic a1, dynamic a2]) async {}
}

class InMemoryPairingRepository extends PairingRepository {
  InMemoryPairingRepository([dynamic a1, dynamic a2, dynamic a3]);
}
