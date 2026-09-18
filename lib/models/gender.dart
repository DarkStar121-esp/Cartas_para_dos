import 'package:flutter/material.dart';

enum Gender {
  male,
  female,
  nonBinary,
  other,
  preferNotToSay,
}

extension GenderColorFix on Gender {
  Color get color {
    final str = toString().toLowerCase();
    if (str.contains('female') || str.contains('mujer')) return Colors.pinkAccent;
    if (str.contains('male') || str.contains('hombre')) return Colors.blueAccent;
    return Colors.purpleAccent;
  }
}
