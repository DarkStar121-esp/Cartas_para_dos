import '../../models/couple.dart';
import '../../models/level_reward.dart';
import '../../models/user_account.dart';
import 'animal_allocation.dart';
import 'level_config.dart';

/// Resultado de aplicar XP: la pareja actualizada + qué se desbloqueó
/// nuevo (para poder mostrar un festejo en la UI, ej. "¡Subieron a nivel
/// 4! Desbloquearon un animal cada uno").
class XpApplicationResult {
  final Couple updatedCouple;
  final List<LevelReward> unlockedRewards;

  /// Solo tiene valor si entre las recompensas desbloqueadas hay un
  /// animal Y se pasaron las dos cuentas (para poder calcular qué
  /// animales están libres). El caller es responsable de aplicar este
  /// resultado a cada UserAccount (agregarlo a ownedAnimalIds) y
  /// persistirlo — este service no toca las cuentas directamente.
  final AnimalAllocationResult? animalAllocation;

  const XpApplicationResult(this.updatedCouple, this.unlockedRewards, this.animalAllocation);
}

/// Toda esta lógica es pura (nada de Flutter, nada de red) para poder
/// testearla con `flutter test` sin mockear nada. La misma lógica tiene
/// que espejarse server-side (ver functions/dailyProgressionTick.ts) —
/// el cliente nunca debe ser la fuente de verdad de cuánta XP se ganó.
class XpService {
  /// Se llama 1 vez por día por pareja (idealmente vía Cloud Scheduler).
  /// Devuelve la pareja sin cambios si ya se contó la XP pasiva hoy.
  XpApplicationResult applyDailyPassiveTick(
    Couple couple,
    DateTime today, {
    UserAccount? user1,
    UserAccount? user2,
  }) {
    final todayDate = _dateOnly(today);
    if (couple.lastActiveDate != null && _isSameDay(couple.lastActiveDate!, todayDate)) {
      return XpApplicationResult(couple, const [], null);
    }

    final withXp = couple.copyWith(
      totalXp: couple.totalXp + passiveXpPerDay,
      lastActiveDate: todayDate,
    );
    return _resolveLevelUps(couple, withXp, user1: user1, user2: user2);
  }

  /// Se llama al terminar cualquier partida jugada entre los dos
  /// (compita o no — la XP activa aplica a todos los juegos, el
  /// contador de victorias/derrotas es un sistema aparte, ver
  /// core/social/nickname_service.dart).
  XpApplicationResult applyActiveGameXp(
    Couple couple,
    DateTime playedAt, {
    UserAccount? user1,
    UserAccount? user2,
  }) {
    final playedDate = _dateOnly(playedAt);
    final last = couple.lastPlayedDate;

    int newStreak;
    if (last == null) {
      newStreak = 1;
    } else if (_isSameDay(last, playedDate)) {
      newStreak = couple.streakDays; // ya jugaron hoy, no vuelve a subir
    } else if (_isSameDay(last.add(const Duration(days: 1)), playedDate)) {
      newStreak = couple.streakDays + 1;
    } else {
      newStreak = 1; // se cortó la racha, arranca de nuevo
    }

    final gained = activeXpForStreak(newStreak);
    final withXp = couple.copyWith(
      totalXp: couple.totalXp + gained,
      streakDays: newStreak,
      lastPlayedDate: playedDate,
    );
    return _resolveLevelUps(couple, withXp, user1: user1, user2: user2);
  }

  XpApplicationResult _resolveLevelUps(
    Couple before,
    Couple after, {
    UserAccount? user1,
    UserAccount? user2,
  }) {
    final newLevel = levelForXp(after.totalXp);
    if (newLevel <= before.level) {
      return XpApplicationResult(after, const [], null);
    }

    final unlocked = levelRewardTable
        .where((r) => r.level > before.level && r.level <= newLevel)
        .toList();

    AnimalAllocationResult? allocation;
    final hasAnimalReward = unlocked.any((r) => r.type == RewardType.animal);
    if (hasAnimalReward && user1 != null && user2 != null) {
      allocation = allocateAnimalsOnLevelUp(
        ownedByUser1: user1.customization.ownedAnimalIds,
        ownedByUser2: user2.customization.ownedAnimalIds,
      );
    }

    return XpApplicationResult(after.copyWith(level: newLevel), unlocked, allocation);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
