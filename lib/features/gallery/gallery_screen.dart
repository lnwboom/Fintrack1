import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/data/models/photo_model.dart';
import 'package:fintrack/features/gallery/gallery_controller.dart';
//import 'dart:typed_data';
import 'dart:io';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();

    // เพิ่ม listener สำหรับการโหลดข้อมูลเพิ่มเติมเมื่อเลื่อนถึงด้านล่าง
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading) {
        _loadMorePhotos();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    await ref.read(galleryControllerProvider.notifier).loadPhotos();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMorePhotos() async {
    setState(() {
      _isLoading = true;
    });

    await ref.read(galleryControllerProvider.notifier).loadMorePhotos();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImageFromGallery() async {
    await ref.read(galleryControllerProvider.notifier).pickImageFromGallery();
  }

  Future<void> _takePhoto() async {
    await ref.read(galleryControllerProvider.notifier).takePhoto();
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รูปภาพ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImageFromGallery,
            tooltip: 'เลือกรูปภาพจากแกลเลอรี',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _takePhoto,
            tooltip: 'ถ่ายรูป',
          ),
        ],
      ),
      body: galleryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('เกิดข้อผิดพลาด: $error')),
        data: (state) {
          if (state.photos.isEmpty) {
            return const Center(
                child: Text('ไม่พบรูปภา55555555พ กรุณาเลือกรูปภาพหรือถ่ายรูป'));
          }

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: state.photos.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.photos.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final photo = state.photos[index];
              return _buildPhotoItem(photo);
            },
          );
        },
      ),
    );
  }

  Widget _buildPhotoItem(PhotoModel photo) {
    return GestureDetector(
      onTap: () {
        // แสดงรูปภาพแบบเต็มหน้าจอ
        _showFullScreenImage(photo);
      },
      child: Hero(
        tag: 'photo_${photo.id}',
        child: Image.file(
          File(photo.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  void _showFullScreenImage(PhotoModel photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(photo.title ?? 'รูปภาพ'),
          ),
          body: Center(
            child: Hero(
              tag: 'photo_${photo.id}',
              child: Image.file(
                File(photo.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
