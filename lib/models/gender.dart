enum Gender { male, female }

extension GenderX on Gender {
  /// Color de fondo por defecto del avatar: azul para hombres, rosa para
  /// mujeres (el dibujo del animal es el mismo para los dos, solo cambia
  /// el fondo). Si más adelante se quiere soportar más identidades, este
  /// es el único lugar que hay que tocar.
  String get defaultBackgroundHex => switch (this) {
        Gender.male => '#4A90D9',
        Gender.female => '#E85D9C',
      };

  String get label => switch (this) {
        Gender.male => 'Hombre',
        Gender.female => 'Mujer',
      };
}
