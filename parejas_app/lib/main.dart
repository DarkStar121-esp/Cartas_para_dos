import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_session.dart';
import 'core/auth/firebase_auth_service.dart';
import 'core/auth/mock_auth_service.dart';
import 'core/multiplayer/game_session_repository.dart';
import 'core/pairing/firestore_pairing_repository.dart';
import 'core/pairing/pairing_repository.dart';
import 'firebase_options.dart';
import 'screens/app_root.dart';

/// Cambiar a `true` una vez que Firebase esté configurado (ver
/// FIREBASE_SETUP.md, en particular el paso 4: `flutterfire configure`).
/// Mientras esté en `false`, la app corre 100% en memoria y sin
/// conexión a internet — sirve para desarrollar la UI sin depender de
/// un proyecto de Firebase armado, pero los dos celulares NO se ven
/// entre sí de verdad (ver el selector de cuentas 🐛 para probar el
/// flujo igual, desde un solo dispositivo).
const bool useFirebase = false;

void main() async {
  if (useFirebase) {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const ParejasApp());
}

class ParejasApp extends StatelessWidget {
  const ParejasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSession>(
      create: (_) => useFirebase ? _buildFirebaseSession() : _buildMockSession(),
      child: MaterialApp(
        title: 'Cartas para dos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const AppRoot(),
      ),
    );
  }

  AppSession _buildFirebaseSession() {
    return AppSession(
      authService: FirebaseAuthService(),
      pairingRepository: FirestorePairingRepository(),
      gameSessionRepository: FirestoreGameSessionRepository(FirebaseFirestore.instance),
    );
  }

  AppSession _buildMockSession() {
    final authService = MockAuthService();
    return AppSession(
      authService: authService,
      pairingRepository: InMemoryPairingRepository(authService),
      gameSessionRepository: InMemoryGameSessionRepository(),
    );
  }
}
