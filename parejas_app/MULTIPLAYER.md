# Multijugador, login y perfil

Este documento cubre tres cosas que se agregaron sobre la base de
`ACCOUNTS_AND_PROGRESSION.md` y `ARCHITECTURE.md`: la pantalla inicial
(login → alta de cuenta → pairing → app), el multijugador real entre dos
celulares, y el apartado de perfil.

## 1. Flujo de pantallas (AppRoot)

`lib/screens/app_root.dart` decide qué mostrar mirando el estado de
`AppSession` (`lib/core/app_session.dart`), que se provee una sola vez en
la raíz de la app (`main.dart`) con `ChangeNotifierProvider`:

```
sin sesión           → SignInScreen (login con Google)
logueado sin cuenta   → CreateAccountScreen (nombre, apellido, edad, sexo)
con cuenta sin pareja → PairingFlowScreen (código / WiFi, sección 3)
emparejado            → MainShell (bottom nav: Juegos / Perfil)
```

`AppSession` no solo guarda `myAccount`/`couple`, hace algo más
importante: se **suscribe a los cambios de su propia cuenta**
(`AuthService.watchAccount`). Esto es lo que resuelve un problema real
del pairing: quien MANDA la solicitud de conexión no está mirando la
pantalla de quien la confirma, así que necesita enterarse solo de que ya
lo emparejaron. En vez de inventar un canal aparte para eso, alcanza con
mirar la propia cuenta: en cuanto le aparece un `coupleId`, `AppSession`
busca la pareja (`PairingRepository.fetchCouple`) y a la cuenta de la
pareja, y notifica — `AppRoot` reacciona solo y navega a `MainShell`.

## 2. Multijugador entre dos celulares

### La pieza central: sessionId determinístico

Cada partida entre la pareja es un `GameSession`
(`lib/core/multiplayer/game_session.dart`) identificado por:

```dart
String buildGameSessionId(String coupleId, String gameId) => '${coupleId}_$gameId';
```

Nada de "crear una sala" ni compartir un código de partida: como los dos
celulares ya conocen su `coupleId` (viene de `AppSession.couple`), los
dos calculan el mismo id sin coordinarse. El primero en entrar al juego
lo crea; el segundo simplemente lo encuentra ya creado.

### GameSessionRepository — el transporte

`lib/core/multiplayer/game_session_repository.dart` es la interfaz que
sincroniza el JSON de cualquier motor entre los dos dispositivos:

- `InMemoryGameSessionRepository`: para desarrollar sin Firebase. **Ojo:**
  vive en el mismo proceso — sirve para revisar toda la UI y probar la
  lógica con el selector de cuentas de desarrollo (sección 4), pero NO
  sincroniza entre dos celulares de verdad.
- `FirestoreGameSessionRepository`: la implementación real, un documento
  por partida en `game_sessions/{sessionId}`, sincronizado en tiempo real
  con `.snapshots()`. Está escrita como referencia (no se pudo probar
  contra un proyecto de Firebase real en este entorno) — revisarla contra
  un dispositivo antes de confiar en ella a ciegas.

### GameSyncController — el pegamento con cada motor

`lib/core/multiplayer/game_sync_controller.dart` es genérico
(`GameSyncController<E>`) y conecta CUALQUIER motor que tenga
`toJson()`/`fromJson()` con el repositorio. Cada pantalla de juego lo usa
así:

```dart
final controller = GameSyncController<UnoEngine>(
  repository: session.gameSessionRepository,
  sessionId: buildGameSessionId(couple.id, 'uno'),
  coupleId: couple.id,
  gameId: 'uno',
  myPlayerIndex: session.myPlayerIndex,
  decode: UnoEngine.fromJson,
  encode: (e) => e.toJson(),
);
await controller.connect(buildInitialState: () => UnoEngine(2));
controller.stream.listen((engine) => setState(() => _engine = engine));

// al jugar:
controller.act((engine) => engine.playCard(myIndex, card));
```

`act()` aplica la jugada al motor local, actualiza la UI al instante, y
publica el JSON completo. `replaceState()` es la variante para "jugar de
nuevo" (una partida nueva de cero, no una jugada sobre la actual).

### Por qué se manda el estado ENTERO y no "diffs"

Los motores (`UnoEngine`, `ChinchonEngine`, `TrucoEngine`) barajan una
sola vez, al arrancar la mano/ronda (`Random()`). A partir de ahí, cada
jugada es determinística (sacar de una lista, agregar a otra). Como
**solo publica quien hizo la jugada**, y el otro dispositivo nunca corre
lógica propia — solo reemplaza su copia entera con lo que llega — los dos
lados nunca pueden divergir por una tirada de dados que corrió distinto
en cada uno. Es la razón por la que `toJson()` de cada motor serializa
TODO (mazo, pozo, manos, puntajes), no solo "lo que cambió".

### Perspectiva: "mi mano" vs "la mano de mi pareja"

`AppSession.myPlayerIndex` es 0 si `myAccount.id == couple.user1Id`, si no
es 1 — un valor fijo desde que se emparejaron, no depende de turnos. Cada
pantalla de juego:

- Muestra SIEMPRE `engine.hands[myPlayerIndex]` como la mano interactiva
  de abajo (nunca "la mano de quien tiene el turno", como en la versión
  vieja de pasar-y-jugar).
- Muestra la cantidad de cartas de `engine.hands[1 - myPlayerIndex]` boca
  abajo (con `SpanishCardBack`), nunca su contenido.
- Habilita las acciones solo si `engine.currentPlayer == myPlayerIndex`
  (o el campo de turno correspondiente en Truco/Chinchón), mostrando
  "Esperando a tu pareja…" en caso contrario.
- **Ojo con los cantos de Truco**: si YO canté Envido/Truco, mi propia
  pantalla no puede mostrarme el botón "Quiero/No quiero" — ese lo tiene
  que ver únicamente mi pareja. Cada pantalla chequea
  `engine.envidoCallerId == myIndex` / `trucoCallerId == myIndex` antes
  de dibujar la barra de respuesta.

### En Palabras: un caso distinto (roles, no cartas)

No tiene un "motor" de reglas — es un estado más simple
(`EnPalabrasSession`) con quién describe, el mazo ya barajado (viaja
completo en el JSON por la misma razón que los mazos de cartas: si cada
celular lo barajara por su cuenta, verían palabras distintas) y si la
ronda está activa. El cronómetro NO se sincroniza segundo a segundo (sería
tráfico de red innecesario): se sincroniza `roundStartedAt` una sola vez
al arrancar, y cada dispositivo calcula localmente cuánto falta. Solo el
dispositivo de quien describe finaliza la ronda cuando se acaba el
tiempo, para que los dos no se pisen escribiendo al mismo tiempo.

## 3. Recomendaciones para la implementación real (Firestore)

- Guardar cada partida en `game_sessions/{coupleId}_{gameId}` (el mismo id
  determinístico). Reglas de seguridad: solo pueden leer/escribir los dos
  usuarios cuyo `coupleId` coincide con el del documento.
- El estado de cuentas (`UserAccount`) también necesita su versión de
  `watchAccount` con `.doc(uid).snapshots()` — es lo que hace que el
  pairing y (a futuro) los intercambios de animales o cambios de
  personalización del otro se reflejen solos.
- Limitación conocida de "último que escribe gana": si los dos
  dispositivos publican casi al mismo tiempo se pisan sin fusionarse. No
  debería pasar en un juego por turnos bien implementado (las pantallas
  ya deshabilitan las acciones cuando no es tu turno), pero conviene
  tenerlo en mente si aparecen bugs de sincronización raros.

## 4. Herramienta de desarrollo: selector de cuentas

Como el backend en memoria vive en un solo proceso, no hay forma de
probar "dos celulares" de verdad sin Firebase desplegado. Mientras tanto,
`DevAccountSwitcherFab` (botón flotante 🐛, **solo visible en
`kDebugMode`**, desaparece solo en release) deja:

1. Crear cuentas de prueba con un toque.
2. Saltar a "ser" cualquier cuenta ya creada — incluso en medio de una
   partida, para revisar ambas perspectivas del multijugador (mi mano
   / la de mi pareja, los cantos de Truco, etc.) desde un solo
   dispositivo.

No existe nada parecido en la app real: en producción cada celular queda
logueado siempre con su propia cuenta.

## 5. Apartado de perfil

`lib/screens/profile/profile_screen.dart` (pestaña "Perfil" del bottom
nav) muestra:

- El avatar de los dos (`ProfileAvatar`, `lib/widgets/profile/avatar_widget.dart`):
  silueta o animal equipado, fondo azul/rosa según sexo, tipografía y
  color de banner elegidos — toda la personalización desbloqueada en un
  solo lugar.
- Nivel, XP, racha, victorias/derrotas y apodos (`CoupleStatusCard`,
  reutilizado tal cual del sistema de progresión).
- Un acceso a `CustomizeProfileScreen` (ya existía) para efectivamente
  cambiar avatar/tipografía/banner y proponer intercambios de animales.
- Los datos de la relación (tipo y desde cuándo).

Pendiente documentado en el propio código: la propuesta de intercambio de
animales (`onProposeTrade`) todavía no tiene un canal de notificación en
tiempo real como el de las solicitudes de pairing — es del mismo tipo de
trabajo que `watchAccount`/`watchIncomingRequest`, queda como siguiente
paso natural una vez que haya un backend real.
