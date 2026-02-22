// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email & password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Register with email & password
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());

    // Save user to Firestore
    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'displayName': displayName.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Anonymous sign in
  Future<UserCredential> signInAnonymously(String nickname) async {
    final credential = await _auth.signInAnonymously();
    await credential.user?.updateDisplayName(nickname.trim());

    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'displayName': nickname.trim(),
      'isAnonymous': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String get displayName =>
      currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Player';
}