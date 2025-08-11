// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoModelImpl _$$PhotoModelImplFromJson(Map<String, dynamic> json) =>
    _$PhotoModelImpl(
      id: json['id'] as String,
      path: json['path'] as String,
      createDateTime: DateTime.parse(json['createDateTime'] as String),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      title: json['title'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$PhotoModelImplToJson(_$PhotoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'createDateTime': instance.createDateTime.toIso8601String(),
      'width': instance.width,
      'height': instance.height,
      'title': instance.title,
      'description': instance.description,
    };
