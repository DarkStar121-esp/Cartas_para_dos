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

import 'package:flutter/material.dart';

extension GenderColorFix on Gender {
  Color get color {
    final str = toString().toLowerCase();
    if (str.contains('female') || str.contains('mujer')) return Colors.pinkAccent;
    if (str.contains('male') || str.contains('hombre')) return Colors.blueAccent;
    return Colors.purpleAccent;
  }
}
