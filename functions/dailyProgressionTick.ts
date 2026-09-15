/**
 * Cloud Function programada (Cloud Scheduler, 1 vez por día) que:
 *   1. Suma XP pasiva a todas las parejas.
 *   2. Corta la racha (streakDays = 0) de las parejas que no jugaron
 *      ninguna partida activa el día anterior.
 *
 * Los apodos DOMINANTE/DOMINADO NO necesitan tocarse acá: se calculan al
 * leer, comparando `lastCompetitiveGameAt` contra "ahora" (ver
 * NicknameService.computeNicknames en el cliente, lib/core/social/). No
 * hay ningún estado que resetear del lado del servidor para eso.
 *
 * IMPORTANTE: esta lógica tiene que espejar exactamente
 * lib/core/progression/xp_service.dart y level_config.dart del cliente —
 * el cliente dispara la partida, pero quien aplica y persiste la XP es
 * siempre el servidor. Si en algún momento se cambia una constante
 * (PASSIVE_XP_PER_DAY, la curva de niveles, etc.) hay que cambiarla en
 * los dos lados.
 *
 * Referencia de implementación — no testeada, ajustar nombres de
 * colección/campos a como termine el schema real de Firestore.
 */
import * as functions from 'firebase-functions/v2/scheduler';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const PASSIVE_XP_PER_DAY = 5;

function dateKey(d: Date): string {
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}

export const dailyProgressionTick = functions.onSchedule('every day 04:00', async () => {
  const db = getFirestore();
  const couplesSnap = await db.collection('couples').get();

  const today = new Date();
  const todayKey = dateKey(today);
  const yesterdayKey = dateKey(new Date(today.getTime() - 24 * 60 * 60 * 1000));

  const batch = db.batch();

  couplesSnap.forEach((doc) => {
    const couple = doc.data();
    const updates: Record<string, unknown> = {};

    // 1. XP pasiva — una vez por día, idempotente vía lastActiveDate.
    if (couple.lastActiveDate !== todayKey) {
      updates.totalXp = FieldValue.increment(PASSIVE_XP_PER_DAY);
      updates.lastActiveDate = todayKey;
    }

    // 2. Corte de racha si ayer no jugaron ninguna partida activa.
    const lastPlayed = couple.lastPlayedDate as string | undefined;
    if (lastPlayed && lastPlayed !== todayKey && lastPlayed !== yesterdayKey) {
      updates.streakDays = 0;
    }

    if (Object.keys(updates).length > 0) {
      batch.update(doc.ref, updates);
    }
  });

  await batch.commit();
});

/**
 * Próximo paso sugerido (no incluido acá para no mezclar responsabilidades):
 * un Firestore trigger `onDocumentUpdated('couples/{id}')` que compare
 * totalXp antes/después de cada escritura (tanto la de este tick como la
 * que dispara el cliente al terminar una partida activa) y, si cruzó un
 * umbral de nivel con recompensa de animal, corra la asignación atómica
 * (equivalente server-side de allocateAnimalsOnLevelUp en
 * lib/core/progression/animal_allocation.dart) dentro de una transacción
 * que también actualice ambas cuentas. Hacerlo ahí y no en el cliente
 * evita que alguien pueda manipular qué animal le toca a cada uno.
 */
