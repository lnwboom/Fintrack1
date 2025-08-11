import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:fintrack/core/api/dio_client.dart';
import 'package:fintrack/data/models/request_model.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'dart:io';

class RequestService {
  final Dio _dio = DioClient.instance;
  final SecureStorage _storage = SecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read('jwt');
    debugPrint('Token: $token');
    return token;
  }

  // Get all requests within a workspace
  Future<List<RequestModel>> getAllByWorkspace(String workspaceId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests';
    debugPrint('Making GET request to $endpoint');

    final resp = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint(
        'Response from getAllByWorkspace: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final data = resp.data['data'] as List<dynamic>;
      final List<RequestModel> requests = [];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            requests.add(RequestModel.fromJson(item));
          } catch (e, s) {
            debugPrint(
                'Error parsing request item: $item, Error: $e, Stacktrace: $s');
          }
        } else {
          debugPrint('Skipping non-map item in request list: $item');
        }
      }
      return requests;
    }
    return [];
  }

  // Get my requests (current user's requests in a workspace)
  Future<List<RequestModel>> getMyRequestsByWorkspace(
      String workspaceId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests/my-requests';
    debugPrint('Making GET request to $endpoint');

    final resp = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint(
        'Response from getMyRequestsByWorkspace: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final data = resp.data['data'] as List<dynamic>;
      final List<RequestModel> requests = [];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            requests.add(RequestModel.fromJson(item));
          } catch (e, s) {
            debugPrint(
                'Error parsing request item: $item, Error: $e, Stacktrace: $s');
          }
        } else {
          debugPrint('Skipping non-map item in request list: $item');
        }
      }
      return requests;
    }
    return [];
  }

  // Get a request by ID
  Future<RequestModel> getById(String workspaceId, String requestId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests/$requestId';
    debugPrint('Making GET request to $endpoint');

    final resp = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint(
        'Response from getById($requestId): ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final requestData = resp.data['data'] as Map<String, dynamic>;
      return RequestModel.fromJson(requestData);
    }
    throw Exception(
        'Request not found or failed to parse. Response: ${resp.data}');
  }

  // Create a new request in a workspace
  Future<RequestModel> create(String workspaceId,
      Map<String, dynamic> requestData, File? proofFile) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests';
    debugPrint('Making POST request to $endpoint');

    // Set up multipart request if there's a file
    FormData formData = FormData();

    // Add JSON data fields
    for (var entry in requestData.entries) {
      if (entry.key == 'items') {
        formData.fields.add(MapEntry(entry.key, jsonEncode(entry.value)));
      } else {
        formData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
    }

    // Add proof file if provided
    if (proofFile != null) {
      final fileName = proofFile.path.split('/').last;
      formData.files.add(MapEntry(
        'requesterProof',
        await MultipartFile.fromFile(
          proofFile.path,
          filename: fileName,
        ),
      ));
    }

    final resp = await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from create: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final responseData = resp.data['data'] as Map<String, dynamic>;
      return RequestModel.fromJson(responseData);
    }
    throw Exception('Failed to create request. Response: ${resp.data}');
  }

  // Update an existing request
  Future<RequestModel> update(String workspaceId, String requestId,
      Map<String, dynamic> requestData, File? proofFile) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests/$requestId';
    debugPrint('Making PUT request to $endpoint');

    // Set up multipart request if there's a file
    FormData formData = FormData();

    // Add JSON data fields
    for (var entry in requestData.entries) {
      if (entry.key == 'items') {
        formData.fields.add(MapEntry(entry.key, jsonEncode(entry.value)));
      } else {
        formData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
    }

    // Add proof file if provided
    if (proofFile != null) {
      final fileName = proofFile.path.split('/').last;
      formData.files.add(MapEntry(
        'requesterProof',
        await MultipartFile.fromFile(
          proofFile.path,
          filename: fileName,
        ),
      ));
    }

    final resp = await _dio.put(
      endpoint,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from update: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final responseData = resp.data['data'] as Map<String, dynamic>;
      return RequestModel.fromJson(responseData);
    }
    throw Exception('Failed to update request. Response: ${resp.data}');
  }

  // Update request status (approve or reject)
  Future<Map<String, dynamic>> updateStatus(
    String workspaceId,
    String requestId,
    String status, {
    String? rejectionReason,
    File? ownerProofFile,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests/$requestId/status';
    debugPrint('Making PUT request to $endpoint with status $status');

    // Set up multipart request
    FormData formData = FormData();
    formData.fields.add(MapEntry('status', status));

    if (status == 'rejected' && rejectionReason != null) {
      formData.fields.add(MapEntry('rejectionReason', rejectionReason));
    }

    // Add owner proof file if approving
    if (status == 'approved' && ownerProofFile != null) {
      final fileName = ownerProofFile.path.split('/').last;
      formData.files.add(MapEntry(
        'ownerProof',
        await MultipartFile.fromFile(
          ownerProofFile.path,
          filename: fileName,
        ),
      ));
    }

    final resp = await _dio.put(
      endpoint,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from updateStatus: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      return resp.data['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to update request status. Response: ${resp.data}');
  }

  // Delete a request
  Future<bool> delete(String workspaceId, String requestId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    final endpoint = '/api/workspaces/$workspaceId/requests/$requestId';
    debugPrint('Making DELETE request to $endpoint');

    final resp = await _dio.delete(
      endpoint,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from delete: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true) {
      return true;
    }
    throw Exception('Failed to delete request. Response: ${resp.data}');
  }
}
