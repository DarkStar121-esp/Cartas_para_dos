import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_session.dart';
import '../../core/pairing/pairing_models.dart';
import '../../models/relationship_type.dart';
import 'confirm_pairing_dialog.dart';
import 'my_code_screen.dart';
import 'relationship_details_screen.dart';

/// Envuelve [MyCodeScreen] con la parte "invisible" del pairing: escuchar
/// si llega una solicitud, mostrar el aviso de irreversibilidad, pedir
/// los datos de la relación, y confirmar. Una vez confirmado, AppSession
/// se entera solo (vía AuthService.watchAccount) y AppRoot navega a
/// MainShell — esta pantalla no necesita hacer nada más después de
/// llamar a confirmPairing.
class PairingFlowScreen extends StatefulWidget {
  const PairingFlowScreen({super.key});

  @override
  State<PairingFlowScreen> createState() => _PairingFlowScreenState();
}

class _PairingFlowScreenState extends State<PairingFlowScreen> {
  StreamSubscription<PairingRequest?>? _sub;
  bool _handlingRequest = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<AppSession>();
    _sub = session.pairingRepository.watchIncomingRequest(session.myAccount!.id).listen((req) {
      if (req != null && !_handlingRequest) _handleIncoming(req);
    });
  }

  Future<void> _handleIncoming(PairingRequest request) async {
    _handlingRequest = true;
    final session = context.read<AppSession>();
    final fromAccount = await session.pairingRepository.findById(request.fromUserId);
    if (fromAccount == null) {
      _handlingRequest = false;
      return;
    }

    final accepted = await showIrreversiblePairingWarning(context, partnerName: fromAccount.fullName);
    if (!accepted || !mounted) {
      _handlingRequest = false;
      return;
    }

    final picked = await Navigator.push<_RelationshipPick>(
      context,
      MaterialPageRoute(
        builder: (_) => RelationshipDetailsScreen(
          partnerName: fromAccount.fullName,
          onConfirm: (type, date) => Navigator.pop(context, _RelationshipPick(type, date)),
        ),
      ),
    );
    if (picked == null) {
      _handlingRequest = false;
      return;
    }

    await session.pairingRepository.confirmPairing(
      request,
      relationshipType: picked.type,
      relationshipStartDate: picked.date,
    );
    // No hace falta hacer nada más acá: confirmPairing actualiza la
    // cuenta de los dos vía authService.updateAccount, y AppSession está
    // escuchando watchAccount(miUid) — se entera solo y notifica a
    // AppRoot para que navegue a MainShell.
  }

  Future<void> _sendRequest(String code) async {
    final session = context.read<AppSession>();
    await session.pairingRepository.sendPairingRequest(session.myAccount!.id, code);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    return MyCodeScreen(me: session.myAccount!, onSendRequest: _sendRequest);
  }
}

class _RelationshipPick {
  final RelationshipType type;
  final DateTime date;
  _RelationshipPick(this.type, this.date);
}
