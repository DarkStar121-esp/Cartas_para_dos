import 'package:flutter/material.dart';

enum Gender {
  male,
  female,
  nonBinary,
  other,
  preferNotToSay;

  Color get color {
    switch (this) {
      case Gender.female:
        return Colors.pinkAccent;
      case Gender.male:
        return Colors.blueAccent;
      default:
        return Colors.purpleAccent;
    }
  }
}
