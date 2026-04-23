import 'package:appsmarketplace/core/constants/api_constants.dart';
import 'package:appsmarketplace/core/services/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DioClient {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await SecureStorage.getToken();

              debugPrint("🔥 TOKEN DIPAKAI: $token");

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
            onError: (error, handler) async {
              debugPrint('[ERROR] ${error.response?.statusCode}');
              debugPrint('[ERROR DATA] ${error.response?.data}');

              if (error.response?.statusCode == 401) {
                await SecureStorage.deleteToken();
              }

              handler.next(error);
            },
          ),
        );

  static Dio get instance => _dio;
}
