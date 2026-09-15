class AnimalAvatar {
  final String id;
  final String name;

  /// Ruta al asset ilustrado (estilo tierno/animado). Los archivos todavía
  /// no existen en assets/avatars/ — son placeholders a reemplazar por el
  /// arte final; mientras tanto la UI muestra un ícono genérico.
  final String assetPath;

  const AnimalAvatar({required this.id, required this.name, required this.assetPath});
}

class FontOption {
  final String id;
  final String name;

  /// Nombre de familia tipográfica. Vacío = fuente del sistema (default).
  /// Las no vacías deben declararse en pubspec.yaml (fonts:) o venir de
  /// google_fonts si se prefiere no empaquetar los .ttf.
  final String fontFamily;

  const FontOption({required this.id, required this.name, required this.fontFamily});
}

class BannerColor {
  final String id;
  final String name;
  final String colorHex;

  const BannerColor({required this.id, required this.name, required this.colorHex});
}

/// Catálogos globales de personalización. El orden no implica orden de
/// desbloqueo (eso lo decide levelRewardTable + la asignación random de
/// animales) pero sirve para mostrar la grilla siempre en el mismo orden.
class CustomizationCatalog {
  static const List<AnimalAvatar> animals = [
    AnimalAvatar(id: 'panda', name: 'Panda', assetPath: 'assets/avatars/panda.png'),
    AnimalAvatar(id: 'zorro', name: 'Zorro', assetPath: 'assets/avatars/zorro.png'),
    AnimalAvatar(id: 'koala', name: 'Koala', assetPath: 'assets/avatars/koala.png'),
    AnimalAvatar(id: 'conejo', name: 'Conejo', assetPath: 'assets/avatars/conejo.png'),
    AnimalAvatar(id: 'gato', name: 'Gato', assetPath: 'assets/avatars/gato.png'),
    AnimalAvatar(id: 'perro', name: 'Perro', assetPath: 'assets/avatars/perro.png'),
    AnimalAvatar(id: 'buho', name: 'Búho', assetPath: 'assets/avatars/buho.png'),
    AnimalAvatar(id: 'oso', name: 'Oso', assetPath: 'assets/avatars/oso.png'),
    AnimalAvatar(id: 'pinguino', name: 'Pingüino', assetPath: 'assets/avatars/pinguino.png'),
    AnimalAvatar(id: 'erizo', name: 'Erizo', assetPath: 'assets/avatars/erizo.png'),
  ];

  static const List<FontOption> fonts = [
    FontOption(id: 'system', name: 'Sistema (default)', fontFamily: ''),
    FontOption(id: 'quicksand', name: 'Quicksand', fontFamily: 'Quicksand'),
    FontOption(id: 'pacifico', name: 'Pacifico', fontFamily: 'Pacifico'),
    FontOption(id: 'poppins', name: 'Poppins', fontFamily: 'Poppins'),
    FontOption(id: 'caveat', name: 'Caveat', fontFamily: 'Caveat'),
  ];

  static const List<BannerColor> bannerColors = [
    BannerColor(id: 'white', name: 'Blanco (default)', colorHex: '#FFFFFF'),
    BannerColor(id: 'lavender', name: 'Lavanda', colorHex: '#C9B6E4'),
    BannerColor(id: 'peach', name: 'Durazno', colorHex: '#FFC9A8'),
    BannerColor(id: 'mint', name: 'Menta', colorHex: '#A8E6CF'),
    BannerColor(id: 'sunset', name: 'Atardecer', colorHex: '#FF8FA3'),
  ];

  static AnimalAvatar animalById(String id) => animals.firstWhere((a) => a.id == id);
  static FontOption fontById(String id) => fonts.firstWhere((f) => f.id == id);
  static BannerColor bannerById(String id) => bannerColors.firstWhere((b) => b.id == id);
}
