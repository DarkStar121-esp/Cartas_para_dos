import 'gender.dart';

class UserAccount {
  final String id;
  final String name;
  final String email;
  final Gender gender;

  UserAccount({
    required this.id,
    String? name,
    String? displayName,
    this.email = '',
    this.gender = Gender.other,
  }) : name = name ?? displayName ?? 'Usuario';

  String get displayName => name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'email': email,
      'gender': gender.name,
    };
  }
}
