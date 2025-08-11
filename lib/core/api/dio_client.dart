// lib/core/api/dio_client.dart
import 'package:dio/dio.dart';

class DioClient {
  static final Dio instance = Dio(
    BaseOptions(
      // For Android emulator:
      baseUrl: //'http://20.191.146.17:5000'
          'http://10.0.2.2:5000' // matches server.js :contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}
      ,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(LogInterceptor(responseBody: true));
}
