import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handles all Firebase Authentication operations.
// Keeps auth logic seperate from UI - screens just call these methods.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Current logged in user ---
  User? get currentUser => _auth.currentUser;

  // --- Auth state stream - listen for login/logout changes ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- Register new user ---
  Future<UserCredential> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Create user in Firebase Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save user profile in Firestore with role as intern by default
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'fullName': fullName,
      'email': email,
      'role': 'intern',
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send email varification
    await credential.user!.sendEmailVerification();

    return credential;
  }

  // --- Login existing user ---
  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // --- Logout ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- Resend verification email ---
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser!.sendEmailVerification();
  }

  // --- Get user role from Firestore ---
  Future<String> getUserRole(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc['role'] as String;
  }
}
