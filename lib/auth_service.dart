import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'services/user_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Task 2: Expose auth state via a Stream
  Stream<User?> get userState => _auth.authStateChanges();

  // Get current user UID directly
  String? get currentUid => _auth.currentUser?.uid;

  // Sign In with Google (Updated null-safe version)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If the user cancels the pop-up, return null
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final cred = await _auth.signInWithCredential(credential);
      await UserPreferences.instance.syncWithFirebase();
      return cred;
    } catch (e) {
      debugPrint('An unexpected error occurred during Google Sign In: $e');
      return null;
    }
  }

  // Task 1 & 3: Sign Up with Email and Password
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await UserPreferences.instance.syncWithFirebase();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred during Sign Up: $e');
      return null;
    }
  }

  // Task 1 & 3: Sign In with Email and Password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await UserPreferences.instance.syncWithFirebase();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred during Sign In: $e');
      return null;
    }
  }

  // Password Recovery
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'success'; // Return a success message
    } on FirebaseAuthException catch (e) {
      // Return clean error strings for the UI
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

  // Updated Sign Out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut(); // Signs out of Google
      await _auth.signOut();          // Signs out of Firebase
      
      // Clear local preferences
      await UserPreferences.instance.clearAuth();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Private helper for basic error handling
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

// Simple helper for printing in non-UI classes
void debugPrint(String message) {
  print('[AuthService] $message');
}
