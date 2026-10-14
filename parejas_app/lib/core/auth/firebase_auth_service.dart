import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/gender.dart';
import '../../models/user_account.dart';
import 'auth_service.dart';

/// Implementación real de [AuthService]: login con Google
/// (google_sign_in) + Firebase Auth para la sesión + Firestore para
/// guardar la cuenta. Reemplaza a MockAuthService una vez que el
/// proyecto de Firebase está configurado — ver FIREBASE_SETUP.md.
///
/// Los documentos de cuenta viven en `users/{uid}`, usando el mismo uid
/// de Firebase Auth como [UserAccount.id] — a diferencia de
/// MockAuthService (que generaba un id interno separado), acá no hace
/// falta mantener dos identificadores distintos para la misma persona.
class FirebaseAuthService implements AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  @override
  Stream<String?> get authStateChanges => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<String?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // La persona cerró el selector de cuenta sin elegir ninguna — no
      // es un error, AppSession simplemente se queda en la pantalla de
      // login y no pasa nada más.
      return null;
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      // Si esto pasa, casi siempre es porque el SHA-1/SHA-256 todavía
      // no estaba cargado en Firebase cuando se generó el
      // google-services.json actual — hace falta volver a correr
      // `flutterfire configure` (o re-descargar el archivo) DESPUÉS de
      // cargar las huellas. Ver FIREBASE_SETUP.md, sección de
      // problemas comunes.
      throw StateError(
        'Google no devolvió un idToken. Revisá que el SHA-1/SHA-256 esté '
        'cargado en Firebase y que google-services.json sea posterior a eso '
        '(ver FIREBASE_SETUP.md).',
      );
    }

    final credential = fb_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final uid = result.user?.uid;
    if (uid == null) {
      throw StateError('No se pudo iniciar sesión con Google.');
    }
    return uid;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
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
      id: googleUid,
      pairingCode: await _generateUniquePairingCode(),
      googleUid: googleUid,
      firstName: firstName,
      lastName: lastName,
      age: age,
      gender: gender,
      createdAt: DateTime.now(),
    );
    await _users.doc(googleUid).set(account.toJson());
    return account;
  }

  @override
  Future<UserAccount?> fetchAccount(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserAccount.fromJson(doc.data()!);
  }

  @override
  Stream<UserAccount?> watchAccount(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.exists ? UserAccount.fromJson(doc.data()!) : null);
  }

  @override
  void updateAccount(UserAccount account) {
    // No esperamos el Future a propósito: AppSession ya actualiza su
    // estado local vía optimistic update en el caller, y watchAccount
    // va a confirmar el cambio cuando Firestore lo propague. Si hiciera
    // falta manejar errores de escritura, es acá donde enganchar eso.
    _users.doc(account.googleUid).set(account.toJson());
  }

  /// Genera un código de 6 caracteres y reintenta si por mala suerte ya
  /// lo tiene otra cuenta (con el alfabeto usado, es extremadamente
  /// improbable, pero mejor no confiar ciegamente).
  Future<String> _generateUniquePairingCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin 0/O/1/I para no confundir al tipear
    for (var attempt = 0; attempt < 5; attempt++) {
      final seed = DateTime.now().microsecondsSinceEpoch + attempt;
      final code = List.generate(6, (i) => chars[(seed ~/ (i + 1) + i * 7) % chars.length]).join();
      final existing = await _users.where('pairingCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    throw StateError('No se pudo generar un código único, intentar de nuevo.');
  }
}
