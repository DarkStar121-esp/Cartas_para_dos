import 'dart:async';
import '../../models/user_account.dart';
import '../../models/gender.dart';

abstract class AuthService {
  Stream<UserAccount?> get userStream;
  UserAccount? get currentUser;
  List<UserAccount> get allAccounts;
  List<UserAccount> get devAccounts;

  Stream<UserAccount?> watchAccount(String googleUid);
  Future<UserAccount?> fetchAccount([dynamic a1]);
  Future<UserAccount> signInAnonymously();
  Future<dynamic> signInWithGoogle([dynamic a1]);
  Future<UserAccount> createAccount({
    String? googleUid,
    String? name,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    Gender? gender,
    String? coupleId,
    String? id,
    String? displayName,
    String? pairingCode,
    dynamic age,
    dynamic customization,
  });
  Future<void> updateAccount([dynamic a1, dynamic a2]);
  Future<void> signOut();
  Future<void> switchAccount([dynamic a1]);
}

class MockAuthService implements AuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  final StreamController<UserAccount?> _userController = StreamController<UserAccount?>.broadcast();
  UserAccount? _currentUser;
  final List<UserAccount> _accounts = [];

  @override
  Stream<UserAccount?> get userStream => _userController.stream;

  @override
  UserAccount? get currentUser => _currentUser;

  @override
  List<UserAccount> get allAccounts => _accounts;

  @override
  List<UserAccount> get devAccounts => _accounts;

  @override
  Stream<UserAccount?> watchAccount(String googleUid) {
    return Stream.value(
      _accounts.firstWhere(
        (a) => a.googleUid == googleUid || a.id == googleUid,
        orElse: () => _currentUser ?? UserAccount(id: googleUid, googleUid: googleUid),
      ),
    );
  }

  @override
  Future<UserAccount?> fetchAccount([dynamic a1]) async {
    if (a1 == null) return _currentUser;
    final key = a1.toString();
    try {
      return _accounts.firstWhere((a) => a.id == key || a.googleUid == key);
    } catch (_) {
      return _currentUser;
    }
  }

  @override
  Future<UserAccount> signInAnonymously() async {
    final user = UserAccount(id: 'anon_123', name: 'Usuario Anónimo');
    _currentUser = user;
    _userController.add(user);
    return user;
  }

  @override
  Future<dynamic> signInWithGoogle([dynamic a1]) async {
    return await signInAnonymously();
  }

  @override
  Future<UserAccount> createAccount({
    String? googleUid,
    String? name,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    Gender? gender,
    String? coupleId,
    String? id,
    String? displayName,
    String? pairingCode,
    dynamic age,
    dynamic customization,
  }) async {
    final uid = id ?? googleUid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    int? parsedAge;
    if (age is int) parsedAge = age;
    if (age is String) parsedAge = int.tryParse(age);

    final account = UserAccount(
      id: uid,
      name: name ?? fullName ?? displayName ?? (firstName != null ? '$firstName ${lastName ?? ""}'.trim() : 'Usuario'),
      firstName: firstName,
      lastName: lastName,
      email: email ?? '',
      gender: gender ?? Gender.other,
      coupleId: coupleId,
      googleUid: googleUid ?? uid,
      pairingCode: pairingCode,
      age: parsedAge,
      customization: customization,
    );
    _accounts.add(account);
    _currentUser = account;
    _userController.add(account);
    return account;
  }

  @override
  Future<void> updateAccount([dynamic a1, dynamic a2]) async {}

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _userController.add(null);
  }

  @override
  Future<void> switchAccount([dynamic a1]) async {
    if (a1 is UserAccount) {
      _currentUser = a1;
      _userController.add(a1);
    }
  }
}
