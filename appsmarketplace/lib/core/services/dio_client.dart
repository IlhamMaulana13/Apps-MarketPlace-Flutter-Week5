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

          final isAuthEndpoint = options.path.contains('/auth/');

          if (!isAuthEndpoint) {
            final token = await SecureStorage.getToken();

            debugPrint('TOKEN DIPAKAI DI DIO: $token');

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              debugPrint('TOKEN NULL ❌');
            }
          }

          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
