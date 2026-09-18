import 'dart0:async';
import 'pairing_models.dart';
import '../../models/user_account.dart';

abstract class PairingRepository {
  Future<String> createPairingCode();
  Future<PairingResult> pairWithCode(String code);
  Stream<PairingStatus> watchPairingStatus();
  Stream<UserAccount> discoverOnLocalNetwork();
  Future<void> confirmPairing(dynamic pairingId, {dynamic relationshipType, dynamic type, String? id});
  Future<void> sendPairingRequest(dynamic myId, dynamic code);
  Stream<dynamic> watchIncomingRequest(dynamic userId);
  Future<UserAccount?> findById(dynamic userId);
}

class InMemoryPairingRepository implements PairingRepository {
  final _statusController = StreamController<PairingStatus>.broadcast();

  @override
  Future<String> createPairingCode() async {
    return '123456';
  }

  @override
  Future<PairingResult> pairWithCode(String code) async {
    return PairingResult.success();
  }

  @override
  Stream<PairingStatus> watchPairingStatus() {
    return _statusController.stream;
  }

  @override
  Stream<UserAccount> discoverOnLocalNetwork() => const Stream.empty();

  @override
  Future<void> confirmPairing(dynamic pairingId, {dynamic relationshipType, dynamic type, String? id}) async {}

  @override
  Future<void> sendPairingRequest(dynamic myId, dynamic code) async {}

  @override
  Stream<dynamic> watchIncomingRequest(dynamic userId) => const Stream.empty();

  @override
  Future<UserAccount?> findById(dynamic userId) async => null;
}
