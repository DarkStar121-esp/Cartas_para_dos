import 'package:flutter/material.dart';
import '../../models/customization.dart';
import '../../models/user_account.dart';

/// Muestra el avatar de una cuenta: silueta por defecto o el animal
/// equipado, con el fondo azul/rosa según el sexo, la tipografía elegida
/// para el nombre, y el color de banner detrás — o sea, TODA la
/// personalización desbloqueada en un solo lugar (ver
/// ACCOUNTS_AND_PROGRESSION.md sección 5).
class ProfileAvatar extends StatelessWidget {
  final UserAccount account;
  final String label;
  final double size;

  const ProfileAvatar({super.key, required this.account, required this.label, this.size = 88});

  Color _hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(account.gender.defaultBackgroundHex);
    final equippedId = account.customization.equippedAnimalId;
    final banner = CustomizationCatalog.bannerById(account.customization.equippedBannerColorId);
    final font = CustomizationCatalog.fontById(account.customization.equippedFontId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Icon(
            equippedId == null ? Icons.person : Icons.pets,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: _hexToColor(banner.colorHex), borderRadius: BorderRadius.circular(6)),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: font.fontFamily.isEmpty ? null : font.fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (equippedId != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              CustomizationCatalog.animalById(equippedId).name,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
