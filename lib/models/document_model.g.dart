// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentModelImpl _$$DocumentModelImplFromJson(Map<String, dynamic> json) =>
    _$DocumentModelImpl(
      id: json['_id'] as String,
      studentId: json['studentId'],
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: $enumDecode(_$PriorityLevelEnumMap, json['priority']),
      status: $enumDecodeNullable(_$DocumentStatusEnumMap, json['status']) ??
          DocumentStatus.pending,
      fileUrl: json['fileUrl'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      workflow: (json['workflow'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((e) => ApprovalModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DocumentModelImplToJson(_$DocumentModelImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'studentId': instance.studentId,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'priority': _$PriorityLevelEnumMap[instance.priority]!,
      'status': _$DocumentStatusEnumMap[instance.status]!,
      'fileUrl': instance.fileUrl,
      'rejectionReason': instance.rejectionReason,
      'workflow': instance.workflow,
      'approvals': instance.approvals,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PriorityLevelEnumMap = {
  PriorityLevel.low: 'low',
  PriorityLevel.medium: 'medium',
  PriorityLevel.high: 'high',
  PriorityLevel.urgent: 'urgent',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.pending: 'pending',
  DocumentStatus.approvedL1: 'approved_l1',
  DocumentStatus.approvedL2: 'approved_l2',
  DocumentStatus.officePending: 'office_pending',
  DocumentStatus.partiallyApproved: 'partially_approved',
  DocumentStatus.finalApproved: 'final_approved',
  DocumentStatus.rejected: 'rejected',
};
