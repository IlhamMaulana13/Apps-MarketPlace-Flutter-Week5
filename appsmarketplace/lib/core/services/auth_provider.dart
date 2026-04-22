import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:appsmarketplace/core/constants/api_constants.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';
import 'package:appsmarketplace/core/services/secure_storage.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  String? _backendToken;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  String? get backendToken => _backendToken;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  void _setLoading() {
    _status = AuthStatus.loading;
    notifyListeners();
  }

  // ================= LOGIN EMAIL =================
  Future<bool> loginWithEmail({
  required String email,
  required String password,
  }) async {
  _setLoading();
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

     _firebaseUser = credential.user;

     await _firebaseUser!.reload();

  // ================= LOGIN GOOGLE =================
  Future<bool> loginWithGoogle() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setError('Login Google dibatalkan');
        return false;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      _firebaseUser = userCred.user;

      final token = await _firebaseUser!.getIdToken();
      print("🔥 FIREBASE TOKEN:");
      print(token);

      final isVerified = await _verifyTokenToBackend();
      if (!isVerified) {
        _setError("Gagal verifikasi ke backend");
        return false;
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal login Google: $e');
      return false;
    }
  }

  // ================= REGISTER =================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseUser = credential.user;

      // Update display name
      await _firebaseUser!.updateDisplayName(name);

      // Send email verification
      await _firebaseUser!.sendEmailVerification();

      _status = AuthStatus.emailNotVerified;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Pendaftaran gagal');
      return false;
    }
  }

  // ================= VERIFY TOKEN KE BACKEND =================
  Future<bool> _verifyTokenToBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final firebaseToken = await user!.getIdToken();

      final response = await DioClient.instance.post(
        '/auth/verify-token',
        data: {"firebase_token": firebaseToken},
      );

      if (response.data['success'] == true) {
        final backendToken = response.data['data']['access_token'];

        await SecureStorage.saveToken(backendToken);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint("VERIFY TOKEN ERROR: $e");
      return false;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await SecureStorage.deleteToken();

    _firebaseUser = null;
    _backendToken = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  // ================= CHECK EMAIL VERIFIED =================
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.emailVerified) return false;

      final token = await user.getIdToken();

      final response = await DioClient.instance.post(
        ApiConstants.verifyToken,
        data: {"firebase_token": token},
      );

      if (response.data['success'] == true) {
        _backendToken = response.data['data']['access_token'];
        await SecureStorage.saveToken(_backendToken!);
        _firebaseUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("CHECK EMAIL VERIFIED ERROR: $e");
      return false;
    }
  }

  // ================= ERROR =================
  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
}
