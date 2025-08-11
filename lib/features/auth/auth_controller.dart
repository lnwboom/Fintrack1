// lib/features/auth/controller/auth_controller.dart
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'service/auth_service.dart';
import 'service/otp_service.dart';
import 'package:fintrack/data/models/user_model.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _auth = AuthService();
  final SecureStorage _storage = SecureStorage();

  AuthController() : super(const AsyncValue.loading()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await _storage.read('jwt');
    if (token != null) {
      try {
        final user = await _auth.checkSession(token);
        state = AsyncValue.data(user);
      } catch (_) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.login(username: username, password: password);
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error(
            'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final token = await _storage.read('jwt');
    if (token != null) {
      await _auth.logout(token);
      await _storage.delete('jwt');
    }
    state = const AsyncValue.data(null);
  }

  Future<void> sendOtp(String email) async {
    final OtpService _otp = OtpService(); // ← add this back
    await _otp.sendOtp(email);
  }

  Future<bool> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String name,
    required String email,
    required String otp,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _auth.register(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        name: name,
        email: email,
        otp: otp,
      );
      state = AsyncData(user);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSimplifiedUsers() async {
    final token = await _storage.read('jwt');
    if (token == null) throw Exception('Not authenticated');

    return await _auth.fetchSimplifiedUsers(token);
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? numberAccount,
    int? maxLimitExpense,
    Uint8List? avatarBytes,
    String? avatarFilename,
    String? currentPassword,
    String? newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final token = await _storage.read('jwt');
      if (token == null) throw Exception('Not authenticated');

      final data = await _auth.updateProfile(
        token: token,
        name: name,
        email: email,
        phone: phone,
        numberAccount: numberAccount,
        maxLimitExpense: maxLimitExpense,
        avatarBytes: avatarBytes,
        avatarFilename: avatarFilename,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final userJson = data['user'] as Map<String, dynamic>;
      state = AsyncValue.data(UserModel.fromJson(userJson));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
