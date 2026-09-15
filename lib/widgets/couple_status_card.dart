import 'package:flutter/material.dart';
import '../core/progression/level_config.dart';
import '../core/social/nickname_service.dart';
import '../models/couple.dart';

class CoupleStatusCard extends StatelessWidget {
  final Couple couple;
  final String myUserId;
  final String myName;
  final String partnerName;

  const CoupleStatusCard({
    super.key,
    required this.couple,
    required this.myUserId,
    required this.myName,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    final floor = xpRequiredForLevel(couple.level - 1 < 0 ? 0 : couple.level - 1);
    final ceiling = xpRequiredForLevel(couple.level);
    final progress = ((couple.totalXp - floor) / (ceiling - floor)).clamp(0.0, 1.0);

    final nicknames = NicknameService().computeNicknames(couple, DateTime.now());
    final isUser1 = couple.user1Id == myUserId;
    final myNickname = isUser1 ? nicknames.user1 : nicknames.user2;
    final partnerNickname = isUser1 ? nicknames.user2 : nicknames.user1;
    final partnerId = isUser1 ? couple.user2Id : couple.user1Id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nivel ${couple.level}', style: Theme.of(context).textTheme.titleLarge),
                if (couple.streakDays > 0)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department, size: 18, color: Colors.orange),
                    label: Text('${couple.streakDays} días de racha'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
            const SizedBox(height: 16),
            _PlayerRow(
              name: myName,
              nickname: myNickname,
              record: couple.competitiveRecordByUserId[myUserId],
            ),
            const SizedBox(height: 8),
            _PlayerRow(
              name: partnerName,
              nickname: partnerNickname,
              record: couple.competitiveRecordByUserId[partnerId],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String name;
  final Nickname? nickname;
  final CompetitiveRecord? record;
  const _PlayerRow({required this.name, this.nickname, this.record});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
        if (nickname != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: nickname == Nickname.dominante ? Colors.deepPurple : Colors.blueGrey,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              nickname == Nickname.dominante ? 'DOMINANTE' : 'DOMINADO',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        Text('${record?.wins ?? 0}V - ${record?.losses ?? 0}D',
            style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
