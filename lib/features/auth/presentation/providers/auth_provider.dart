import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:near_share/features/auth/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isGuest = false;
  String? _verificationId;
  String? _pendingName;

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _user != null && !_user!.isAnonymous;
  String? get verificationId => _verificationId;

  AuthProvider() {
    _authService.user.listen((User? user) {
      _user = user;
      if (user == null) {
        _isGuest = false;
      } else if (user.isAnonymous) {
        _isGuest = true;
      } else {
        _isGuest = false;
      }
      notifyListeners();
    });
  }

  // Phone Auth: Start Verification
  Future<void> verifyPhone({
    required String phoneNumber,
    required String name,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    _pendingName = name;
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await signInWithPhone(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verId, int? resendToken) {
        _verificationId = verId;
        onCodeSent(verId);
      },
      codeAutoRetrievalTimeout: (String verId) {
        _verificationId = verId;
      },
    );
  }

  // Phone Auth: Verify OTP
  Future<void> signInWithPhone(AuthCredential credential) async {
    final userCredential = await _authService.signInWithPhoneCredential(
      credential as PhoneAuthCredential,
    );
    if (userCredential.user != null && _pendingName != null) {
      await _authService.updateDisplayName(_pendingName!);
      _pendingName = null;
    }
  }

  Future<AuthCredential?> getGoogleCredential() async {
    return await _authService.getGoogleCredential();
  }

  Future<UserCredential?> upgradeWithCredential(
    AuthCredential credential,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      return await _authService.linkWithCredential(credential);
    }
    return await _authService.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithCredential(
    AuthCredential credential,
  ) async {
    return await _authService.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _authService.signInWithEmail(email, password);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return await _authService.signUpWithEmail(email, password);
  }

  Future<void> signInAsGuest() async {
    try {
      final credential = await _authService.signInAnonymously();
      if (credential != null) {
        _isGuest = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Guest sign-in failed: $e');
    }
  }

  Future<void> updateProfile({required String name}) async {
    await _authService.updateDisplayName(name);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _isGuest = false;
    notifyListeners();
  }
}
