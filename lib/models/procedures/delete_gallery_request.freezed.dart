// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delete_gallery_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DeleteGalleryRequest _$DeleteGalleryRequestFromJson(Map<String, dynamic> json) {
  return _DeleteGalleryRequest.fromJson(json);
}

/// @nodoc
mixin _$DeleteGalleryRequest {
  String get uri => throw _privateConstructorUsedError;

  /// Serializes this DeleteGalleryRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeleteGalleryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeleteGalleryRequestCopyWith<DeleteGalleryRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeleteGalleryRequestCopyWith<$Res> {
  factory $DeleteGalleryRequestCopyWith(
    DeleteGalleryRequest value,
    $Res Function(DeleteGalleryRequest) then,
  ) = _$DeleteGalleryRequestCopyWithImpl<$Res, DeleteGalleryRequest>;
  @useResult
  $Res call({String uri});
}

/// @nodoc
class _$DeleteGalleryRequestCopyWithImpl<
  $Res,
  $Val extends DeleteGalleryRequest
>
    implements $DeleteGalleryRequestCopyWith<$Res> {
  _$DeleteGalleryRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeleteGalleryRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? uri = null}) {
    return _then(
      _value.copyWith(
            uri: null == uri
                ? _value.uri
                : uri // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeleteGalleryRequestImplCopyWith<$Res>
    implements $DeleteGalleryRequestCopyWith<$Res> {
  factory _$$DeleteGalleryRequestImplCopyWith(
    _$DeleteGalleryRequestImpl value,
    $Res Function(_$DeleteGalleryRequestImpl) then,
  ) = __$$DeleteGalleryRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String uri});
}

/// @nodoc
class __$$DeleteGalleryRequestImplCopyWithImpl<$Res>
    extends _$DeleteGalleryRequestCopyWithImpl<$Res, _$DeleteGalleryRequestImpl>
    implements _$$DeleteGalleryRequestImplCopyWith<$Res> {
  __$$DeleteGalleryRequestImplCopyWithImpl(
    _$DeleteGalleryRequestImpl _value,
    $Res Function(_$DeleteGalleryRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeleteGalleryRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? uri = null}) {
    return _then(
      _$DeleteGalleryRequestImpl(
        uri: null == uri
            ? _value.uri
            : uri // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeleteGalleryRequestImpl implements _DeleteGalleryRequest {
  const _$DeleteGalleryRequestImpl({required this.uri});

  factory _$DeleteGalleryRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeleteGalleryRequestImplFromJson(json);

  @override
  final String uri;

  @override
  String toString() {
    return 'DeleteGalleryRequest(uri: $uri)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteGalleryRequestImpl &&
            (identical(other.uri, uri) || other.uri == uri));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uri);

  /// Create a copy of DeleteGalleryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteGalleryRequestImplCopyWith<_$DeleteGalleryRequestImpl>
  get copyWith =>
      __$$DeleteGalleryRequestImplCopyWithImpl<_$DeleteGalleryRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DeleteGalleryRequestImplToJson(this);
  }
}

abstract class _DeleteGalleryRequest implements DeleteGalleryRequest {
  const factory _DeleteGalleryRequest({required final String uri}) =
      _$DeleteGalleryRequestImpl;

  factory _DeleteGalleryRequest.fromJson(Map<String, dynamic> json) =
      _$DeleteGalleryRequestImpl.fromJson;

  @override
  String get uri;

  /// Create a copy of DeleteGalleryRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeleteGalleryRequestImplCopyWith<_$DeleteGalleryRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
