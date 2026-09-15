import '../../models/gender.dart';
import '../../models/user_account.dart';

/// Contrato de autenticación + alta de cuenta. La implementación real usa
/// firebase_auth (con el provider de Google) + Firestore para guardar el
/// UserAccount. Requiere: crear un proyecto de Firebase, agregar
/// google-services.json (Android), y habilitar el proveedor "Google" en
/// Firebase Auth — ver README.md.
abstract class AuthService {
  /// Emite el uid de Firebase logueado, o null si no hay sesión activa.
  Stream<String?> get authStateChanges;

  /// Dispara el flujo nativo de Google Sign-In y devuelve el uid.
  Future<String> signInWithGoogle();

  Future<void> signOut();

  /// Alta de cuenta — se llama una sola vez, después del primer login,
  /// si todavía no existe un UserAccount para ese uid.
  Future<UserAccount> createAccount({
    required String googleUid,
    required String firstName,
    required String lastName,
    required int age,
    required Gender gender,
  });

  Future<UserAccount?> fetchAccount(String uid);
}
