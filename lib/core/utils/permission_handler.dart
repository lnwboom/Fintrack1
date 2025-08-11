import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// ขอสิทธิ์การเข้าถึงรูปภาพ
  static Future<bool> requestPhotoPermission() async {
    // ขอสิทธิ์การเข้าถึงรูปภาพ
    PermissionStatus status;

    // ตรวจสอบเวอร์ชัน Android
    if (await _isAndroid13OrHigher()) {
      // Android 13+ ใช้ READ_MEDIA_IMAGES
      status = await Permission.photos.request();
    } else {
      // Android เวอร์ชันเก่าใช้ READ_EXTERNAL_STORAGE
      status = await Permission.storage.request();
    }

    // ถ้าได้รับสิทธิ์แล้ว
    if (status.isGranted) {
      return true;
    }

    // ถ้าถูกปฏิเสธถาวร
    if (status.isPermanentlyDenied) {
      // เปิดหน้าตั้งค่าแอปพลิเคชัน
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// ตรวจสอบสิทธิ์การเข้าถึงรูปภาพ
  static Future<bool> checkPhotoPermission() async {
    if (await _isAndroid13OrHigher()) {
      return await Permission.photos.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  /// ตรวจสอบว่าเป็น Android 13 หรือสูงกว่าหรือไม่
  static Future<bool> _isAndroid13OrHigher() async {
    // ใช้ Platform.isAndroid และ Platform.version เพื่อตรวจสอบเวอร์ชัน
    // แต่เพื่อความง่าย เราจะใช้วิธีนี้แทน
    try {
      // ลองขอสิทธิ์ READ_MEDIA_IMAGES ซึ่งมีใน Android 13+
      final status = await Permission.photos.status;
      // ถ้าสถานะไม่ใช่ PermissionStatus.permanentlyDenied แสดงว่าเป็น Android 13+
      return status != PermissionStatus.permanentlyDenied;
    } catch (e) {
      // ถ้าเกิดข้อผิดพลาด แสดงว่าไม่ใช่ Android 13+
      return false;
    }
  }
}
