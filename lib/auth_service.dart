import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Task 2: Expose auth state via a Stream
  Stream<User?> get userState => _auth.authStateChanges();

  // Get current user UID directly
  String? get currentUid => _auth.currentUser?.uid;

  // Task 1 & 3: Sign Up with Email and Password
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred during Sign In: $e');
      return null;
    }
  }

  // Task 1: Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
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
