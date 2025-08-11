import 'package:dio/dio.dart';
import 'package:fintrack/core/api/dio_client.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

/// Service for handling OCR operations via Dio HTTP client.
class OcrService {
  final Dio _dio = DioClient.instance;
  static const _base = '/api/ocrslip/upload';
  final SecureStorage _storage = SecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read('jwt');
    if (token == null) {
      throw Exception('No token found');
    }
    debugPrint('Token: $token');
    return token;
  }

  /// Upload an image for OCR processing and transaction creation.
  /// Returns a list of created transactions from the OCR process.
  Future<List<TransactionModel>> uploadImagesForOcr({
    required List<Map<String, dynamic>> images,
  }) async {
    final token = await _getToken();

    // Create FormData with multiple files
    final formData = FormData();

    for (final image in images) {
      final bytes = image['bytes'] as List<int>;
      final fileName = image['fileName'] as String;

      String? mimeType;
      if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else {
        mimeType = 'application/octet-stream';
      }

      formData.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        ),
      );
    }

    final resp = await _dio.post(
      _base,
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Process the response
    final results = resp.data['results'] as List<dynamic>?;
    if (results == null) return [];

    // Filter only successful transactions
    final successfulTransactions = results
        .whereType<Map<String, dynamic>>()
        .where((result) => result['success'] == true)
        .map((result) {
      final data = result['data'] as Map<String, dynamic>;
      return TransactionModel.fromJson(data);
    }).toList();

    return successfulTransactions;
  }

  /// Upload a single image for OCR processing.
  Future<TransactionModel?> uploadImageForOcr({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final results = await uploadImagesForOcr(
      images: [
        {
          'bytes': imageBytes,
          'fileName': fileName,
        }
      ],
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Get the OCR processing results without creating transactions.
  /// This is useful for preview before confirming a transaction.
  Future<Map<String, dynamic>?> getOcrProcessingPreview({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final token = await _getToken();

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'images',
        MultipartFile.fromBytes(imageBytes, filename: fileName),
      ),
    );

    // Add a query parameter to indicate this is just for preview
    final resp = await _dio.post(
      '$_base?preview=true',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );

    final results = resp.data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final result = results.first as Map<String, dynamic>;
    if (result['success'] != true) return null;

    return result['data'] as Map<String, dynamic>?;
  }

  /// Check if an image hash already exists to avoid duplicates.
  Future<bool> checkDuplicateImage({
    required List<int> imageBytes,
  }) async {
    final token = await _getToken();

    // Calculate hash on client side
    final hash = await compute(_calculateHash, imageBytes);

    final resp = await _dio.post(
      '$_base/check-duplicate',
      data: {'hash': hash},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return resp.data['isDuplicate'] == true;
  }

  // Helper method to calculate hash in isolate
  static String _calculateHash(List<int> bytes) {
    // This is just a placeholder - in a real app, you would use
    // a proper hashing algorithm like SHA-256
    return bytes.length.toString(); // Not a real hash!
  }
}
