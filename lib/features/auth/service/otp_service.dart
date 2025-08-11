// lib/features/auth/service/otp_service.dart
import 'package:dio/dio.dart';
import 'package:fintrack/core/api/dio_client.dart';

class OtpService {
  final Dio _dio = DioClient.instance;
  static const _base = '/api/otp';

  /// Send OTP to email (register-request)
  Future<void> sendOtp(String email) async {
    await _dio.post('$_base/register-request', data: {'email': email});
  }

  /// Verify OTP separately if needed (verify-register)
  Future<void> verifyOtp(String email, String otp) async {
    await _dio.post('$_base/verify-register', data: {'email': email, 'otp': otp});
  }
}
