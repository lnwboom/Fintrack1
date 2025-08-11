import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fintrack/core/api/dio_client.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'package:fintrack/data/models/bills_model.dart';

/// Service for managing bills scoped to a workspace.
class BillService {
  final Dio _dio = DioClient.instance;
  final SecureStorage _storage = SecureStorage();

  Future<String> _getToken() async {
    final token = await _storage.read('jwt');
    if (token == null) {
      throw Exception('No token found');
    }
    debugPrint('Token: $token');
    return token;
  }

  Future<List<Bill>> fetchBills({required String workspaceId}) async {
    final token = await _getToken();
    final resp = await _dio.get(
      '/api/workspaces/$workspaceId/bills',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return (resp.data['data'] as List<dynamic>)
        .map((e) => Bill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Bill> fetchBillById({
    required String workspaceId,
    required String billId,
  }) async {
    final token = await _getToken();
    final resp = await _dio.get(
      '/api/workspaces/$workspaceId/bills/$billId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return Bill.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<Bill> createBill({
    required String workspaceId,
    required String paymentType,
    RoundDetails? roundDetails,
    required List<Item> items,
    String? note,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    final token = await _getToken();

    // แปลงข้อมูล items ให้ถูกต้อง
    final processedItems = items.map((item) {
      final processedSharedWith = item.sharedWith.map((shared) {
        final userData = shared.user is Map
            ? shared.user as Map<String, dynamic>
            : {'_id': shared.user, 'name': shared.name};
        return {
          'user': shared.user,
          'name': shared.name,
          'status': shared.status,
          'shareAmount': shared.shareAmount,
          'roundPayments':
              shared.roundPayments?.map((r) => r.toJson()).toList() ?? [],
          'eSlip': shared.eSlip,
        };
      }).toList();

      return {
        'description': item.description,
        'amount': item.amount,
        'sharedWith': processedSharedWith,
      };
    }).toList();

    final resp = await _dio.post(
      '/api/workspaces/$workspaceId/bills',
      data: {
        'paymentType': paymentType,
        'items': processedItems,
        if (roundDetails != null) 'roundDetails': roundDetails.toJson(),
        if (note != null) 'note': note,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'application/json',
      ),
    );
    return Bill.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<Bill> updateBill({
    required String workspaceId,
    required String id,
    String? paymentType,
    RoundDetails? roundDetails,
    List<Item>? items,
    String? note,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    final token = await _getToken();
    final form = FormData();
    if (paymentType != null) {
      form.fields.add(MapEntry('paymentType', paymentType));
    }
    if (roundDetails != null) {
      form.fields.add(
        MapEntry('roundDetails', jsonEncode(roundDetails.toJson())),
      );
    }
    if (items != null) {
      form.fields.add(
        MapEntry('items', jsonEncode(items.map((i) => i.toJson()).toList())),
      );
    }
    if (note != null) {
      form.fields.add(MapEntry('note', note));
    }
    if (slipImageBytes != null && slipImageName != null) {
      form.files.add(
        MapEntry(
          'eSlip',
          MultipartFile.fromBytes(slipImageBytes, filename: slipImageName),
        ),
      );
    }

    final resp = await _dio.put(
      '/api/workspaces/$workspaceId/bills/$id',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );
    return Bill.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteBill({
    required String workspaceId,
    required String id,
  }) async {
    final token = await _getToken();
    await _dio.delete(
      '/api/workspaces/$workspaceId/bills/$id',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  /// Submit payment for a bill item
  ///
  /// This method allows a user to submit payment for one or more items in a bill
  /// by uploading a payment slip. The payment status will be set to 'awaiting_confirmation'
  /// or 'paid' depending on whether the user is the workspace owner.
  Future<Map<String, dynamic>> submitPayment({
    required String workspaceId,
    required String billId,
    required List<String> itemIds,
    required List<int> slipImageBytes,
    required String slipImageName,
  }) async {
    final token = await _getToken();

    final form = FormData();
    final itemIdJson = jsonEncode(itemIds);
    form.fields.add(MapEntry('itemId', itemIdJson));
    form.files.add(
      MapEntry(
        'eSlip',
        MultipartFile.fromBytes(slipImageBytes, filename: slipImageName),
      ),
    );

    final resp = await _dio.post(
      '/api/workspaces/$workspaceId/bills/$billId/pay',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );

    return resp.data;
  }

  /// Confirm payment for a bill item
  ///
  /// This method allows the bill creator to confirm payment for one or more items
  /// in a bill, changing the status from 'awaiting_confirmation' to 'paid'.
  Future<Map<String, dynamic>> confirmPayment({
    required String workspaceId,
    required String billId,
    required List<Map<String, String>> itemsToConfirm,
  }) async {
    final token = await _getToken();

    // Create form data with the items to confirm
    final form = FormData();

    // Convert items to the format expected by the server
    for (final item in itemsToConfirm) {
      form.fields.add(MapEntry('itemId', item['itemId'] ?? ''));
      form.fields
          .add(MapEntry('userIdToConfirm', item['userIdToConfirm'] ?? ''));
    }

    final resp = await _dio.patch(
      '/api/workspaces/$workspaceId/bills/$billId/confirm',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );

    return resp.data;
  }
}
