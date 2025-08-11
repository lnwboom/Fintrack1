import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fintrack/data/models/request_model.dart';
import 'package:fintrack/features/workspace/request_controller.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

// Utility function สำหรับเข้ารหัส URL
String _encodeUrl(String url) {
  try {
    // ลบช่องว่างและอักขระพิเศษที่ไม่ต้องการ
    url = url
        .trim()
        .replaceAll(RegExp(r'\s+'), '') // ลบช่องว่างทั้งหมด
        .replaceAll(RegExp(r'[^\x00-\x7F]+'), '') // ลบอักขระที่ไม่ใช่ ASCII
        .replaceAll('requesterr', 'requester') // แก้ไขการสะกดผิด
        .replaceAll(RegExp(r'\?$'), ''); // ลบเครื่องหมาย ? ที่อยู่ท้าย URL

    // แยก URL เป็นส่วนประกอบ
    final uri = Uri.parse(url);

    // ตรวจสอบความถูกต้องของ host
    if (!uri.host.contains('fintrack101.blob.core.windows.net')) {
      debugPrint('URL ไม่ถูกต้อง: ${uri.host}');
      throw Exception('Invalid host');
    }

    // เข้ารหัสแต่ละส่วนของ path
    final encodedPath = uri.path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) => Uri.encodeComponent(segment))
        .join('/');

    // สร้าง URL ใหม่โดยรวมส่วนประกอบทั้งหมด
    final encodedUrl = Uri(
      scheme: 'https', // กำหนด scheme เป็น https เสมอ
      host: uri.host,
      path: '/$encodedPath',
      queryParameters:
          uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
    ).toString();

    debugPrint('URL เดิม: $url');
    debugPrint('URL ใหม่: $encodedUrl');

    return encodedUrl;
  } catch (e) {
    debugPrint('เกิดข้อผิดพลาดในการเข้ารหัส URL: $e');
    // ถ้าเกิดข้อผิดพลาด ให้ทำความสะอาด URL แบบง่ายๆ
    final cleanUrl = url
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\x00-\x7F]+'), '')
        .replaceAll('requesterr', 'requester')
        .replaceAll(RegExp(r'\?$'), '');

    // ตรวจสอบว่า URL ยังคงถูกต้องหรือไม่
    if (cleanUrl.contains('fintrack101.blob.core.windows.net')) {
      return cleanUrl;
    }

    throw Exception('ไม่สามารถแก้ไข URL ได้: $url');
  }
}

class RequestDetailDialog extends StatelessWidget {
  final RequestModel request;
  final bool isOwner;
  final Function(RequestModel) onApprove;
  final Function(RequestModel) onReject;
  final Function(RequestModel) onDelete;

  const RequestDetailDialog({
    Key? key,
    required this.request,
    required this.isOwner,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  }) : super(key: key);

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    final encodedUrl = _encodeUrl(imageUrl);
    debugPrint('กำลังแสดงรูปภาพเต็มหน้าจอจาก URL: $encodedUrl');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _CachedRetryImage(
                imageUrl: encodedUrl,
                isFullScreen: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProofImage(
      BuildContext context, String? imageUrl, String label) {
    if (imageUrl == null) return const SizedBox.shrink();

    final encodedUrl = _encodeUrl(imageUrl);
    debugPrint('กำลังโหลดรูปภาพจาก URL: $encodedUrl');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullScreenImage(context, encodedUrl),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _CachedRetryImage(
                imageUrl: encodedUrl,
                isFullScreen: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF638889),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'รายละเอียดคำขอ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!isOwner || request.status != 'pending')
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(request);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                        'ผู้ขอเบิก', request.requester?.name ?? 'ไม่ระบุ'),
                    _buildDetailItem('วันที่', request.formattedDate),
                    _buildDetailItem('สถานะ', _getStatusText(request.status),
                        isBold: true),
                    if (request.rejectionReason != null)
                      _buildDetailItem(
                          'เหตุผลที่ปฏิเสธ', request.rejectionReason!),
                    const Divider(height: 32),
                    const Text(
                      'รายการ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...request.items.map((item) => Card(
                          child: ListTile(
                            title: Text(item.description ?? 'ไม่ระบุรายการ'),
                            subtitle:
                                Text('${item.price} บาท x ${item.quantity}'),
                            trailing: Text(
                              '${item.total} บาท',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'รวมทั้งสิ้น',
                      '${request.amount.toStringAsFixed(2)} บาท',
                      isBold: true,
                    ),
                    const Divider(height: 32),
                    if (request.requesterProof != null)
                      _buildProofImage(
                        context,
                        request.requesterProof!.url,
                        'หลักฐานการเบิกจ่าย',
                      ),
                    if (request.ownerProof != null)
                      _buildProofImage(
                        context,
                        request.ownerProof!.url,
                        'หลักฐานการอนุมัติ',
                      ),
                  ],
                ),
              ),
            ),
            if (isOwner && request.status == 'pending')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onReject(request);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('ปฏิเสธ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onApprove(request);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('อนุมัติ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รออนุมัติ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ไม่อนุมัติ';
      case 'completed':
        return 'เสร็จสิ้น';
      default:
        return status;
    }
  }
}

class _CachedRetryImage extends StatefulWidget {
  final String imageUrl;
  final bool isFullScreen;

  const _CachedRetryImage({
    required this.imageUrl,
    required this.isFullScreen,
  });

  @override
  State<_CachedRetryImage> createState() => _CachedRetryImageState();
}

class _CachedRetryImageState extends State<_CachedRetryImage> {
  int _retryCount = 0;
  Timer? _retryTimer;
  bool _isLoading = true;
  String? _error;
  bool _isDisposed = false;
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _progressController.close();
    super.dispose();
  }

  void _loadImage() {
    if (_isDisposed) return;

    _isLoading = true;
    _error = null;
    _currentProgress = 0.0;
    _progressController.add(0.0);
  }

  void _handleError(dynamic error) {
    if (_isDisposed) return;

    debugPrint('เกิดข้อผิดพลาดในการโหลดรูปภาพ: $error');

    if (_retryCount < 3) {
      _retryCount++;
      _error = 'กำลังลองโหลดใหม่... (ครั้งที่ $_retryCount)';

      Future.microtask(() {
        if (!_isDisposed) {
          setState(() {});
        }
      });

      final delay = Duration(seconds: _retryCount * 2);
      _retryTimer?.cancel();
      _retryTimer = Timer(delay, () {
        if (!_isDisposed) {
          _loadImage();
        }
      });
    } else {
      _isLoading = false;
      _error = 'ไม่สามารถโหลดรูปภาพได้\nกรุณาลองใหม่อีกครั้ง';

      Future.microtask(() {
        if (!_isDisposed) {
          setState(() {});
        }
      });
    }
  }

  Widget _buildLoadingIndicator(double? progress) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isFullScreen
                  ? Colors.white
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress != null
                ? 'กำลังโหลดรูปภาพ... ${(progress * 100).toStringAsFixed(0)}%'
                : 'กำลังโหลดรูปภาพ...',
            style: TextStyle(
              color: widget.isFullScreen ? Colors.white : Colors.black87,
              fontSize: widget.isFullScreen ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _retryCount < 3 ? Icons.refresh : Icons.error_outline,
            color: _retryCount < 3 ? Colors.orange : Colors.red,
            size: widget.isFullScreen ? 48 : 32,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _retryCount < 3 ? Colors.orange : Colors.red,
              fontSize: widget.isFullScreen ? 16 : 14,
            ),
          ),
          if (_retryCount >= 3) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _retryCount = 0;
                _isLoading = true;
                _error = null;
                _currentProgress = 0.0;
                _progressController.add(0.0);
                _loadImage();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    return StreamBuilder<double>(
      stream: _progressController.stream,
      initialData: 0.0,
      builder: (context, snapshot) {
        return Image.network(
          _encodeUrl(widget.imageUrl),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              _isLoading = false;
              if (!_isDisposed) {
                _currentProgress = 1.0;
                _progressController.add(1.0);
              }
              return child;
            }

            final newProgress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null;

            if (!_isDisposed && newProgress != null) {
              _currentProgress = newProgress;
              _progressController.add(newProgress);
            }

            return _buildLoadingIndicator(newProgress);
          },
          errorBuilder: (context, error, stackTrace) {
            Future.microtask(() => _handleError(error));
            return _buildLoadingIndicator(null);
          },
        );
      },
    );
  }
}
