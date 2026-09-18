class PairingRequest {
  final String id;
  final dynamic sender;
  final String code;
  final dynamic relationshipType;
  final String? customFromUserId;

  PairingRequest({
    this.id = '',
    this.sender,
    this.code = '',
    this.relationshipType,
    String? fromUserId,
  }) : customFromUserId = fromUserId;

  String get fromUserId => customFromUserId ?? (sender is String ? sender : sender?.id ?? '');
}
