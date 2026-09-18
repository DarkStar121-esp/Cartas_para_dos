import 'gender.dart';

class UserAccount {
  final String id;
  final String name;
  final String? customFirstName;
  final String? lastName;
  final String email;
  final Gender gender;
  final String? coupleId;
  final String? customGoogleUid;
  final String? customPairingCode;
  final int? age;
  final dynamic customization;

  UserAccount({
    required this.id,
    String? name,
    String? displayName,
    String? firstName,
    this.lastName,
    this.email = '',
    this.gender = Gender.other,
    this.coupleId,
    String? googleUid,
    String? pairingCode,
    String? fullName,
    this.age,
    this.customization,
  })  : customFirstName = firstName,
        name = name ?? fullName ?? displayName ?? (firstName != null ? '$firstName ${lastName ?? ""}'.trim() : 'Usuario'),
        customGoogleUid = googleUid,
        customPairingCode = pairingCode;

  String get displayName => name;
  String get fullName => name;
  String get firstName => customFirstName ?? (name.contains(' ') ? name.split(' ').first : name);
  String get googleUid => customGoogleUid ?? id;
  String get pairingCode => customPairingCode ?? (id.length >= 6 ? id.substring(0, 6) : id);

  UserAccount copyWith({
    String? id,
    String? name,
    String? displayName,
    String? firstName,
    String? lastName,
    String? email,
    Gender? gender,
    String? coupleId,
    String? googleUid,
    String? pairingCode,
    String? fullName,
    int? age,
    dynamic customization,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.customFirstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      coupleId: coupleId ?? this.coupleId,
      googleUid: googleUid ?? this.googleUid,
      pairingCode: pairingCode ?? this.pairingCode,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      customization: customization ?? this.customization,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'fullName': fullName,
      'firstName': firstName,
      'email': email,
      'gender': gender.name,
      'coupleId': coupleId,
      'googleUid': googleUid,
      'pairingCode': pairingCode,
      'age': age,
      'customization': customization,
    };
  }
}
