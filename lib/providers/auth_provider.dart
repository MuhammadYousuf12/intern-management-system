import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// Manages authentication state across the app.
// Bridges AuthService and UI - screens interact with this, not AuthService directly.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // --- Listen to auth state changes on app start ---
  AuthProvider() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      notifyListeners();
    });
  }

  // --- Register ---
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _handleError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- Login ---
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _authService.loginUser(email: email, password: password);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _handleError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- Logout ---
  Future<void> logout() async {
    await _authService.logout();
  }

  // --- Resend verification email ---
  Future<void> resendVerificationEmail() async {
    await _authService.resendVerificationEmail();
  }

  // --- Get user role ---
  Future<String> getUserRole() async {
    return await _authService.getUserRole(_user!.uid);
  }

  // --- Private helpers ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Converts Firebase error into readable messages
  String _handleError(String error) {
    if (error.contains("email-already-in-use")) {
      return "This email is already registered.";
    } else if (error.contains("wrong-password")) {
      return "Incorrect password.";
    } else if (error.contains("user-not-found")) {
      return "no account found with this email.";
    } else if (error.contains("invalid-email")) {
      return "Please enter a valid email address.";
    } else if (error.contains("weak-password")) {
      return "Password must be at least 8 characters.";
    }
    return "Something went wrong. Please try again.";
  }
}
