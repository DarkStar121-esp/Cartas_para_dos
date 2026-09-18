import '../../models/relationship_type.dart';

enum PairingStatus { none, pending, paired }

class PairingRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String code;
  final DateTime createdAt;

  PairingRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.code,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class PairingResult {
  final bool isSuccess;
  final String? errorMessage;

  PairingResult({required this.isSuccess, this.errorMessage});

  factory PairingResult.success() => PairingResult(isSuccess: true);
  factory PairingResult.failure(String message) => PairingResult(isSuccess: false, errorMessage: message);
}
