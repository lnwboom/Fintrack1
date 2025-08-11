import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'components/profile_screen.dart';
import 'package:fintrack/features/home/transaction_controller.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:fintrack/features/home/ocr_controller.dart';
import 'package:fintrack/features/home/service/ocr_service.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

// Provider for OCR controller
final ocrControllerProvider = Provider<OcrController>((ref) => OcrController());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final OcrService _ocrService = OcrService();
  bool _isOcrProcessing = false;
  String? _ocrError;
  List<Map<String, dynamic>> _bankFolders = [];

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
    _checkPermissionsAndLoadBankFolders();
  }

  Future<void> _checkPermissionsAndLoadBankFolders() async {
    if (await _requestStoragePermission()) {
      await _scanForBankFolders();
    }
  }

  Future<bool> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;
    debugPrint('Permission.storage.status: $status');
    if (!status.isGranted) {
      status = await Permission.storage.request();
      debugPrint('Permission.storage.request: $status');
    }

    final manageStatus = await Permission.manageExternalStorage.status;
    debugPrint('Permission.manageExternalStorage.status: $manageStatus');
    if (!manageStatus.isGranted) {
      final req = await Permission.manageExternalStorage.request();
      debugPrint('Permission.manageExternalStorage.request: $req');
    }

    if (await Permission.manageExternalStorage.isGranted) {
      debugPrint('MANAGE_EXTERNAL_STORAGE granted');
      return true;
    }

    debugPrint('Final storage permission: ${status.isGranted}');
    return status.isGranted;
  }

  Future<void> _scanForBankFolders() async {
    try {
      setState(() {
        _bankFolders = [];
      });

      // Common bank folder names to search for
      final bankFolderNames = [
        'KPLUS', 'KBank', 'SCB', 'SCBEasy', 'BBL', 'BangkokBank',
        'KrungsriBank', 'Krungsri', 'TMB', 'TTB', 'UOB', 'GSB', 'KTB',
        // Add more bank names as needed
      ];

      // Get external storage directory
      final directories = await getExternalStorageDirectories();
      if (directories == null || directories.isEmpty) return;

      // Navigate up to find the root external storage
      Directory? rootDir;
      for (var dir in directories) {
        String path = dir.path;
        List<String> parts = path.split('/');
        int androidIndex = parts.indexOf('Android');
        if (androidIndex > 0) {
          rootDir = Directory(parts.sublist(0, androidIndex).join('/'));
          break;
        }
      }

      if (rootDir == null) return;

      // Search for bank folders in Downloads and Pictures directories
      final commonDirs = [
        Directory('${rootDir.path}/Download'),
        Directory('${rootDir.path}/DCIM'),
        Directory('${rootDir.path}/Pictures'),
      ];

      for (var dir in commonDirs) {
        if (!dir.existsSync()) continue;

        // List all subdirectories
        final entities = dir.listSync();
        for (var entity in entities) {
          if (entity is Directory) {
            final folderName = entity.path.split('/').last;

            // Check if this is a bank folder
            if (bankFolderNames.any((bank) =>
                folderName.toLowerCase().contains(bank.toLowerCase()))) {
              // Get the most recent image files
              final files = entity
                  .listSync()
                  .whereType<File>()
                  .where((file) =>
                      file.path.toLowerCase().endsWith('.jpg') ||
                      file.path.toLowerCase().endsWith('.jpeg') ||
                      file.path.toLowerCase().endsWith('.png'))
                  .toList();

              if (files.isNotEmpty) {
                // Sort by last modified date, most recent first
                files.sort((a, b) =>
                    b.statSync().modified.compareTo(a.statSync().modified));

                setState(() {
                  _bankFolders.add({
                    'name': folderName,
                    'path': entity.path,
                    'files': files,
                    'fileCount': files.length
                  });
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning bank folders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF638889),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildBankFolderSelection(context),
            _buildTransactionSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    debugPrint('Current user: ${user?.name}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              Text(
                user?.name ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF72c7cc),
                borderRadius: BorderRadius.circular(10.77),
              ),
              child: Center(
                child: Text(
                  user != null && user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankFolderSelection(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 48,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF9F9F9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bank Slips/Screenshots',
                style: TextStyle(
                  color: Color(0xFF3A3451),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF638889)),
                onPressed: _scanForBankFolders,
                tooltip: 'Refresh folders',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Show found bank folders
          if (_bankFolders.isEmpty)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.folder_off, color: Colors.grey, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'No bank folders found',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(context),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Select Images Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF638889),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount:
                    _bankFolders.length + 1, // +1 for the "All Images" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All Images" option as the first item
                    return _buildBankFolderCard(
                      'All Images',
                      'Select from any folder',
                      Icons.photo_library,
                      () => _pickImage(context),
                    );
                  } else {
                    final folder = _bankFolders[index - 1];
                    return _buildBankFolderCard(
                      folder['name'],
                      '${folder['fileCount']} images',
                      Icons.folder,
                      () => _openBankFolder(folder),
                    );
                  }
                },
              ),
            ),

          // Show OCR loading or error
          if (_isOcrProcessing)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing receipt...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

          if (_ocrError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _ocrError!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBankFolderCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF638889)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBankFolder(Map<String, dynamic> folder) async {
    try {
      final files = folder['files'] as List<File>;
      if (files.isEmpty) {
        setState(() {
          _ocrError = 'No images found in this folder';
        });
        return;
      }

      // Show image preview and selection dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select from ${folder['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: files.length > 9
                  ? 9
                  : files.length, // Limit to 9 recent images
              itemBuilder: (context, index) {
                final file = files[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _processImageWithOcr(file);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _ocrError = 'Error opening folder: $e';
      });
    }
  }

  Future<void> _processImageWithOcr(File imageFile) async {
    setState(() {
      _isOcrProcessing = true;
      _ocrError = null;
    });

    try {
      // Read the file bytes
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      // Process with OCR
      final transaction = await _ocrService.uploadImageForOcr(
        imageBytes: bytes,
        fileName: fileName,
      );

      setState(() {
        _isOcrProcessing = false;
      });

      if (transaction != null) {
        // Refresh transactions list
        ref.invalidate(transactionListProvider);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction created: ${transaction.amount} THB'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // You could navigate to transaction detail screen here
              },
            ),
          ),
        );
      } else {
        setState(() {
          _ocrError = 'Failed to process image. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isOcrProcessing = false;
        _ocrError = 'Error: ${e.toString()}';
      });
    }
  }

  Widget _buildTransactionSection(BuildContext context) {
    final transactionState = ref.watch(transactionListProvider);

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(transactionState),
            const SizedBox(height: 20),
            Text(
              'Transaction History',
              style: TextStyle(
                color: const Color(0xFF080422).withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactionState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
                data: (transactions) => ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildTransactionItem(transactions[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'food':
          return Icons.restaurant;
        case 'housing':
          return Icons.home;
        case 'utilities':
          return Icons.power;
        case 'transportation':
          return Icons.directions_car;
        case 'healthcare':
          return Icons.medical_services;
        case 'education':
          return Icons.school;
        case 'shopping':
          return Icons.shopping_bag;
        case 'entertainment':
          return Icons.movie;
        case 'telecommunications':
          return Icons.phone;
        case 'insurance':
          return Icons.security;
        case 'electronics':
          return Icons.devices;
        default:
          return Icons.category;
      }
    }

    String getCategoryLabel(String category) {
      switch (category.toLowerCase()) {
        case 'food':
          return 'อาหาร';
        case 'housing':
          return 'ที่อยู่อาศัย';
        case 'utilities':
          return 'ค่าสาธารณูปโภค';
        case 'transportation':
          return 'การเดินทาง';
        case 'healthcare':
          return 'สุขภาพ';
        case 'education':
          return 'การศึกษา';
        case 'shopping':
          return 'ช้อปปิ้ง';
        case 'entertainment':
          return 'บันเทิง';
        case 'telecommunications':
          return 'โทรคมนาคม';
        case 'insurance':
          return 'ประกันภัย';
        case 'electronics':
          return 'อิเล็กทรอนิกส์';
        default:
          return 'อื่นๆ';
      }
    }

    void _showCategoryBottomSheet() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'เลือกหมวดหมู่',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final categories = [
                    'food',
                    'housing',
                    'utilities',
                    'transportation',
                    'healthcare',
                    'education',
                    'shopping',
                    'entertainment',
                    'telecommunications',
                    'insurance',
                    'electronics',
                    'other'
                  ];
                  final category = categories[index];
                  return InkWell(
                    onTap: () async {
                      await ref.read(transactionListProvider.notifier).update(
                            id: tx.id,
                            category: category,
                          );
                      ref.invalidate(transactionListProvider);
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getCategoryIcon(category),
                          color: const Color(0xFF638889),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getCategoryLabel(category),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    getCategoryIcon(tx.category),
                    color: const Color(0xFF638889),
                  ),
                  title: Text(getCategoryLabel(tx.category)),
                  subtitle: Text(tx.description ?? '-'),
                  trailing: Text(
                    '${tx.amount.toStringAsFixed(2)} บาท',
                    style: TextStyle(
                      color: tx.type == 'Income' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF638889)),
                  title: const Text('แก้ไขหมวดหมู่'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryBottomSheet();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบรายการ'),
                  onTap: () async {
                    await ref
                        .read(transactionListProvider.notifier)
                        .remove(tx.id);
                    ref.invalidate(transactionListProvider);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showCategoryBottomSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF638889).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getCategoryIcon(tx.category),
                        color: const Color(0xFF638889),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getCategoryLabel(tx.category),
                          style: const TextStyle(
                            color: Color(0xFF080422),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          tx.description ?? '-',
                          style: TextStyle(
                            color: const Color(0xFF080422).withOpacity(0.5),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.amount.toStringAsFixed(2)} บาท',
                  style: TextStyle(
                    color: tx.type == 'Income' ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (tx.createdAt != null)
                  Text(
                    '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                    style: TextStyle(
                      color: const Color(0xFF080422).withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      AsyncValue<List<TransactionModel>> transactionState) {
    double earned = 0;
    double spent = 0;

    transactionState.whenData((transactions) {
      for (var tx in transactions) {
        if (tx.type == 'Income') {
          earned += tx.amount;
        } else {
          spent += tx.amount;
        }
      }
    });

    return Container(
      width: double.infinity,
      height: 83,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.11),
            offset: const Offset(0, 10),
            blurRadius: 50,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBalanceColumn(
              'Earned', earned.toStringAsFixed(2), const Color(0xFF086F3E)),
          _buildBalanceColumn(
              'Spent', spent.toStringAsFixed(2), const Color(0xFFFF7171)),
        ],
      ),
    );
  }

  Widget _buildBalanceColumn(String title, String amount, Color amountColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF080422).withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      // Request storage permission if needed
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        setState(() {
          _ocrError = 'Storage permission denied';
        });
        return;
      }

      // Use FilePicker to select image
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        await _processImageWithOcr(file);
      }
    } catch (e) {
      setState(() {
        _ocrError = 'Error picking image: $e';
      });
    }
  }

  Future<List<Directory>> _getExternalStorageDirectories() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectories() ?? [];
    }
    return [];
  }
}
