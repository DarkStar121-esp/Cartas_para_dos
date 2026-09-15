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
6. Implementar `AuthService` (`lib/core/auth/auth_service.dart`) y
   `PairingRepository` (`lib/core/pairing/pairing_repository.dart`) contra
   Firebase — hoy son interfaces con TODOs, están pensadas para poder
   desarrollar y probar toda la UI antes de tener el proyecto de Firebase
   armado.
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
| UNO | ✅ Jugable (pasar y jugar, 2 jugadores) |
| En Palabras | ✅ Jugable (contrarreloj) |
| Chinchón | ✅ Jugable (pasar y jugar, 2 jugadores) — ver simplificaciones en el header de `chinchon_engine.dart` |
| Truco | ✅ Jugable (1 contra 1) — envido/truco simplificados, sin Flor; ver header de `truco_engine.dart` |
| Escoba del 15 | 🚧 Módulo registrado, falta motor de reglas |
| Conectados | 🚧 Módulo registrado, falta contenido y pantalla |
| Climax Club | 🚧 Módulo registrado, falta contenido y pantalla |
| Cuentas (alta, Google Sign-In) | 🚧 UI y modelo listos, falta conectar Firebase (`AuthService`) |
| Pairing (código / WiFi) | 🚧 UI y modelo listos, falta conectar Firebase (`PairingRepository`); WiFi sin implementar |
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
