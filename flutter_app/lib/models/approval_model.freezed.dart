// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApprovalModel _$ApprovalModelFromJson(Map<String, dynamic> json) {
  return _ApprovalModel.fromJson(json);
}

/// @nodoc
mixin _$ApprovalModel {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  dynamic get approverId => throw _privateConstructorUsedError;
  String get action =>
      throw _privateConstructorUsedError; // approved, rejected, forwarded
  String? get comment => throw _privateConstructorUsedError;
  String? get signatureUrl => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ApprovalModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApprovalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApprovalModelCopyWith<ApprovalModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApprovalModelCopyWith<$Res> {
  factory $ApprovalModelCopyWith(
          ApprovalModel value, $Res Function(ApprovalModel) then) =
      _$ApprovalModelCopyWithImpl<$Res, ApprovalModel>;
  @useResult
  $Res call(
      {@JsonKey(name: '_id') String? id,
      dynamic approverId,
      String action,
      String? comment,
      String? signatureUrl,
      DateTime? createdAt});
}

/// @nodoc
class _$ApprovalModelCopyWithImpl<$Res, $Val extends ApprovalModel>
    implements $ApprovalModelCopyWith<$Res> {
  _$ApprovalModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApprovalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? approverId = freezed,
    Object? action = null,
    Object? comment = freezed,
    Object? signatureUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      approverId: freezed == approverId
          ? _value.approverId
          : approverId // ignore: cast_nullable_to_non_nullable
              as dynamic,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      signatureUrl: freezed == signatureUrl
          ? _value.signatureUrl
          : signatureUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApprovalModelImplCopyWith<$Res>
    implements $ApprovalModelCopyWith<$Res> {
  factory _$$ApprovalModelImplCopyWith(
          _$ApprovalModelImpl value, $Res Function(_$ApprovalModelImpl) then) =
      __$$ApprovalModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: '_id') String? id,
      dynamic approverId,
      String action,
      String? comment,
      String? signatureUrl,
      DateTime? createdAt});
}

/// @nodoc
class __$$ApprovalModelImplCopyWithImpl<$Res>
    extends _$ApprovalModelCopyWithImpl<$Res, _$ApprovalModelImpl>
    implements _$$ApprovalModelImplCopyWith<$Res> {
  __$$ApprovalModelImplCopyWithImpl(
      _$ApprovalModelImpl _value, $Res Function(_$ApprovalModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApprovalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? approverId = freezed,
    Object? action = null,
    Object? comment = freezed,
    Object? signatureUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ApprovalModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      approverId: freezed == approverId
          ? _value.approverId
          : approverId // ignore: cast_nullable_to_non_nullable
              as dynamic,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      signatureUrl: freezed == signatureUrl
          ? _value.signatureUrl
          : signatureUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApprovalModelImpl implements _ApprovalModel {
  const _$ApprovalModelImpl(
      {@JsonKey(name: '_id') this.id,
      required this.approverId,
      required this.action,
      this.comment,
      this.signatureUrl,
      this.createdAt});

  factory _$ApprovalModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApprovalModelImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final dynamic approverId;
  @override
  final String action;
// approved, rejected, forwarded
  @override
  final String? comment;
  @override
  final String? signatureUrl;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ApprovalModel(id: $id, approverId: $approverId, action: $action, comment: $comment, signatureUrl: $signatureUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApprovalModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other.approverId, approverId) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.signatureUrl, signatureUrl) ||
                other.signatureUrl == signatureUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(approverId),
      action,
      comment,
      signatureUrl,
      createdAt);

  /// Create a copy of ApprovalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApprovalModelImplCopyWith<_$ApprovalModelImpl> get copyWith =>
      __$$ApprovalModelImplCopyWithImpl<_$ApprovalModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApprovalModelImplToJson(
      this,
    );
  }
}

abstract class _ApprovalModel implements ApprovalModel {
  const factory _ApprovalModel(
      {@JsonKey(name: '_id') final String? id,
      required final dynamic approverId,
      required final String action,
      final String? comment,
      final String? signatureUrl,
      final DateTime? createdAt}) = _$ApprovalModelImpl;

  factory _ApprovalModel.fromJson(Map<String, dynamic> json) =
      _$ApprovalModelImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  dynamic get approverId;
  @override
  String get action; // approved, rejected, forwarded
  @override
  String? get comment;
  @override
  String? get signatureUrl;
  @override
  DateTime? get createdAt;

  /// Create a copy of ApprovalModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApprovalModelImplCopyWith<_$ApprovalModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
