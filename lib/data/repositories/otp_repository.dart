// lib/data/repositories/otp_repository.dart
abstract class OtpRepository {
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String otp);
}
