// lib/data/repositories/auth_repository.dart
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String username, String password);
  Future<void> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String name,
    required String email,
    required String otp,
  });
  Future<void> logout(String token);
  Future<UserModel> refreshToken(String refreshToken);
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
  Future<UserModel> checkSession(String token);
  Future<List<UserModel>> fetchAllUsers();
  Future<UserModel> fetchUserById(String userId);
  Future<UserModel> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? numberAccount,
    String? currentPassword,
    String? newPassword,
   // Uint8List? avatarBytes,      // for file upload
    String? avatarFilename,
  });
}
