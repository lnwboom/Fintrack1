// lib/features/auth/service/auth_service.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fintrack/core/api/dio_client.dart';
import 'package:fintrack/data/models/user_model.dart';
import 'package:fintrack/core/storage/secure_storage.dart';

class AuthService {
  final Dio _dio = DioClient.instance;
  static const _base = '/api/auth';

  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    try {
      final resp = await _dio.post('$_base/login', data: {
        'username': username,
        'password': password,
      });

      if (!resp.data['success']) {
        return null;
      }

      final data = resp.data['data'] as Map<String, dynamic>;

      if (data['token'] == null) {
        throw Exception('ไม่พบ token ในข้อมูลที่ได้รับ');
      }

      final token = data['token'] as String;
      final SecureStorage _store = SecureStorage();
      await _store.write('jwt', token);

      if (data['user'] == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ในข้อมูลที่ได้รับ');
      }

      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
      } else if (e.response?.statusCode == 400) {
        if (e.response?.data['message'] == 'Invalid credentials') {
          return null;
        }
        throw Exception(e.response?.data['message'] ?? 'ข้อมูลไม่ถูกต้อง');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
      } else {
        throw Exception('เกิดข้อผิดพลาดในการเข้าสู่ระบบ: ${e.message}');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ: ${e.toString()}');
    }
  }

  Future<UserModel> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String name,
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'username': username,
          'password': password,
          'confirmPassword': confirmPassword,
          'name': name,
          'email': email,
          'otp': otp,
        },
      );

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw response.data['message'] ?? 'ไม่สามารถลงทะเบียนได้';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'];
        final details = e.response?.data['details'];
        if (message == 'Duplicate value' && details is List) {
          if (details.contains('numberAccount is already registered')) {
            throw 'ชื่อผู้ใช้นี้มีผู้ใช้งานแล้ว';
          } else if (details.contains('email is already registered')) {
            throw 'อีเมลนี้มีผู้ใช้งานแล้ว';
          }
        } else if (message == 'Invalid OTP') {
          throw 'รหัส OTP ไม่ถูกต้อง';
        } else if (message == 'Weak password') {
          throw 'รหัสผ่านไม่ปลอดภัยพอ';
        }
      }
      throw e.response?.data['message'] ??
          'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    } catch (e) {
      throw 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }

  Future<void> logout(String token) async {
    await _dio.post('$_base/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<UserModel> refreshToken(String refreshToken) async {
    final resp = await _dio
        .post('$_base/refresh-token', data: {'refreshToken': refreshToken});
    return UserModel.fromJson(resp.data['data']);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post('$_base/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<UserModel> checkSession(String token) async {
    try {
      final resp = await _dio.get(
        '$_base/check-session',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = resp.data['data'] as Map<String, dynamic>;
      if (data['user'] == null) {
        throw Exception('User data not found in response');
      }

      final userJson = data['user'] as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } catch (e) {
      throw Exception('Failed to check session: ${e.toString()}');
    }
  }

  Future<List<UserModel>> fetchAllUsers(String token) async {
    final resp = await _dio.get('$_base/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return (resp.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> fetchUserById(String token, String userId) async {
    final resp = await _dio.get('$_base/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return UserModel.fromJson(resp.data);
  }

  Future<List<Map<String, dynamic>>> fetchSimplifiedUsers(String token) async {
    final resp = await _dio.get('$_base/users/simplified',
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    if (!resp.data['success']) {
      throw Exception(
          resp.data['message'] ?? 'Failed to fetch simplified users');
    }

    return List<Map<String, dynamic>>.from(resp.data['data']);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
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
    final form = FormData();

    if (name != null) form.fields.add(MapEntry('name', name));
    if (email != null) form.fields.add(MapEntry('email', email));
    if (phone != null) form.fields.add(MapEntry('phone', phone));
    if (numberAccount != null)
      form.fields.add(MapEntry('numberAccount', numberAccount));
    if (maxLimitExpense != null)
      form.fields
          .add(MapEntry('max_limit_expense', maxLimitExpense.toString()));
    if (currentPassword != null)
      form.fields.add(MapEntry('currentPassword', currentPassword));
    if (newPassword != null)
      form.fields.add(MapEntry('newPassword', newPassword));
    if (avatarBytes != null && avatarFilename != null) {
      form.files.add(MapEntry(
        'avatar',
        MultipartFile.fromBytes(avatarBytes, filename: avatarFilename),
      ));
    }

    final resp = await _dio.put(
      '$_base/profile',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );

    // returns { success: true, message: "...", data: { user: { ... } } }
    return resp.data['data'] as Map<String, dynamic>;
  }
}
