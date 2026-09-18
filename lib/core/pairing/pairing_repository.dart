import 'dart:async';
import 'pairing_models.dart';
import '../../models/user_account.dart';

abstract class PairingRepository {
  Future<String> createPairingCode();
  Future<PairingResult> pairWithCode(String code);
  Stream<PairingStatus> watchPairingStatus();
  Stream<UserAccount> discoverOnLocalNetwork();
  Future<void> confirmPairing(
    dynamic pairingId, {
    dynamic relationshipType,
    DateTime? relationshipStartDate,
    dynamic type,
    String? id,
  });
  Future<void> sendPairingRequest(dynamic myId, dynamic code);
  Stream<PairingRequest?> watchIncomingRequest(dynamic userId);
  Future<UserAccount?> findById(dynamic userId);
  Future<dynamic> fetchCouple(dynamic coupleId);
}

class InMemoryPairingRepository implements PairingRepository {
  final dynamic authService;
  InMemoryPairingRepository([this.authService]);

  final _statusController = StreamController<PairingStatus>.broadcast();

  @override
  Future<String> createPairingCode() async => '123456';

  @override
  Future<PairingResult> pairWithCode(String code) async => PairingResult.success();

  @override
  Stream<PairingStatus> watchPairingStatus() => _statusController.stream;

  @override
  Stream<UserAccount> discoverOnLocalNetwork() => const Stream.empty();

  @override
  Future<void> confirmPairing(
    dynamic pairingId, {
    dynamic relationshipType,
    DateTime? relationshipStartDate,
    dynamic type,
    String? id,
  }) async {}

  @override
  Future<void> sendPairingRequest(dynamic myId, dynamic code) async {}

  @override
  Stream<PairingRequest?> watchIncomingRequest(dynamic userId) => const Stream.empty();

  @override
  Future<UserAccount?> findById(dynamic userId) async => null;

  @override
  Future<dynamic> fetchCouple(dynamic coupleId) async => null;
}
