import 'dart:async';
import '../../models/gender.dart';
import '../../models/user_account.dart';
import 'auth_service.dart';

/// Implementación 100% en memoria de [AuthService] — simula un login de
/// Google instantáneo y guarda las cuentas creadas en un mapa. Sirve
/// para desarrollar y probar todo el flujo de la app (login → alta de
/// cuenta → pairing → juegos) sin tener un proyecto de Firebase armado
/// todavía. Para producción, reemplazar por una implementación real con
/// firebase_auth + google_sign_in (ver README.md).
class MockAuthService implements AuthService {
  final Map<String, UserAccount> _accountsByUid = {};
  final Map<String, StreamController<UserAccount?>> _accountControllers = {};
  final _authController = StreamController<String?>.broadcast();
  String? _currentUid;
  int _uidCounter = 0;

  @override
  Stream<String?> get authStateChanges => _authController.stream;

  @override
  Future<String> signInWithGoogle() async {
    // En la vida real esto abre el picker nativo de cuentas de Google.
    // Acá, cada "login" simulado genera un uid nuevo la primera vez —
    // suficiente para probar la pantalla de alta de cuenta.
    _uidCounter++;
    _currentUid = 'mock-uid-$_uidCounter';
    _authController.add(_currentUid);
    return _currentUid!;
  }

  @override
  Future<void> signOut() async {
    _currentUid = null;
    _authController.add(null);
  }

  @override
  Future<UserAccount> createAccount({
    required String googleUid,
    required String firstName,
    required String lastName,
    required int age,
    required Gender gender,
  }) async {
    final account = UserAccount(
      id: 'user-$googleUid',
      pairingCode: _generatePairingCode(),
      googleUid: googleUid,
      firstName: firstName,
      lastName: lastName,
      age: age,
      gender: gender,
      createdAt: DateTime.now(),
    );
    _accountsByUid[googleUid] = account;
    _notifyAccount(account);
    return account;
  }

  @override
  Future<UserAccount?> fetchAccount(String uid) async => _accountsByUid[uid];

  @override
  Stream<UserAccount?> watchAccount(String uid) {
    final controller = _accountControllers.putIfAbsent(uid, () => StreamController<UserAccount?>.broadcast());
    Future.microtask(() => controller.add(_accountsByUid[uid]));
    return controller.stream;
  }

  /// Búsquedas síncronas que necesita InMemoryPairingRepository — como
  /// todas las cuentas viven en este mismo mapa en memoria, no hace
  /// falta duplicar el registro en otro lado (ver pairing_repository.dart).
  UserAccount? findByPairingCode(String code) {
    for (final a in _accountsByUid.values) {
      if (a.pairingCode == code) return a;
    }
    return null;
  }

  UserAccount? findById(String userId) {
    for (final a in _accountsByUid.values) {
      if (a.id == userId) return a;
    }
    return null;
  }

  /// Solo para el selector de cuentas de desarrollo (DevAccountSwitcherFab).
  List<UserAccount> get allAccounts => _accountsByUid.values.toList();

  /// Sobreescribe la cuenta guardada (por ejemplo, después de emparejar
  /// o de cambiar la personalización) — no forma parte de la interfaz
  /// [AuthService] porque las implementaciones reales normalmente
  /// escriben directo a Firestore desde donde corresponda, pero acá
  /// hace falta un lugar donde guardar el cambio en memoria.
  void updateAccount(UserAccount account) {
    _accountsByUid[account.googleUid] = account;
    _notifyAccount(account);
  }

  void _notifyAccount(UserAccount account) {
    _accountControllers[account.googleUid]?.add(account);
  }

  String _generatePairingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(rand ~/ (i + 1)) % chars.length]).join();
  }
}
