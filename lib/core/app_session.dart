import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/couple.dart';
import '../models/gender.dart';
import '../models/user_account.dart';
import 'auth/mock_auth_service.dart';
import 'multiplayer/game_session_repository.dart';
import 'pairing/pairing_repository.dart';

/// Estado global de la app: quién soy, con quién estoy emparejado, y los
/// servicios que el resto de las pantallas necesitan. Se provee una sola
/// vez en la raíz (ver main.dart) y se consume con `context.watch<AppSession>()`.
///
/// El dato clave para el multijugador es [myPlayerIndex]: todos los
/// motores de juego (UnoEngine, ChinchonEngine, TrucoEngine) numeran a
/// los jugadores 0/1 según quién es `couple.user1Id` / `user2Id` — ese
/// orden se fija una sola vez, al emparejar, y no vuelve a cambiar.
class AppSession extends ChangeNotifier {
  final MockAuthService authService;
  final PairingRepository pairingRepository;
  final GameSessionRepository gameSessionRepository;

  String? _googleUid;
  UserAccount? myAccount;
  UserAccount? partnerAccount;
  Couple? couple;

  StreamSubscription<UserAccount?>? _accountSub;

  AppSession({
    required this.authService,
    required this.pairingRepository,
    required this.gameSessionRepository,
  });

  bool get isSignedIn => _googleUid != null;
  bool get hasAccount => myAccount != null;
  bool get isPaired => couple != null;

  int get myPlayerIndex {
    if (couple == null || myAccount == null) return 0;
    return myAccount!.id == couple!.user1Id ? 0 : 1;
  }

  Future<void> signIn() async {
    _googleUid = await authService.signInWithGoogle();
    _listenToMyAccount();
    final existing = await authService.fetchAccount(_googleUid!);
    if (existing != null) await _onMyAccountChanged(existing);
    notifyListeners();
  }

  Future<void> completeAccountCreation({
    required String firstName,
    required String lastName,
    required int age,
    required Gender gender,
  }) async {
    final account = await authService.createAccount(
      googleUid: _googleUid!,
      firstName: firstName,
      lastName: lastName,
      age: age,
      gender: gender,
    );
    await _onMyAccountChanged(account);
  }

  /// Actualiza mi cuenta (por ejemplo, un cambio de personalización) —
  /// pasa por AuthService para que watchAccount se entere y refresque
  /// myAccount solo, en vez de tocar el campo acá directamente.
  void updateMyAccount(UserAccount updated) => authService.updateAccount(updated);

  void _listenToMyAccount() {
    _accountSub?.cancel();
    _accountSub = authService.watchAccount(_googleUid!).listen((account) {
      if (account != null) _onMyAccountChanged(account);
    });
  }

  Future<void> _onMyAccountChanged(UserAccount account) async {
    myAccount = account;
    if (account.coupleId != null && (couple == null || couple!.id != account.coupleId)) {
      final newCouple = await pairingRepository.fetchCouple(account.coupleId!);
      if (newCouple != null) {
        couple = newCouple;
        final partnerId = newCouple.user1Id == account.id ? newCouple.user2Id : newCouple.user1Id;
        partnerAccount = await pairingRepository.findById(partnerId);
      }
    }
    notifyListeners();
  }

  /// SOLO PARA DESARROLLO. El backend en memoria vive en el mismo
  /// proceso que la app, así que no hay forma de tener "dos celulares"
  /// de verdad acá. Esto permite saltar a actuar como cualquier cuenta
  /// ya creada (ver DevAccountSwitcherFab, solo visible en modo debug)
  /// para poder revisar el flujo de pairing y el multijugador desde
  /// ambas perspectivas con un solo dispositivo. No existe en la app
  /// real: en producción cada celular queda logueado siempre con SU
  /// cuenta.
  Future<void> devSignInAs(UserAccount account) async {
    _accountSub?.cancel();
    _googleUid = account.googleUid;
    couple = null;
    partnerAccount = null;
    _listenToMyAccount();
    final refreshed = await authService.fetchAccount(account.googleUid) ?? account;
    await _onMyAccountChanged(refreshed);
  }

  int _devAccountSeed = 0;

  /// Crea una cuenta de prueba con datos genéricos y salta a actuar como
  /// ella — atajo para no tener que completar el formulario de alta a
  /// mano cada vez que se quiere probar el pairing con una segunda
  /// cuenta. Solo para desarrollo, mismo criterio que [devSignInAs].
  Future<void> devCreateAndSwitchToTestAccount() async {
    _devAccountSeed++;
    final uid = 'dev-test-uid-$_devAccountSeed-${DateTime.now().millisecondsSinceEpoch}';
    final account = await authService.createAccount(
      googleUid: uid,
      firstName: 'Test$_devAccountSeed',
      lastName: 'Dev',
      age: 25,
      gender: _devAccountSeed.isEven ? Gender.male : Gender.female,
    );
    await devSignInAs(account);
  }

  void signOut() {
    _accountSub?.cancel();
    _googleUid = null;
    myAccount = null;
    partnerAccount = null;
    couple = null;
    notifyListeners();
  }
}
