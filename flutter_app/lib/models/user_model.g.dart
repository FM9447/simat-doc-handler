// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      registerNo: json['registerNo'] as String?,
      dept: json['dept'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
      token: json['token'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'registerNo': instance.registerNo,
      'dept': instance.dept,
      'signatureUrl': instance.signatureUrl,
      'token': instance.token,
      'isApproved': instance.isApproved,
    };
