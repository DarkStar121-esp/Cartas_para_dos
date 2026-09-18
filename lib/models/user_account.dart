import 'gender.dart';

class UserAccount {
  final String id;
  final String name;
  final String email;
  final Gender gender;
  final String? coupleId;
  final String? customGoogleUid;

  UserAccount({
    required this.id,
    String? name,
    String? displayName,
    this.email = '',
    this.gender = Gender.other,
    this.coupleId,
    String? googleUid,
  })  : name = name ?? displayName ?? 'Usuario',
        customGoogleUid = googleUid;

  String get displayName => name;
  String get googleUid => customGoogleUid ?? id;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'email': email,
      'gender': gender.name,
      'coupleId': coupleId,
      'googleUid': googleUid,
    };
  }
}
