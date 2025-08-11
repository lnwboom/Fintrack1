import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fintrack/core/api/dio_client.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/core/storage/secure_storage.dart';

class WorkspaceService {
  final Dio _dio = DioClient.instance;
  static const _base = '/api/workspaces';
  final SecureStorage _storage = SecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read('jwt');
    debugPrint('Token: $token');
    return token;
  }

  Future<List<WorkspaceModel>> getAll() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    debugPrint('Making GET request to $_base');
    final resp = await _dio.get(
      _base,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from getAll: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final data = resp.data['data'] as List<dynamic>;
      final List<WorkspaceModel> workspaces = [];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            workspaces.add(WorkspaceModel.fromJson(item));
          } catch (e, s) {
            debugPrint(
                'Error parsing workspace item in getAll: $item, Error: $e, Stacktrace: $s');
          }
        } else {
          debugPrint('Skipping non-map item in workspace list (getAll): $item');
        }
      }
      return workspaces;
    }
    return [];
  }

  Future<WorkspaceModel> getById(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    debugPrint('Making GET request to $_base/$id (for enriching workspace)');
    final resp = await _dio.get(
      '$_base/$id',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from getById($id): ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final e = resp.data['data'] as Map<String, dynamic>;
      // This WorkspaceModel.fromJson should correctly parse members if they are full user objects
      return WorkspaceModel.fromJson(e);
    }
    throw Exception(
        'Workspace not found or failed to parse (getById). Response: ${resp.data}');
  }

  Future<WorkspaceModel> create(WorkspaceModel ws) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    debugPrint('Making POST request to $_base');
    debugPrint('Request data for create: ${ws.toJson()}');
    final resp = await _dio.post(
      _base,
      data: ws.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from create: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final e = resp.data['data'] as Map<String, dynamic>;
      return WorkspaceModel.fromJson(e);
    }
    throw Exception('Failed to create workspace. Response: ${resp.data}');
  }

  Future<WorkspaceModel> update(WorkspaceModel ws) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    // Update to use PUT instead of PATCH based on the backend implementation
    debugPrint('Making PUT request to $_base/${ws.id}');
    debugPrint('Request data for update: ${ws.toJson()}');
    final resp = await _dio.put(
      '$_base/${ws.id}',
      data: ws.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from update: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final e = resp.data['data'] as Map<String, dynamic>;
      return WorkspaceModel.fromJson(e);
    }
    throw Exception('Failed to update workspace. Response: ${resp.data}');
  }

  Future<void> delete(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    debugPrint('Making DELETE request to $_base/$id');
    final resp = await _dio.delete(
      '$_base/$id',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from delete: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] != true) {
      throw Exception('Failed to delete workspace. Response: ${resp.data}');
    }
  }

  Future<WorkspaceModel> createFromMap(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');
    final resp = await _dio.post(
      _base,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    if (resp.data['success'] == true && resp.data['data'] != null) {
      final e = resp.data['data'] as Map<String, dynamic>;
      return WorkspaceModel.fromJson(e);
    }
    throw Exception('Failed to create workspace. Response: ${resp.data}');
  }

  // New method for adding a member to a workspace
  Future<WorkspaceModel> addMember(String workspaceId, String email) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    debugPrint('Making POST request to $_base/$workspaceId/member');
    final resp = await _dio.post(
      '$_base/$workspaceId/member',
      data: {'email': email},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from addMember: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final e = resp.data['data'] as Map<String, dynamic>;
      return WorkspaceModel.fromJson(e);
    }
    throw Exception('Failed to add member to workspace. Response: ${resp.data}');
  }

  // New method for removing a member from a workspace
  Future<WorkspaceModel> removeMember(String workspaceId, String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    debugPrint('Making DELETE request to $_base/$workspaceId/member/$userId');
    final resp = await _dio.delete(
      '$_base/$workspaceId/member/$userId',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    debugPrint('Response from removeMember: ${resp.statusCode} - ${resp.data}');

    if (resp.data['success'] == true && resp.data['data'] != null) {
      final e = resp.data['data'] as Map<String, dynamic>;
      return WorkspaceModel.fromJson(e);
    }
    throw Exception('Failed to remove member from workspace. Response: ${resp.data}');
  }
}