// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApprovalModelImpl _$$ApprovalModelImplFromJson(Map<String, dynamic> json) =>
    _$ApprovalModelImpl(
      id: json['_id'] as String?,
      approverId: json['approverId'],
      action: json['action'] as String,
      comment: json['comment'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ApprovalModelImplToJson(_$ApprovalModelImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'approverId': instance.approverId,
      'action': instance.action,
      'comment': instance.comment,
      'signatureUrl': instance.signatureUrl,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
