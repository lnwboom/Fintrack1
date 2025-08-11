import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fintrack/data/models/photo_model.dart';
import 'package:fintrack/core/utils/permission_handler.dart';

abstract class PhotoRepository {
  Future<List<PhotoModel>> getPhotos({int page = 0, int pageSize = 20});
  Future<PhotoModel?> getPhotoById(String id);
  Future<PhotoModel?> pickImageFromGallery();
  Future<PhotoModel?> takePhoto();
}

class PhotoRepositoryImpl implements PhotoRepository {
  final ImagePicker _imagePicker = ImagePicker();
  final List<PhotoModel> _cachedPhotos = [];

  @override
  Future<List<PhotoModel>> getPhotos({int page = 0, int pageSize = 20}) async {
    // ตรวจสอบสิทธิ์การเข้าถึงรูปภาพ
    final bool hasPermission = await PermissionService.checkPhotoPermission();
    if (!hasPermission) {
      final bool granted = await PermissionService.requestPhotoPermission();
      if (!granted) {
        return [];
      }
    }

    // คำนวณ start และ end index สำหรับการแบ่งหน้า
    final int startIndex = page * pageSize;
    final int endIndex = startIndex + pageSize;

    // ถ้ามีข้อมูลในแคชแล้ว ให้ส่งคืนข้อมูลจากแคช
    if (_cachedPhotos.isNotEmpty && startIndex < _cachedPhotos.length) {
      final int actualEndIndex =
          endIndex > _cachedPhotos.length ? _cachedPhotos.length : endIndex;
      return _cachedPhotos.sublist(startIndex, actualEndIndex);
    }

    return [];
  }

  @override
  Future<PhotoModel?> getPhotoById(String id) async {
    // ค้นหารูปภาพจาก ID ในแคช
    try {
      return _cachedPhotos.firstWhere((photo) => photo.id == id);
    } catch (e) {
      print('Error getting photo by ID: $e');
      return null;
    }
  }

  @override
  Future<PhotoModel?> pickImageFromGallery() async {
    try {
      // ตรวจสอบสิทธิ์การเข้าถึงรูปภาพ
      final bool hasPermission = await PermissionService.checkPhotoPermission();
      if (!hasPermission) {
        final bool granted = await PermissionService.requestPhotoPermission();
        if (!granted) {
          return null;
        }
      }

      // เลือกรูปภาพจากแกลเลอรี
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final PhotoModel photo =
            PhotoModel.fromFile(file, title: pickedFile.name);

        // เพิ่มรูปภาพลงในแคช
        _cachedPhotos.add(photo);

        return photo;
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }

    return null;
  }

  @override
  Future<PhotoModel?> takePhoto() async {
    try {
      // ตรวจสอบสิทธิ์การเข้าถึงกล้อง
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return null;
      }

      // ถ่ายรูปด้วยกล้อง
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final PhotoModel photo = PhotoModel.fromFile(file,
            title: 'Camera_${DateTime.now().toString()}');

        // เพิ่มรูปภาพลงในแคช
        _cachedPhotos.add(photo);

        return photo;
      }
    } catch (e) {
      print('Error taking photo: $e');
    }

    return null;
  }
}
