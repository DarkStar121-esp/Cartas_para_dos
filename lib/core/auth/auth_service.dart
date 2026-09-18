import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_account.dart';
import '../../models/gender.dart';

abstract class AuthService {
  Stream<UserAccount?> get userStream;
  UserAccount? get currentUser;
  Future<UserAccount> signInAnonymously();
  Future<dynamic> signInWithGoogle();
  Future<UserAccount?> fetchAccount(String userId);
  Future<UserAccount> createAccount(dynamic a1, [dynamic a2, dynamic a3]);
  Future<void> updateAccount(dynamic a1, [dynamic a2]);
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserAccount?> get userStream {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return await fetchAccount(fbUser.uid);
    });
  }

  @override
  UserAccount? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return UserAccount(
      id: fbUser.uid,
      name: fbUser.displayName ?? 'Usuario',
      email: fbUser.email ?? '',
      gender: Gender.other,
    );
  }

  @override
  Future<UserAccount> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final fbUser = cred.user!;
    final existing = await fetchAccount(fbUser.uid);
    if (existing != null) return existing;
    final newUser = UserAccount(
      id: fbUser.uid,
      name: 'Usuario_${fbUser.uid.substring(0, 4)}',
      email: fbUser.email ?? '',
      gender: Gender.other,
    );
    await createAccount(newUser);
    return newUser;
  }

  @override
  Future<dynamic> signInWithGoogle() async {
    return await signInAnonymously();
  }

  @override
  Future<UserAccount?> fetchAccount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return UserAccount(
        id: doc.id,
        name: data['name'] ?? data['displayName'] ?? 'Usuario',
        email: data['email'] ?? '',
        gender: Gender.values.firstWhere(
          (g) => g.name == (data['gender'] ?? 'other'),
          orElse: () => Gender.other,
        ),
        coupleId: data['coupleId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserAccount> createAccount(dynamic a1, [dynamic a2, dynamic a3]) async {
    UserAccount account;
    if (a1 is UserAccount) {
      account = a1;
    } else {
      account = UserAccount(
        id: a1?.toString() ?? _auth.currentUser?.uid ?? 'unknown',
        name: a2?.toString() ?? 'Usuario',
        email: a3?.toString() ?? '',
      );
    }
    await _firestore.collection('users').doc(account.id).set({
      'name': account.name,
      'displayName': account.displayName,
      'email': account.email,
      'gender': account.gender.name,
      'coupleId': account.coupleId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return account;
  }

  @override
  Future<void> updateAccount(dynamic a1, [dynamic a2]) async {
    if (a1 is UserAccount) {
      await _firestore.collection('users').doc(a1.id).set({
        'name': a1.name,
        'displayName': a1.displayName,
        'email': a1.email,
        'gender': a1.gender.name,
        'coupleId': a1.coupleId,
      }, SetOptions(merge: true));
    } else if (a1 is String && a2 != null) {
      await _firestore.collection('users').doc(a1).set(
        a2 is Map<String, dynamic> ? a2 : {'data': a2},
        SetOptions(merge: true),
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

typedef InMemoryAuthService = FirebaseAuthService;
