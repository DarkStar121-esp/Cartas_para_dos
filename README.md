# Cartas para dos

App de juegos de cartas para parejas: clásicos (UNO, Chinchón, Escoba del 15,
Truco) + juegos de conexión (En Palabras, Conectados, Climax Club).

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22+
- Android Studio (o solo el Android SDK vía command-line tools) para compilar el APK
- Un dispositivo/emulador Android, o `flutter run -d chrome` para probar en el navegador mientras desarrollás

## Correr en desarrollo

```bash
flutter pub get
flutter run
```

## Generar el .apk

```bash
flutter build apk --release
# el archivo queda en build/app/outputs/flutter-apk/app-release.apk
```

Si no querés instalar Android Studio localmente, podés compilar en la nube con
[Codemagic](https://codemagic.io) o [EAS Build](https://docs.expo.dev/build/introduction/)
(este último es de Expo/React Native, no aplica si te quedás con Flutter — para
Flutter, Codemagic tiene un free tier y es la opción más directa).

## Probar la app de punta a punta (sin Firebase)

Desde `flutter run`, la app arranca en la pantalla de login, no en el
catálogo de juegos — ese cambió de lugar (ver MULTIPLAYER.md sección 1).
Con el backend en memoria (`MockAuthService` + `InMemoryPairingRepository`
+ `InMemoryGameSessionRepository`, ya cableados en `main.dart`) se puede
recorrer TODO el flujo desde un solo dispositivo:

1. Tocar "Continuar con Google" (no abre nada real, genera una cuenta de
   prueba al toque) y completar el alta.
2. En la pantalla de pairing, tocar el botón flotante 🐛 (abajo a la
   derecha, solo visible en modo debug) → "Crear cuenta de prueba nueva".
   Guardar o anotar el código que le tocó a esa segunda cuenta.
3. Tocar "Ingresar el código de mi pareja", pegar ese código y enviar.
4. Tocar 🐛 de nuevo y saltar a la cuenta de prueba recién creada — ahí
   va a aparecer la solicitud pendiente con el aviso de irreversibilidad.
   Aceptar y completar los datos de la relación.
5. Ya emparejados: se puede seguir usando 🐛 para saltar entre las dos
   cuentas en cualquier momento, incluso en medio de una partida, y
   revisar ambas perspectivas del multijugador (mi mano / la de mi
   pareja, quién tiene el turno, los cantos de Truco, etc).

Nada de esto reemplaza probar con dos celulares reales una vez conectado
Firebase — es solo para revisar la UI y la integración sin desplegar nada.

## Setup de Firebase (cuentas, pairing y progresión)

El sistema de cuentas descrito en `ACCOUNTS_AND_PROGRESSION.md` necesita un
proyecto de Firebase propio (no viene incluido, cada quien tiene que crear
el suyo):

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com).
2. Agregar una app Android, descargar `google-services.json` y ponerlo en
   `android/app/`.
3. Habilitar **Authentication → Sign-in method → Google**.
4. Crear una base de **Firestore** (modo producción).
5. Correr `flutterfire configure` (requiere el paquete `flutterfire_cli`)
   para generar `lib/firebase_options.dart` automáticamente.
6. Implementar contra Firebase, sin tocar el resto de la app (todo está
   detrás de interfaces para esto):
   - `AuthService` (`lib/core/auth/auth_service.dart`) — reemplaza `MockAuthService`.
   - `PairingRepository` (`lib/core/pairing/pairing_repository.dart`) — reemplaza `InMemoryPairingRepository`.
   - `GameSessionRepository` para el multijugador — ya tiene una implementación
     de referencia (`FirestoreGameSessionRepository`, en
     `lib/core/multiplayer/game_session_repository.dart`); revisarla contra
     un proyecto real antes de confiar en ella a ciegas. Reemplaza
     `InMemoryGameSessionRepository` en `main.dart`.
   - Ver MULTIPLAYER.md para el detalle de cómo encajan estas tres piezas.
7. Desplegar `functions/dailyProgressionTick.ts` (requiere `firebase init
   functions` y `firebase deploy --only functions`).

## Cartas ilustradas

Truco y Chinchón comparten la baraja española (`lib/games/shared/spanish_deck.dart`)
y el mismo widget de carta (`lib/widgets/cards/spanish_card_face.dart`). El
dibujo de cada carta (palos, pips, figuras) está hecho con `CustomPainter` —
o sea, es arte vectorial propio generado en código, no imágenes bajadas de
internet. Eso evita cualquier problema de derechos de autor con mazos
españoles existentes (Fournier y similares) y además hace que las cartas
se vean nítidas en cualquier tamaño de pantalla sin pesar nada en assets.
Las animaciones (`lib/widgets/cards/card_animations.dart`) son igual de
reutilizables: flip 3D al robar, entrada escalonada al repartir la mano, y
un "pop" de escala al jugar una carta a la mesa.

## Estado actual

| Juego | Estado |
|---|---|
| UNO | ✅ Jugable — multijugador real entre 2 celulares (ver MULTIPLAYER.md) |
| En Palabras | ✅ Jugable — multijugador con roles (describe/adivina) |
| Chinchón | ✅ Jugable — multijugador; simplificaciones en el header de `chinchon_engine.dart` |
| Truco | ✅ Jugable — multijugador 1 contra 1; envido/truco simplificados, sin Flor, ver header de `truco_engine.dart` |
| Escoba del 15 | 🚧 Módulo registrado, falta motor de reglas |
| Conectados | 🚧 Módulo registrado, falta contenido y pantalla |
| Climax Club | 🚧 Módulo registrado, falta contenido y pantalla |
| Login (Google) + alta de cuenta | ✅ Flujo completo con `MockAuthService`; falta conectar Firebase real |
| Pairing (código / WiFi) | ✅ Flujo completo (solicitud → aviso irreversible → confirmación) con `InMemoryPairingRepository`; WiFi sin implementar; falta Firebase real |
| Multijugador (sincronización entre celulares) | ✅ Arquitectura completa (`GameSyncController` + `GameSessionRepository`), ver MULTIPLAYER.md; falta Firebase real para jugar en 2 celulares de verdad |
| Perfil (ver progresión) | ✅ Pantalla completa: avatares, nivel/XP/racha, victorias/apodos, acceso a personalización |
| Progresión (XP, niveles, racha) | ✅ Lógica pura completa y testeable (`XpService`); falta el cron server-side |
| Personalización (avatares/fuentes/banners) | ✅ Modelo + UI completos; faltan los assets de arte de los animales |
| Victorias/derrotas y apodos | ✅ Lógica completa (`NicknameService`) + widget (`CoupleStatusCard`) |

## Cómo agregar un juego nuevo

1. Creá una carpeta en `lib/games/classic/` o `lib/games/couples/`.
2. Si el juego tiene reglas de mesa, separá la lógica pura (sin Flutter) en un
   `*_engine.dart`, como `uno_engine.dart`. Esto te permite testearlo sin UI.
3. Si el juego usa mazos de contenido (preguntas, frases), poné los datos en
   un JSON dentro de `assets/data/` y cargalo con un `*_deck.dart`, como
   `en_palabras_deck.dart`. Así podés editar/agregar cartas sin tocar Dart.
4. Armá la pantalla (`*_screen.dart`) que consume el engine o el deck.
5. Creá el `*_module.dart` implementando `GameModule` (ver `core/game_module.dart`).
6. Agregalo a la lista en `core/game_registry.dart`. Listo, ya aparece en el catálogo.

Ver `ARCHITECTURE.md` para las decisiones de fondo (por qué Flutter, manejo de
estado, contenido adulto, roadmap de multijugador online, etc).
