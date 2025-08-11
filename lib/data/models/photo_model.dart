import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:io';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
class PhotoModel with _$PhotoModel {
  const factory PhotoModel({
    required String id,
    required String path,
    required DateTime createDateTime,
    required int width,
    required int height,
    String? title,
    String? description,
  }) = _PhotoModel;

  factory PhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PhotoModelFromJson(json);

  factory PhotoModel.fromFile(File file, {String? title}) {
    return PhotoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: file.path,
      createDateTime: DateTime.now(),
      width: 0, // ค่าเริ่มต้น จะถูกอัปเดตเมื่อโหลดรูปภาพ
      height: 0, // ค่าเริ่มต้น จะถูกอัปเดตเมื่อโหลดรูปภาพ
      title: title,
    );
  }
}
