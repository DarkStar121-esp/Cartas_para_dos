import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_session.dart';
import 'core/auth/mock_auth_service.dart';
import 'core/multiplayer/game_session_repository.dart';
import 'core/pairing/pairing_repository.dart';
import 'screens/app_root.dart';

void main() {
  runApp(const ParejasApp());
}

class ParejasApp extends StatelessWidget {
  const ParejasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSession>(
      // Wiring de desarrollo: todo en memoria, en un solo proceso. Para
      // producción, reemplazar MockAuthService por una implementación
      // con firebase_auth + google_sign_in, InMemoryPairingRepository
      // por una con Firestore, e InMemoryGameSessionRepository por
      // FirestoreGameSessionRepository (ya escrita, ver
      // core/multiplayer/game_session_repository.dart) — todo detrás de
      // las mismas interfaces, así que el resto de la app no cambia.
      create: (_) {
        final authService = MockAuthService();
        return AppSession(
          authService: authService,
          pairingRepository: InMemoryPairingRepository(authService),
          gameSessionRepository: InMemoryGameSessionRepository(),
        );
      },
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
}
