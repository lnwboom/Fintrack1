import 'package:dio/dio.dart';
import 'package:fintrack/core/api/dio_client.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:flutter/foundation.dart';

/// Service for managing transactions via Dio HTTP client.
class TransactionService {
  final Dio _dio = DioClient.instance;
  static const _base = '/api/transactions';
  final SecureStorage _storage = SecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read('jwt');
    if (token == null) {
      throw Exception('No token found');
    }
    debugPrint('Token: \$token');
    return token;
  }

  /// Fetch paginated list of transactions.
  Future<List<TransactionModel>> fetchTransactions({
    int page = 1,
    int limit = 10,
    String sort = '-createdAt',
  }) async {
    final token = await _getToken();
    final resp = await _dio.get(
      '$_base/CheckBills',
      queryParameters: {'limit': limit, 'page': page, 'sort': sort},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    final data = resp.data['data']['transactions'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((j) => TransactionModel.fromJson(j))
        .toList();
  }

  /// Fetch a single transaction by ID.
  Future<TransactionModel> fetchTransactionById(String id) async {
    final token = await _getToken();
    final resp = await _dio.get(
      '$_base/CheckBills/$id',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return TransactionModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  /// Create a new transaction, optionally with slip image.
  Future<TransactionModel> createTransaction({
    required String type,
    required double amount,
    required String category,
    String? description,
    String? workspaceId,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    final token = await _getToken();
    final form = FormData();
    form.fields
      ..add(MapEntry('type', type))
      ..add(MapEntry('amount', amount.toString()))
      ..add(MapEntry('category', category));
    if (description != null) {
      form.fields.add(MapEntry('description', description));
    }
    if (workspaceId != null) {
      form.fields.add(MapEntry('workspace', workspaceId));
    }
    if (slipImageBytes != null && slipImageName != null) {
      form.files.add(
        MapEntry(
          'slip_image',
          MultipartFile.fromBytes(slipImageBytes, filename: slipImageName),
        ),
      );
    }

    final resp = await _dio.post(
      '$_base/keepBills',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );
    return TransactionModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  /// Update existing transaction by ID.
  Future<TransactionModel> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? category,
    String? description,
    String? workspaceId,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    final token = await _getToken();
    final form = FormData();
    if (type != null) form.fields.add(MapEntry('type', type));
    if (amount != null) form.fields.add(MapEntry('amount', amount.toString()));
    if (category != null) form.fields.add(MapEntry('category', category));
    if (description != null) {
      form.fields.add(MapEntry('description', description));
    }
    if (workspaceId != null) {
      form.fields.add(MapEntry('workspace', workspaceId));
    }
    if (slipImageBytes != null && slipImageName != null) {
      form.files.add(
        MapEntry(
          'slip_image',
          MultipartFile.fromBytes(slipImageBytes, filename: slipImageName),
        ),
      );
    }

    final resp = await _dio.put(
      '$_base/CheckBills/$id',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );
    return TransactionModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  /// Delete transaction by ID.
  Future<void> deleteTransaction(String id) async {
    final token = await _getToken();
    await _dio.delete(
      '$_base/CheckBills/$id',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}
