import 'package:appsmarketplace/core/constants/api_constants.dart';
import 'package:appsmarketplace/core/services/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('[REQUEST] ${options.method} ${options.path}');

          // Jangan inject token ke auth endpoint
          final isAuthEndpoint = options.path.contains('/auth/');

          if (!isAuthEndpoint) {
            final token = await SecureStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          debugPrint('[ERROR] ${error.response?.statusCode}');

          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/');
          final is401 = error.response?.statusCode == 401;

          // Coba refresh token otomatis saat 401 pada non-auth endpoint
          if (is401 && !isAuthEndpoint) {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final firebaseToken = await user.getIdToken(true);

                // Minta backend token baru
                final refreshDio = Dio(BaseOptions(
                  baseUrl: ApiConstants.baseUrl,
                  headers: {'Content-Type': 'application/json'},
                ));
                final resp = await refreshDio.post(
                  ApiConstants.verifyToken,
                  data: {'firebase_token': firebaseToken},
                );

                if (resp.data['success'] == true) {
                  final newToken = resp.data['data']['access_token'] as String;
                  await SecureStorage.saveToken(newToken);

                  // Ulangi request asli dengan token baru
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newToken';
                  final retryResp = await dio.fetch(retryOptions);
                  return handler.resolve(retryResp);
                }
              }
            } catch (e) {
              debugPrint('[TOKEN_REFRESH_ERROR] $e');
            }
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
