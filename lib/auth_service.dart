import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

import 'services/user_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userState => _auth.authStateChanges();

  AuthService() {
    _bootstrapPreferences();

    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await UserPreferences.instance.syncWithFirebase(user);
      }
    });
  }

  void _bootstrapPreferences() {
    UserPreferences.instance.init().then((_) async {
      final user = _auth.currentUser;
      if (user != null) {
        await UserPreferences.instance.syncWithFirebase(user);
      }
    });
  }

  String? get currentUid => _auth.currentUser?.uid;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      await UserPreferences.instance.syncWithFirebase(cred.user);
      return cred;
    } catch (e) {
      debugPrint('An unexpected error occurred during Google Sign In: $e');
      return null;
    }
  }

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await UserPreferences.instance.syncWithFirebase(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred during Sign Up: $e');
      return null;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await UserPreferences.instance.syncWithFirebase(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred during Sign In: $e');
      return null;
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is poorly formatted.';
      } else {
        return e.message ?? 'An unknown Firebase error occurred.';
      }
    } catch (e) {
      return 'An unexpected error occurred during password reset.';
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      await UserPreferences.instance.clearAuth();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        debugPrint('No user found for that email.');
        break;
      case 'wrong-password':
        debugPrint('Wrong password provided for that user.');
        break;
      case 'email-already-in-use':
        debugPrint('The account already exists for that email.');
        break;
      case 'invalid-email':
        debugPrint('The email address is poorly formatted.');
        break;
      case 'weak-password':
        debugPrint('The password is too weak.');
        break;
      default:
        debugPrint('Firebase Auth Error: ${e.message}');
    }
  }
}
