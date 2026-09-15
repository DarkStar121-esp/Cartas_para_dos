import 'relationship_type.dart';

class CompetitiveRecord {
  final int wins;
  final int losses;
  const CompetitiveRecord({this.wins = 0, this.losses = 0});

  CompetitiveRecord addWin() => CompetitiveRecord(wins: wins + 1, losses: losses);
  CompetitiveRecord addLoss() => CompetitiveRecord(wins: wins, losses: losses + 1);
}

/// La entidad que se crea al conectar dos cuentas. El nivel/XP/racha son
/// de la pareja (no de cada persona por separado) — ver
/// ACCOUNTS_AND_PROGRESSION.md sección 4.
class Couple {
  final String id;
  final String user1Id;
  final String user2Id;

  final RelationshipType relationshipType;
  final DateTime relationshipStartDate;

  /// Cuándo se confirmó el pairing — a partir de acá es irreversible.
  final DateTime pairedAt;

  final int level;

  /// XP acumulada TOTAL (no solo la del nivel actual). El nivel se
  /// deriva de este valor, ver level_config.dart#levelForXp.
  final int totalXp;

  final int streakDays;

  /// Último día (solo fecha, sin hora) en que se contó la XP pasiva.
  /// Evita duplicar la XP si el tick corre más de una vez el mismo día.
  final DateTime? lastActiveDate;

  /// Último día en que jugaron una partida activa — se usa para calcular
  /// si la racha sigue, sube o se corta.
  final DateTime? lastPlayedDate;

  /// Último momento en que terminó una partida de un juego marcado
  /// isCompetitive. Determina si los apodos DOMINANTE/DOMINADO siguen
  /// vigentes o ya pasó el mes de inactividad (sección 7 del diseño).
  final DateTime? lastCompetitiveGameAt;

  /// Victorias/derrotas por userId. Nunca se resetea (a diferencia de los
  /// apodos, que se recalculan y pueden dejar de mostrarse).
  final Map<String, CompetitiveRecord> competitiveRecordByUserId;

  const Couple({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.relationshipType,
    required this.relationshipStartDate,
    required this.pairedAt,
    this.level = 1,
    this.totalXp = 0,
    this.streakDays = 0,
    this.lastActiveDate,
    this.lastPlayedDate,
    this.lastCompetitiveGameAt,
    this.competitiveRecordByUserId = const {},
  });

  Couple copyWith({
    int? level,
    int? totalXp,
    int? streakDays,
    DateTime? lastActiveDate,
    DateTime? lastPlayedDate,
    DateTime? lastCompetitiveGameAt,
    Map<String, CompetitiveRecord>? competitiveRecordByUserId,
  }) {
    return Couple(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      relationshipType: relationshipType,
      relationshipStartDate: relationshipStartDate,
      pairedAt: pairedAt,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      lastCompetitiveGameAt: lastCompetitiveGameAt ?? this.lastCompetitiveGameAt,
      competitiveRecordByUserId: competitiveRecordByUserId ?? this.competitiveRecordByUserId,
    );
  }
}
