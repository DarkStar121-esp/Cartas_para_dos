/// XP acumulada necesaria para llegar al nivel [level]. Curva de arranque,
/// fácil de tunear cuando haya datos reales de uso: xpParaNivel(n) = 100n.
int xpRequiredForLevel(int level) => 100 * level;

/// Dado el total de XP acumulada, calcula en qué nivel está la pareja.
int levelForXp(int totalXp) {
  var level = 1;
  while (totalXp >= xpRequiredForLevel(level)) {
    level++;
  }
  return level;
}

const int passiveXpPerDay = 5;
const int baseActiveXpPerGame = 20;
const int maxStreakBonus = 30;
const int streakBonusPerDay = 2;

/// XP que da una partida activa según la racha actual. El bonus está
/// tapeado para que no se descontrole con rachas muy largas.
int activeXpForStreak(int streakDays) {
  final bonus = (streakDays * streakBonusPerDay).clamp(0, maxStreakBonus);
  return baseActiveXpPerGame + bonus;
}
