# Cuentas, emparejamiento y progresión

Este documento define el sistema pedido: cuentas individuales, conexión de
pareja irreversible, experiencia/niveles, personalización de perfiles con
intercambio de animales, y el sistema de victorias/derrotas con apodos.

## 1. Cuentas

Cada persona crea su propia cuenta (no hay cuentas "de pareja" desde el
inicio, se conectan dos cuentas individuales después). Datos en el alta:

- Nombre, apellido
- Edad
- Sexo (determina el color de fondo del avatar: azul / rosa)
- Login con cuenta de Google (Firebase Auth — ver sección 6)

**Recomendación: edad mínima 18 años para crear cuenta.** No porque cada
juego sea para adultos (UNO no lo es), sino porque la app en su conjunto está
diseñada para parejas/amantes y tiene un módulo con contenido para adultos
(Climax Club) — es más simple y más seguro poner el piso en toda la cuenta
que tratar de segmentar por módulo, y evita problemas de clasificación en
las stores. Esto es una recomendación de producto, se puede ajustar.

Al crear la cuenta se genera un `pairingCode`: un código corto (6
caracteres, ej. `7K2P9X`) que la persona comparte con su pareja para
conectarse. Es distinto del `id` interno de la cuenta (que es un UUID y no
se muestra a nadie).

Valores por defecto antes de personalizar nada:
- Avatar: silueta blanca, fondo rosa (mujer) o azul (hombre)
- Tipografía: la del sistema
- Banner: blanco

## 2. Información de la pareja

Una vez que dos cuentas se conectan (sección 3), se crea una entidad
`Couple` separada de las dos cuentas individuales, con:

- Tipo de relación: **saliendo / novios / amantes / esposos**
- Fecha de inicio de la relación (para calcular "cuánto tiempo llevan
  juntos")
- Fecha en la que se conectaron las cuentas en la app (`pairedAt`)

## 3. Emparejamiento (pairing)

### 3.1 Cómo se conectan

Dos formas, ambas terminan en el mismo flujo de confirmación:

1. **Por código**: la persona A ingresa el `pairingCode` de la persona B.
2. **Mismo WiFi**: ambos dispositivos, conectados a la misma red, se
   descubren automáticamente (broadcast en la red local) y la app sugiere
   "¿Te querés conectar con [nombre]?" — esto es solo un atajo para no
   tener que tipear el código a mano, **no reemplaza la confirmación
   explícita** de ambas personas (si alguien más estuviera en la misma red
   wifi —una casa compartida, un café— no queremos que se empareje solo por
   estar cerca).

En ambos casos, el flujo real de confirmación pasa siempre por el backend
(nunca es un pairing puramente local/P2P):

```
A ingresa el código de B  ─▶  se crea un "pairing request" pendiente
                          ─▶  B ve una notificación: "A quiere conectarse
                              con vos" + nombre/foto de A
                          ─▶  B ve el aviso de irreversibilidad (3.2)
                          ─▶  B confirma
                          ─▶  se crea el Couple, se bloquean ambas cuentas
                              entre sí (coupleId en cada una)
```

### 3.2 Es irreversible — y hay que decirlo antes, no después

No existe, en la app, ninguna acción de "desconectar" o "desvincular"
cuentas. Antes de confirmar el pairing (del lado de quien acepta), se
muestra un diálogo bloqueante:

> ⚠️ **Esta conexión es permanente.**
> Una vez conectadas, las cuentas de [A] y [B] no se pueden desvincular
> desde la app. Todo el progreso (nivel, personalización, racha) es
> compartido de acá en adelante.
> [Cancelar] [Conectar para siempre]

Nota de producto: en la vida real las parejas terminan. "Irreversible desde
la app" no puede significar "irreversible para siempre sin salida" — la
salida real (soporte que desvincula manualmente, o borrar y recrear la
cuenta) tiene que existir en algún lado, simplemente no está expuesta como
un botón fácil de tocar por accidente. Esto es una decisión de UX (fricción
intencional), no una limitación técnica real, y conviene tenerlo resuelto
en soporte antes de publicar la app.

## 4. Experiencia y niveles

El nivel es **de la pareja**, no de cada cuenta individual (tiene sentido:
mide qué tan activa está la relación en la app).

### 4.1 Curva de experiencia

```
xpParaNivel(n) = 100 × n
```
Ej: nivel 1→2 requiere 100 XP, nivel 4→5 requiere 500 XP. Es un valor de
arranque fácil de tunear después de ver comportamiento real de usuarios.

### 4.2 Experiencia pasiva

Por cada día que **ambas** cuentas siguen conectadas y con la app instalada
(sin necesidad de abrir la app ni jugar), la pareja suma una cantidad chica
de XP. Default: **+5 XP/día**. Se calcula server-side una vez por día (no
puede depender de que el usuario abra la app — ver sección 6), y no se ve
afectada por la racha.

### 4.3 Experiencia activa

Por cada partida completa jugada entre los dos, se suma más XP que la
pasiva. Default: **+20 XP por partida**.

### 4.4 Racha (streak)

Si juegan activamente **todos los días sin cortar**, la racha sube de a 1
por día. Si un día no juegan ninguna partida, la racha vuelve a 0 (esto no
afecta la XP pasiva, solo la activa). Mientras más alta la racha, más XP
activa dan las partidas siguientes:

```
xpActivaPorPartida = 20 + min(streakDays × 2, 30)
```

Ej: con racha de 10 días, cada partida da 20 + 20 = 40 XP. El bonus está
tapeado en +30 para que no se descontrole a rachas muy largas.

### 4.5 Qué se desbloquea al subir de nivel

Una tabla de recompensas por nivel (fácil de editar sin tocar lógica, mismo
patrón de "contenido como datos" que usamos para los mazos de cartas):

| Nivel | Desbloquea |
|---|---|
| 2 | 1 animal para cada uno |
| 3 | 1 tipografía nueva |
| 4 | 1 animal para cada uno |
| 5 | 1 color de banner |
| 6 | 1 animal para cada uno |
| ... | (se repite el patrón cada 2-3 niveles) |

## 5. Personalización de perfiles

### 5.1 Avatares (animales)

- Mismo set de animales dibujados estilo tierno/animado para ambos sexos —
  lo que cambia es el fondo (azul / rosa), no el dibujo.
- Al subir de nivel, se desbloquea **un animal al azar para cada persona**,
  tomado de un catálogo común.
- **Regla de unicidad dentro de la pareja**: en un momento dado, las dos
  personas de una pareja nunca pueden tener el mismo animal desbloqueado.
  Al asignar el animal random del level-up, se excluyen todos los animales
  que ya tiene cualquiera de los dos (no importa si es de otra pareja —
  otra pareja sí puede tener "Panda" en simultáneo, la restricción es solo
  puertas adentro de la relación).
- **Intercambio**: cualquiera de los dos puede proponer un swap 1-a-1 ("te
  cambio mi Zorro por tu Panda"). El otro tiene que aceptar. Al confirmarse,
  se intercambia la propiedad — la regla de unicidad se sigue cumpliendo
  automáticamente porque es un intercambio, no una copia.
- El avatar "equipado" (el que se ve en el perfil) es elegible entre todos
  los que la persona tiene desbloqueados, incluida la silueta default.

### 5.2 Tipografías y banners

Estos sí son compartidos sin restricción de unicidad: al subir de nivel se
desbloquea una tipografía o un color de banner **para la pareja**, y cada
uno elige libremente cuál usar entre lo que la pareja ya desbloqueó (no hay
escasez ni intercambio acá, a diferencia de los animales).

## 6. Backend necesario

Este sistema no puede vivir solo en el cliente:

- El pairing tiene que confirmarse server-side (si no, cualquiera podría
  forjar una conexión).
- La XP pasiva se calcula **aunque nadie abra la app** — necesita un
  trabajo programado (cron), no puede depender de un cliente.
- La reasignación de "quién tiene qué animal" tiene que ser atómica (dos
  escrituras simultáneas de ambos dispositivos no pueden pisarse).

Recomendación: **Firebase** (Auth con Google Sign-In nativo, Firestore para
las cuentas/couples, Cloud Functions + Cloud Scheduler para la XP pasiva
diaria y el chequeo de reset de apodos). Es la opción con menos fricción
para arrancar con Flutter y no requiere mantener un servidor propio.

Ver `functions/dailyProgressionTick.ts` para un ejemplo de cómo se vería la
función programada que corre 1 vez por día.

## 7. Victorias, derrotas y apodos

- Aplica **solo a los juegos con ganador/perdedor** (UNO, Chinchón, Escoba,
  Truco) — no a los juegos de conexión, que no tienen "ganador" en ese
  sentido. Cada `GameModule` tiene un flag `isCompetitive` para marcarlo.
- Cada vez que termina una partida de un juego competitivo, se suma 1
  victoria a quien ganó y 1 derrota a quien perdió, sobre la pareja. El
  contador es visible siempre para ambos (no se puede ocultar).
- El apodo se **calcula**, no se guarda: quien tiene más victorias es
  "DOMINANTE", el otro es "DOMINADO". Empate = sin apodo.
- **Reset por inactividad**: si pasa más de un mes sin jugarse ningún juego
  competitivo, los apodos dejan de mostrarse (vuelven a neutro) — pero el
  contador de victorias/derrotas NO se borra. En cuanto se juega una
  partida competitiva de nuevo, el apodo se vuelve a calcular a partir del
  contador histórico (que nunca se tocó), así que puede reaparecer
  inmediatamente si la diferencia de victorias se mantiene.
