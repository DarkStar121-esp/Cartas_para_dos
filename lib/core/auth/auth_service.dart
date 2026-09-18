import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_account.dart';
import '../../models/gender.dart';

abstract class AuthService {
  Stream<UserAccount?> get userStream;
  UserAccount? get currentUser;
  Future<UserAccount> signInAnonymously();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserAccount?> get userStream {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return await _getOrUpdateUserAccount(fbUser);
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
    return await _getOrUpdateUserAccount(fbUser);
  }

  Future<UserAccount> _getOrUpdateUserAccount(fb.User fbUser) async {
    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return UserAccount(
        id: fbUser.uid,
        name: data['name'] ?? data['displayName'] ?? 'Usuario',
        email: data['email'] ?? fbUser.email ?? '',
        gender: Gender.values.firstWhere(
          (g) => g.name == (data['gender'] ?? 'other'),
          orElse: () => Gender.other,
        ),
      );
    } else {
      final newUser = UserAccount(
        id: fbUser.uid,
        name: 'Usuario_${fbUser.uid.substring(0, 4)}',
        email: fbUser.email ?? '',
        gender: Gender.other,
      );
      await docRef.set({
        'name': newUser.name,
        'displayName': newUser.displayName,
        'email': newUser.email,
        'gender': newUser.gender.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return newUser;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

typedef InMemoryAuthService = FirebaseAuthService;
