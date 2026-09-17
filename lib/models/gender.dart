enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  String get label => switch (this) {
        Gender.male => 'Masculino',
        Gender.female => 'Femenino',
        Gender.other => 'Otro',
        Gender.preferNotToSay => 'Prefiero no decir',
      };

  String get defaultBackgroundHex => switch (this) {
        Gender.female => '#E85D9C',
        _ => '#E0E0E0',
      };
}
