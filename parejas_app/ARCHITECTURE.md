# Arquitectura

## Por qué Flutter

- Un solo código para Android e iOS (si más adelante querés subir a App Store
  no tenés que reescribir nada).
- Excelente para UI de cartas: animaciones, drag & drop y transiciones fluidas
  sin pelear con el framework.
- Se compila a APK sin depender de servicios de terceros — podés buildear
  localmente en cualquier momento con `flutter build apk`.
- Alternativa considerada: React Native/Expo. Es más cómodo si el equipo ya
  sabe JS/TS y querés EAS Build (compilar en la nube sin instalar nada), pero
  el rendimiento de animaciones complejas (mesa de Truco con varias cartas
  moviéndose) suele ser mejor en Flutter.

## Patrón central: GameModule

Cada juego (clásico o de pareja) implementa la interfaz `GameModule`
(`lib/core/game_module.dart`) y se registra en `GameRegistry`
(`lib/core/game_registry.dart`). La pantalla de inicio (`HomeScreen`) no sabe
nada de UNO, Truco o Climax Club en particular — solo itera la lista de
módulos registrados y muestra sus metadatos (nombre, descripción, si es
contenido adulto). Esto da dos ventajas:

1. **Cada juego se desarrolla de forma aislada**, sin pisarse entre sí.
2. **Agregar/sacar un juego es un cambio de una línea** en el registro, útil
   si más adelante querés hacer algunos juegos exclusivos de una versión paga.

## Lógica de juego vs. UI

Para juegos con reglas (UNO, y a futuro Chinchón/Escoba/Truco), la lógica pura
vive en un `*_engine.dart` sin ningún import de Flutter (ver
`uno_engine.dart`). Esto permite:

- Testear las reglas con `flutter test` sin levantar la UI.
- Reutilizar el mismo motor si el día de mañana agregás un modo online
  (el engine correría en un servidor/Cloud Function y la UI solo dibuja el
  estado que le llega).

Para los juegos de pareja basados en mazos de preguntas/frases (En Palabras,
Conectados, Climax Club), el contenido vive en JSON dentro de `assets/data/`
en vez de estar hardcodeado en Dart (ver `en_palabras_cards.json` +
`en_palabras_deck.dart`). Ventajas:

- Se pueden agregar cartas nuevas sin tocar código ni recompilar (si más
  adelante lo servís desde un backend en vez de un asset local).
- Facilita separar el trabajo de "escribir contenido" del de "programar".

## Manejo de estado

Para el alcance actual (juegos locales, pasar-y-jugar en un solo dispositivo)
alcanza con `StatefulWidget` + `setState`, que es lo que usan `UnoGameScreen`
y `EnPalabrasScreen`. Si más adelante sumás:

- **Progreso persistente** (estadísticas, mazos favoritos): agregar
  `shared_preferences` o `sqflite` es suficiente, no hace falta un manejador
  de estado global.
- **Multijugador online** (cada uno juega desde su propio teléfono): ahí sí
  conviene introducir `provider` o `riverpod` para el estado compartido, más
  un backend en tiempo real (Firebase Realtime Database/Firestore, o
  Supabase). Es un cambio de alcance grande — recomiendo dejarlo para una
  v2 una vez que los juegos "pasar y jugar" estén pulidos.

## Contenido para adultos (Climax Club / partes de Conectados)

`GameModule.isAdultContent` marca qué juegos tienen contenido +18. Hoy solo
se usa para mostrar un badge en el catálogo. Antes de publicar en las stores
conviene:

- Agregar una pantalla de confirmación de edad la primera vez que se abre un
  juego marcado como adulto (un simple diálogo "¿Sos mayor de 18?" con
  persistencia en `shared_preferences` alcanza para launch).
- Revisar las políticas de contenido de Google Play (categoría "Mature 17+"/
  "Dating") — apps con contenido sexual sugerido tienen reglas específicas de
  clasificación que conviene chequear antes de publicar, no después.
- El contenido en sí (las cartas/preguntas) conviene mantenerlo insinuante
  más que explícito — además de simplificar la aprobación en las stores, es
  el tono que suelen usar este tipo de apps (Climax Club, Blush, etc.).

## Roadmap sugerido (orden de implementación)

1. **UNO** ✅ y **En Palabras** ✅ — ya están como demo del patrón.
2. **Conectados** — reutiliza el patrón de En Palabras (mazo JSON + pantalla
   de turnos), es el siguiente más rápido de sumar.
3. **Escoba del 15** — reglas simples, buen tercer juego clásico.
4. **Chinchón** — reglas de agrupar/escalerar, algo más de UI (ordenar mano).
5. **Climax Club** — depende de tener el contenido (las cartas) escrito y
   revisado antes de programar la pantalla.
6. **Truco** — el más complejo (cantos, envido, bluff), dejarlo para el final.
7. **Pulido visual** — una vez que los 7 juegos funcionan, pasar una pasada de
   diseño (temas, animaciones de cartas, sonido) sobre toda la app.

## Monetización (para cuando llegue el momento)

Modelo típico para este tipo de app: los juegos clásicos gratis, los de
pareja como compra única o suscripción (Climax Club especialmente, al ser el
diferencial "picante" de la app). Con el patrón de `GameModule` es directo
agregar un flag `isPremium` y chequear el estado de compra antes de navegar
a `buildScreen()` — no requiere cambios estructurales.
