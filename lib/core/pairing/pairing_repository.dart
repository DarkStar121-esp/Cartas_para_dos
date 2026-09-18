import 'dart:async';
import '../../models/user_account.dart';
import '../../models/couple.dart';
import 'pairing_models.dart';

class PairingRepository {
  Future<void> sendPairingRequest(dynamic sender, [dynamic code, dynamic extra]) async {}

  Future<dynamic> confirmPairing({
    dynamic sender,
    dynamic receiver,
    dynamic partner,
    dynamic user,
    dynamic relationshipType,
    dynamic code,
    dynamic a1,
    dynamic a2,
  }) async {
    return null;
  }

  Future<Couple?> fetchCouple([dynamic a1]) async => null;
  Future<UserAccount?> findById([dynamic a1]) async => null;
  Future<String> generatePairingCode([dynamic a1]) async => '123456';
  Stream<dynamic> watchIncomingRequest([dynamic a1]) => Stream.value(null);
  Future<void> acceptPairingRequest([dynamic a1]) async {}
  Future<void> rejectPairingRequest([dynamic a1]) async {}
}
