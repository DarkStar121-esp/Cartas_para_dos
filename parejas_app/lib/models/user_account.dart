import 'gender.dart';

/// Estado de personalización de un perfil. Los valores por defecto son
/// los que pide el spec: sin animal (silueta), fuente del sistema, banner
/// blanco — todo lo demás se desbloquea subiendo de nivel.
class ProfileCustomization {
  final List<String> ownedAnimalIds;
  final String? equippedAnimalId; // null = silueta default
  final List<String> ownedFontIds;
  final String equippedFontId;
  final List<String> ownedBannerColorIds;
  final String equippedBannerColorId;

  const ProfileCustomization({
    this.ownedAnimalIds = const [],
    this.equippedAnimalId,
    this.ownedFontIds = const ['system'],
    this.equippedFontId = 'system',
    this.ownedBannerColorIds = const ['white'],
    this.equippedBannerColorId = 'white',
  });

  ProfileCustomization copyWith({
    List<String>? ownedAnimalIds,
    String? equippedAnimalId,
    bool clearEquippedAnimal = false,
    List<String>? ownedFontIds,
    String? equippedFontId,
    List<String>? ownedBannerColorIds,
    String? equippedBannerColorId,
  }) {
    return ProfileCustomization(
      ownedAnimalIds: ownedAnimalIds ?? this.ownedAnimalIds,
      equippedAnimalId:
          clearEquippedAnimal ? null : (equippedAnimalId ?? this.equippedAnimalId),
      ownedFontIds: ownedFontIds ?? this.ownedFontIds,
      equippedFontId: equippedFontId ?? this.equippedFontId,
      ownedBannerColorIds: ownedBannerColorIds ?? this.ownedBannerColorIds,
      equippedBannerColorId: equippedBannerColorId ?? this.equippedBannerColorId,
    );
  }

  Map<String, dynamic> toJson() => {
        'ownedAnimalIds': ownedAnimalIds,
        'equippedAnimalId': equippedAnimalId,
        'ownedFontIds': ownedFontIds,
        'equippedFontId': equippedFontId,
        'ownedBannerColorIds': ownedBannerColorIds,
        'equippedBannerColorId': equippedBannerColorId,
      };

  factory ProfileCustomization.fromJson(Map<String, dynamic> json) => ProfileCustomization(
        ownedAnimalIds: List<String>.from(json['ownedAnimalIds'] as List? ?? const []),
        equippedAnimalId: json['equippedAnimalId'] as String?,
        ownedFontIds: List<String>.from(json['ownedFontIds'] as List? ?? const ['system']),
        equippedFontId: json['equippedFontId'] as String? ?? 'system',
        ownedBannerColorIds: List<String>.from(json['ownedBannerColorIds'] as List? ?? const ['white']),
        equippedBannerColorId: json['equippedBannerColorId'] as String? ?? 'white',
      );
}

class UserAccount {
  /// UUID interno — no se muestra a nadie.
  final String id;

  /// Código corto (6 caracteres) que la persona comparte para que su
  /// pareja se conecte con ella. Ver ACCOUNTS_AND_PROGRESSION.md sección 3.
  final String pairingCode;

  /// UID que devuelve Firebase Auth tras el login con Google.
  final String googleUid;

  final String firstName;
  final String lastName;
  final int age;
  final Gender gender;

  /// null hasta que se empareja con otra cuenta. Una vez seteado, no hay
  /// forma de volver a null desde la app (ver sección 3.2 del diseño).
  final String? coupleId;

  final DateTime createdAt;
  final ProfileCustomization customization;

  const UserAccount({
    required this.id,
    required this.pairingCode,
    required this.googleUid,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.createdAt,
    this.coupleId,
    this.customization = const ProfileCustomization(),
  });

  bool get isPaired => coupleId != null;
  String get fullName => '$firstName $lastName';

  UserAccount copyWith({
    String? coupleId,
    ProfileCustomization? customization,
  }) {
    return UserAccount(
      id: id,
      pairingCode: pairingCode,
      googleUid: googleUid,
      firstName: firstName,
      lastName: lastName,
      age: age,
      gender: gender,
      createdAt: createdAt,
      coupleId: coupleId ?? this.coupleId,
      customization: customization ?? this.customization,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pairingCode': pairingCode,
        'googleUid': googleUid,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender.name,
        'coupleId': coupleId,
        'createdAt': createdAt.toIso8601String(),
        'customization': customization.toJson(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'] as String,
        pairingCode: json['pairingCode'] as String,
        googleUid: json['googleUid'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        age: json['age'] as int,
        gender: Gender.values.byName(json['gender'] as String),
        coupleId: json['coupleId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        customization: json['customization'] == null
            ? const ProfileCustomization()
            : ProfileCustomization.fromJson(Map<String, dynamic>.from(json['customization'] as Map)),
      );
}
