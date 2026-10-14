# Conectar Firebase (para que el multijugador funcione por internet)

Hasta ahora la app corre 100% en memoria (`MockAuthService` +
`InMemoryPairingRepository` + `InMemoryGameSessionRepository`) — sirve
para probar toda la UI con el selector de cuentas 🐛, pero los dos
celulares no se ven entre sí de verdad. Esta guía conecta las
implementaciones reales que ya están escritas (`FirebaseAuthService`,
`FirestorePairingRepository`, `FirestoreGameSessionRepository`) contra un
proyecto de Firebase real.

## Paso 1 — Crear el proyecto

1. Entrar a [Firebase Console](https://console.firebase.google.com) →
   "Agregar proyecto" → seguir el asistente (el nombre no importa, ej.
   "cartas-para-dos").
2. Cuando pregunte por Google Analytics, se puede desactivar — no hace
   falta para esta app.

## Paso 2 — Agregar la app Android

1. Dentro del proyecto, ícono de Android → "Agregar app".
2. **Nombre del paquete**: tiene que coincidir EXACTO con el
   `applicationId` de `android/app/build.gradle` de tu proyecto (algo
   tipo `com.tuusuario.parejas_app`). Si todavía no armaste esa carpeta
   `android/` (este zip solo trae el código Dart de `lib/`), corré
   primero `flutter create .` en la raíz del proyecto para que Flutter
   genere `android/` e `ios/` — así el paquete queda definido.
3. **SHA-1 y SHA-256** — las dos, no alcanza con una sola:
   ```bash
   cd android && ./gradlew signingReport
   ```
   Esto imprime, para cada variante (`debug`, `release`), tanto el
   `SHA1` como el `SHA256`. En la pantalla de Firebase donde agregaste
   la app Android, click en "Agregar huella digital" y cargar **las dos**
   del `Variant: debug` (`SHA1` es el que de verdad usa Google Sign-In
   para validar el login; `SHA256` lo pide cada vez más Google para
   otras verificaciones — cargar ambas de entrada evita tener que volver
   después). Cuando generes un build firmado para Play Store, hay que
   volver acá y agregar TAMBIÉN el SHA-1 y el SHA-256 de esa firma (y si
   usás Play App Signing, el que Google Play te muestra en su consola,
   que no es el mismo que tu keystore local) — si no, el login con
   Google va a fallar solo en esa versión, aunque en debug funcione
   perfecto.
4. **Orden importante**: cargar las huellas ANTES de descargar
   `google-services.json` (paso 4). El archivo necesita que las huellas
   ya estén cargadas para incluir el client ID que permite pedir el
   `idToken` — si lo generás antes y agregás las huellas después, hay
   que volver a correr `flutterfire configure` para que se regenere
   (ver "Problemas comunes" más abajo, es la causa más común de que el
   login falle con un error de `idToken`).

## Paso 3 — Habilitar Authentication y Firestore

1. Authentication → "Comenzar" → pestaña "Sign-in method" → habilitar
   **Google**. Elegir un correo de soporte del proyecto (te lo pide).
2. Firestore Database → "Crear base de datos" → modo producción (las
   reglas de seguridad las subimos en el paso 5) → elegir una región
   (la más cercana a donde estén ustedes dos).

## Paso 4 — Conectar el proyecto Flutter con `flutterfire configure`

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Va a pedir elegir el proyecto de Firebase que creaste y las plataformas
(Android, y iOS si corresponde). Esto genera automáticamente:
- `lib/firebase_options.dart` — reemplaza el placeholder que dejé ahí
  (con `useFirebase = false` no se usa, así que no hay drama si corrés
  esto en cualquier momento).
- El `google-services.json` en `android/app/` y los ajustes de
  `build.gradle` que hacen falta — no hay que tocarlos a mano.

## Paso 5 — Subir las reglas de seguridad y el índice

Este repo ya incluye `firestore.rules` y `firestore.indexes.json`
listos para usar. Subirlos desde Firebase Console (Firestore Database →
Reglas → pegar el contenido de `firestore.rules` → Publicar) o con el
CLI si lo tenés instalado:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

**Importante**: `watchIncomingRequest` (la solicitud de pairing
entrante) hace una consulta que combina 3 campos — Firestore va a pedir
un índice compuesto la primera vez que corra. Si no subiste
`firestore.indexes.json` de antemano, cuando pruebes el pairing vas a
ver un error en consola con un link tipo
`https://console.firebase.google.com/.../indexes?create_composite=...`
— tocarlo crea el índice al toque (tarda 1-2 minutos en activarse).

Las reglas que dejé son un punto de partida razonable, no 100%
blindadas — tienen una nota adentro del archivo explicando el
compromiso que hacen (dejan que cualquier usuario logueado actualice
cuentas ajenas, porque hoy el cliente confirma el pairing directo contra
Firestore). Antes de publicar en serio, conviene mover esas operaciones
puntuales a Cloud Functions — está anotado en el propio archivo.

## Paso 6 — Prender el interruptor

En `lib/main.dart`:

```dart
const bool useFirebase = true; // estaba en false
```

Con eso, la app pasa a usar `FirebaseAuthService` +
`FirestorePairingRepository` + `FirestoreGameSessionRepository` en vez
de las versiones en memoria — y el botón 🐛 de desarrollo se oculta
solo (ya no tiene sentido, cada celular va a tener su propia cuenta de
Google real).

## Paso 7 — Probar con dos celulares de verdad

1. Compilar e instalar la app en los dos teléfonos (o un teléfono +
   un emulador).
2. En el celular 1: iniciar sesión con una cuenta de Google, crear la
   cuenta, anotar el código de 6 caracteres.
3. En el celular 2: iniciar sesión con OTRA cuenta de Google, crear la
   cuenta, ingresar el código del celular 1.
4. El celular 1 debería recibir el aviso de la solicitud casi al
   instante (gracias a `watchIncomingRequest` con `.snapshots()`).
   Aceptar, completar los datos de la relación.
5. Entrar a cualquier juego desde los dos celulares — la partida se
   sincroniza sola por Firestore.

## Problemas comunes

- **"PERMISSION_DENIED" en la consola**: no subiste `firestore.rules`
  (paso 5), o las reglas no llegaron a publicarse. Revisar en Firebase
  Console → Firestore → Reglas que diga la versión que subiste.
- **El login con Google falla en release pero funciona en debug**: falta
  agregar el SHA-1 y el SHA-256 de la firma de release en Firebase
  Console (mismo paso que las de debug, sección 2.3).
- **Error "Google no devolvió un idToken" al tocar "Continuar con
  Google"**: exactamente el caso del paso 2.4 — las huellas se cargaron
  DESPUÉS de generar `google-services.json`. Solución: correr
  `flutterfire configure` de nuevo (sobrescribe el archivo con uno que sí
  incluye el client ID correcto) y volver a compilar.
- **El botón "Buscar por WiFi" no encuentra al otro celular**: confirmar
  que los dos estén en la MISMA red y que no sea una red con
  "aislamiento de clientes" (común en WiFi de oficinas, cafés o algunos
  routers de ISP con esa opción activada) — ahí el broadcast UDP no
  llega de un dispositivo a otro aunque estén en la misma red, y no hay
  forma de evitarlo desde la app. El código manual (pantalla anterior)
  siempre funciona como alternativa, no depende de la red local.
- **"La consulta requiere un índice"**: ver la nota del paso 5 — tocar
  el link del error crea el índice, o subir `firestore.indexes.json` de
  antemano para no tener que esperar a que pase en vivo.
- **No aparece `android/` en el repo**: este proyecto se armó escribiendo
  solo el código Dart (`lib/`) a mano, sin correr `flutter create` en
  este entorno — hace falta correrlo una vez en tu máquina/CI antes de
  poder compilar un APK (ver paso 2.2). A partir de ahí, `android/` e
  `ios/` quedan como cualquier proyecto Flutter normal.
