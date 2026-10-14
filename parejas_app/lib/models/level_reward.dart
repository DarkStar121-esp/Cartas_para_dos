enum RewardType { animal, font, bannerColor }

class LevelReward {
  final int level;
  final RewardType type;
  const LevelReward(this.level, this.type);
}

/// Tabla de recompensas por nivel — mismo patrón de "contenido como datos"
/// que los mazos de cartas: para cambiar el ritmo de desbloqueos se edita
/// esta lista, no la lógica de progresión (ver xp_service.dart).
const List<LevelReward> levelRewardTable = [
  LevelReward(2, RewardType.animal),
  LevelReward(3, RewardType.font),
  LevelReward(4, RewardType.animal),
  LevelReward(5, RewardType.bannerColor),
  LevelReward(6, RewardType.animal),
  LevelReward(7, RewardType.font),
  LevelReward(8, RewardType.animal),
  LevelReward(9, RewardType.bannerColor),
  LevelReward(10, RewardType.animal),
];
