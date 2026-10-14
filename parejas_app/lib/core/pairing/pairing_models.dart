enum PairingRequestStatus { pending, accepted, expired }

/// Una solicitud de conexión entre dos cuentas. Vive en el backend
/// (Firestore) hasta que el destinatario la confirma o expira.
class PairingRequest {
  final String id;
  final String fromUserId;
  final String toPairingCode;
  final DateTime createdAt;
  final PairingRequestStatus status;

  const PairingRequest({
    required this.id,
    required this.fromUserId,
    required this.toPairingCode,
    required this.createdAt,
    this.status = PairingRequestStatus.pending,
  });

  PairingRequest copyWith({PairingRequestStatus? status}) => PairingRequest(
        id: id,
        fromUserId: fromUserId,
        toPairingCode: toPairingCode,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
