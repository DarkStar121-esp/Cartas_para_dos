import 'dart:async';
import 'pairing_models.dart';
import '../../models/user_account.dart';

abstract class PairingRepository {
  Future<String> createPairingCode();
  Future<PairingResult> pairWithCode(String code);
  Stream<PairingStatus> watchPairingStatus();
  Stream<UserAccount> discoverOnLocalNetwork();
  Future<void> confirmPairing(dynamic pairingId);
  Future<void> sendPairingRequest(String myId, String code);
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
  Future<void> confirmPairing(dynamic pairingId) async {}

  @override
  Future<void> sendPairingRequest(String myId, String code) async {}
}
