class PairingRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String code;

  PairingRequest({
    required this.id,
    required this.fromUserId,
    String? fromUserName,
    String? fromName,
    this.code = '',
  }) : fromUserName = fromUserName ?? fromName ?? 'Usuario';

  String get fromName => fromUserName;
}

class PairingResult {
  final bool isSuccess;
  final String? errorMessage;

  PairingResult.success() : isSuccess = true, errorMessage = null;
  PairingResult.error(this.errorMessage) : isSuccess = false;
}
