import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // 🔥 AUTO SYNC FIREBASE USER
  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _firebaseUser = user;
      notifyListeners();
    });
  }

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

      final user = credential.user;
      if (user == null) {
        _setError("User tidak ditemukan");
        return false;
      }

      await user.reload(); // 🔥 refresh data

      // ❗ CEK EMAIL VERIFIED DULU
      if (!user.emailVerified) {
        _firebaseUser = user;
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      // 🔥 kalau sudah verified baru lanjut backend
      final token = await user.getIdToken(true);

      final response = await DioClient.instance.post(
        '/auth/verify-token',
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

      _setError("Gagal verifikasi backend");
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login gagal');
      return false;
    }
  }

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


      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      // ✅ kirim token ke backend
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

      final user = credential.user;

      if (user == null) {
        _setError("Gagal membuat user");
        return false;
      }

      await user.updateDisplayName(name);
      await user.sendEmailVerification();

      _firebaseUser = user;
      _status = AuthStatus.emailNotVerified;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Pendaftaran gagal');
      return false;
    }
  }

  // ================= CHECK EMAIL VERIFIED =================
  Future<bool> checkEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return false;

      await user.reload();

      if (!user.emailVerified) return false;

      final token = await user.getIdToken(true);

      final response = await DioClient.instance.post(
        '/auth/verify-token',
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
      debugPrint("CHECK VERIFY ERROR: $e");
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

  // ================= ERROR =================
  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
}
