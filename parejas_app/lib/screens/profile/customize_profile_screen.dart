import 'package:flutter/material.dart';
import '../../models/customization.dart';
import '../../models/user_account.dart';

class CustomizeProfileScreen extends StatefulWidget {
  final UserAccount me;

  /// Animales que tiene la pareja — se muestran con un tag "de tu pareja"
  /// y, al tocarlos, se ofrece proponer un intercambio.
  final List<String> partnerOwnedAnimalIds;

  final void Function(String animalId)? onEquipAnimal;
  final void Function(String fontId)? onEquipFont;
  final void Function(String bannerId)? onEquipBanner;

  /// (miAnimalOfrecido, animalDeLaPareja que pido a cambio)
  final void Function(String myAnimalId, String partnerAnimalId)? onProposeTrade;

  const CustomizeProfileScreen({
    super.key,
    required this.me,
    this.partnerOwnedAnimalIds = const [],
    this.onEquipAnimal,
    this.onEquipFont,
    this.onEquipBanner,
    this.onProposeTrade,
  });

  @override
  State<CustomizeProfileScreen> createState() => _CustomizeProfileScreenState();
}

class _CustomizeProfileScreenState extends State<CustomizeProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar perfil'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Avatar'),
          Tab(text: 'Tipografía'),
          Tab(text: 'Banner'),
        ]),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _AnimalGrid(
            me: widget.me,
            partnerOwnedAnimalIds: widget.partnerOwnedAnimalIds,
            onEquip: widget.onEquipAnimal,
            onProposeTrade: widget.onProposeTrade,
          ),
          _FontList(me: widget.me, onEquip: widget.onEquipFont),
          _BannerGrid(me: widget.me, onEquip: widget.onEquipBanner),
        ],
      ),
    );
  }
}

class _AnimalGrid extends StatelessWidget {
  final UserAccount me;
  final List<String> partnerOwnedAnimalIds;
  final void Function(String)? onEquip;
  final void Function(String, String)? onProposeTrade;

  const _AnimalGrid({
    required this.me,
    required this.partnerOwnedAnimalIds,
    this.onEquip,
    this.onProposeTrade,
  });

  Future<void> _offerTrade(BuildContext context, String partnerAnimalId) async {
    final owned = me.customization.ownedAnimalIds;
    if (owned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todavía no tenés ningún animal para ofrecer a cambio.')),
      );
      return;
    }
    final myOffer = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('¿Qué animal ofrecés a cambio?'),
        children: owned
            .map((id) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, id),
                  child: Text(CustomizationCatalog.animalById(id).name),
                ))
            .toList(),
      ),
    );
    if (myOffer != null) {
      onProposeTrade?.call(myOffer, partnerAnimalId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta enviada, esperando que tu pareja confirme.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = me.customization.ownedAnimalIds;
    final equipped = me.customization.equippedAnimalId;

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: CustomizationCatalog.animals.map((animal) {
        final ownedByMe = owned.contains(animal.id);
        final ownedByPartner = partnerOwnedAnimalIds.contains(animal.id);
        final isEquipped = equipped == animal.id;
        final isLocked = !ownedByMe && !ownedByPartner;

        return GestureDetector(
          onTap: () {
            if (ownedByMe) {
              onEquip?.call(animal.id);
            } else if (ownedByPartner) {
              _offerTrade(context, animal.id);
            }
            // Si está locked, no pasa nada acá — se desbloquea solo al
            // subir de nivel (ver core/progression/animal_allocation.dart).
          },
          child: Opacity(
            opacity: isLocked ? 0.35 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEquipped ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  width: 3,
                ),
                color: Colors.grey.shade100,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets, size: 32), // placeholder hasta tener el asset final
                      const SizedBox(height: 4),
                      Text(animal.name, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  if (isLocked)
                    const Positioned(top: 4, right: 4, child: Icon(Icons.lock, size: 14)),
                  if (ownedByPartner)
                    const Positioned(
                      bottom: 4,
                      child: Text('de tu pareja',
                          style: TextStyle(fontSize: 9, color: Colors.black54)),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FontList extends StatelessWidget {
  final UserAccount me;
  final void Function(String)? onEquip;
  const _FontList({required this.me, this.onEquip});

  @override
  Widget build(BuildContext context) {
    final owned = me.customization.ownedFontIds;
    final equipped = me.customization.equippedFontId;
    return ListView(
      children: CustomizationCatalog.fonts.map((font) {
        final unlocked = owned.contains(font.id);
        return ListTile(
          enabled: unlocked,
          leading: Icon(unlocked ? Icons.font_download : Icons.lock_outline),
          title: Text(
            font.name,
            style: TextStyle(fontFamily: font.fontFamily.isEmpty ? null : font.fontFamily),
          ),
          trailing: equipped == font.id ? const Icon(Icons.check_circle, color: Colors.green) : null,
          onTap: unlocked ? () => onEquip?.call(font.id) : null,
        );
      }).toList(),
    );
  }
}

class _BannerGrid extends StatelessWidget {
  final UserAccount me;
  final void Function(String)? onEquip;
  const _BannerGrid({required this.me, this.onEquip});

  @override
  Widget build(BuildContext context) {
    final owned = me.customization.ownedBannerColorIds;
    final equipped = me.customization.equippedBannerColorId;
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: CustomizationCatalog.bannerColors.map((b) {
        final unlocked = owned.contains(b.id);
        final color = Color(int.parse(b.colorHex.replaceFirst('#', '0xFF')));
        return GestureDetector(
          onTap: unlocked ? () => onEquip?.call(b.id) : null,
          child: Opacity(
            opacity: unlocked ? 1 : 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: equipped == b.id ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
              alignment: Alignment.center,
              child: !unlocked ? const Icon(Icons.lock, size: 16) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
