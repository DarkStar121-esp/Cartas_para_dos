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

  /// Dispara el flujo nativo de Google Sign-In y devuelve el uid, o
  /// `null` si la persona cerró el selector de cuenta sin elegir
  /// ninguna (cancelar no es un error, no hay que mostrar nada feo por
  /// eso). Cualquier otra falla (red, configuración de Firebase mal
  /// hecha, etc.) sí se lanza como excepción.
  Future<String?> signInWithGoogle();

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

  /// Emite la cuenta cada vez que cambia (pairing confirmado, cambios de
  /// personalización hechos desde este mismo dispositivo, etc). Es lo
  /// que le permite a AppSession enterarse de que un pairing se
  /// confirmó sin que la pantalla que lo originó tenga que hacer nada
  /// manualmente — ver core/app_session.dart.
  Stream<UserAccount?> watchAccount(String uid);

  /// Actualiza una cuenta ya existente (cambios de personalización, o
  /// setear coupleId al confirmar un pairing). Reemplaza el documento
  /// entero — UserAccount.toJson() ya serializa todos los campos, así
  /// que no hace falta un "patch" parcial.
  void updateAccount(UserAccount account);
}
