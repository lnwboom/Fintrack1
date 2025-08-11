import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/data/models/request_model.dart';
import 'package:fintrack/features/workspace/request_controller.dart';
import 'package:fintrack/core/utils/snackbar_utils.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'dart:io';
import 'dart:convert';

class RequestFormScreen extends StatefulWidget {
  final WorkspaceModel workspace;

  const RequestFormScreen({
    Key? key,
    required this.workspace,
  }) : super(key: key);

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final RequestController _requestController = Get.find<RequestController>();
  final SecureStorage _storage = SecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isOwner = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final token = await _storage.read('jwt');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(
              base64Url.decode(
                base64Url.normalize(parts[1]),
              ),
            ),
          );
          final userId = payload['id'] as String;
          _isOwner = userId == widget.workspace.owner;
        }
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      final item = RequestItemModel(
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
      );

      _requestController.addItem(item);

      _descriptionController.clear();
      _priceController.clear();
      _quantityController.clear();

      setState(() {}); // อัพเดท UI
    }
  }

  void _removeItem(int index) {
    _requestController.removeItem(index);
    setState(() {}); // อัพเดท UI
  }

  Future<void> _selectProofFile() async {
    await _requestController.selectProofFile();
    setState(() {}); // อัพเดท UI เพื่อแสดงไฟล์ที่เลือก
  }

  Future<void> _submitRequest() async {
    if (_requestController.requestItems.isEmpty) {
      SnackbarUtils.showWarning(
          context, 'กรุณาเพิ่มรายการ', 'ต้องมีอย่างน้อย 1 รายการ');
      return;
    }

    if (_requestController.selectedProofFile.value == null) {
      SnackbarUtils.showWarning(
          context, 'กรุณาแนบไฟล์หลักฐาน', 'ต้องแนบไฟล์หลักฐานการเบิกจ่าย');
      return;
    }

    final success = await _requestController.createRequest(widget.workspace.id);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('สร้างคำขอเบิกจ่าย'),
          backgroundColor: const Color(0xFF638889),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ไม่สามารถสร้างคำขอได้',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'เจ้าของ workspace ไม่สามารถสร้างคำขอเบิกจ่ายได้\nเนื่องจากเป็นผู้ที่มีสิทธิ์ในการอนุมัติคำขอ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A6D8C),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('กลับ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างคำขอเบิกจ่าย'),
        backgroundColor: const Color(0xFF638889),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'รายการ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรายการ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'ราคา',
                            border: OutlineInputBorder(),
                            prefixText: '฿ ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกราคา';
                            }
                            if (double.tryParse(value) == null) {
                              return 'กรุณากรอกตัวเลข';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'จำนวน',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกจำนวน';
                            }
                            if (int.tryParse(value) == null) {
                              return 'กรุณากรอกตัวเลข';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มรายการ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A6D8C),
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'รายการที่เพิ่มแล้ว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Column(
                  children: _requestController.requestItems
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.description ?? 'ไม่ระบุรายการ'),
                        subtitle: Text('${item.price} บาท x ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.total} บาท',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),
            const SizedBox(height: 24),
            Obx(() => Text(
                  'รวมทั้งสิ้น: ${_requestController.totalAmount.value.toStringAsFixed(2)} บาท',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ไฟล์หลักฐานการเบิกจ่าย',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'กรุณาแนบไฟล์หลักฐานการเบิกจ่าย เช่น ใบเสร็จ, ใบแจ้งหนี้, หรือเอกสารอื่นๆ ที่เกี่ยวข้อง',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => _requestController.selectedProofFile.value != null
                          ? Row(
                              children: [
                                const Icon(Icons.attach_file),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _requestController
                                        .selectedProofFile.value!.path
                                        .split('/')
                                        .last,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _requestController.selectedProofFile.value =
                                        null;
                                    setState(() {});
                                  },
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _selectProofFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('เลือกไฟล์'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A6D8C),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GetBuilder<RequestController>(
              builder: (controller) => ElevatedButton.icon(
                onPressed:
                    controller.isSubmitting.value ? null : _submitRequest,
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  controller.isSubmitting.value ? 'กำลังส่งคำขอ...' : 'ส่งคำขอ',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A6D8C),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
