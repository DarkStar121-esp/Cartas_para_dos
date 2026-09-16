import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_session.dart';
import '../../models/relationship_type.dart';
import '../../models/user_account.dart';
import '../../widgets/couple_status_card.dart';
import '../../widgets/profile/avatar_widget.dart';
import 'customize_profile_screen.dart';

/// Muestra la progresión de la pareja (nivel, XP, racha, victorias/
/// derrotas y apodos vía CoupleStatusCard) y da acceso a personalizar el
/// propio perfil (avatar, tipografía, banner) desde CustomizeProfileScreen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final me = session.myAccount;
    final partner = session.partnerAccount;
    final couple = session.couple;

    if (me == null || partner == null || couple == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ProfileAvatar(account: me, label: me.firstName),
              const Icon(Icons.favorite, color: Colors.pinkAccent),
              ProfileAvatar(account: partner, label: partner.firstName),
            ],
          ),
          const SizedBox(height: 20),
          CoupleStatusCard(
            couple: couple,
            myUserId: me.id,
            myName: me.firstName,
            partnerName: partner.firstName,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Personalizar mi perfil'),
              subtitle: const Text('Avatar, tipografía y banner'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openCustomize(context, session, me, partner),
            ),
          ),
          const SizedBox(height: 16),
          Text('Relación', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${couple.relationshipType.label} desde ${_formatDate(couple.relationshipStartDate)}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _openCustomize(BuildContext context, AppSession session, UserAccount me, UserAccount partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomizeProfileScreen(
          me: me,
          partnerOwnedAnimalIds: partner.customization.ownedAnimalIds,
          onEquipAnimal: (id) => session.updateMyAccount(
            me.copyWith(customization: me.customization.copyWith(equippedAnimalId: id)),
          ),
          onEquipFont: (id) => session.updateMyAccount(
            me.copyWith(customization: me.customization.copyWith(equippedFontId: id)),
          ),
          onEquipBanner: (id) => session.updateMyAccount(
            me.copyWith(customization: me.customization.copyWith(equippedBannerColorId: id)),
          ),
          onProposeTrade: (mine, theirs) {
            // TODO: mandar la propuesta al backend real para que la
            // pareja la confirme — ver ACCOUNTS_AND_PROGRESSION.md
            // sección 5.1. Todavía no existe un canal de "propuestas"
            // como el de pairing requests; es el siguiente paso natural
            // una vez que haya un backend real.
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
