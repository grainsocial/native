// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'atproto_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AtprotoSession _$AtprotoSessionFromJson(Map<String, dynamic> json) {
  return _AtprotoSession.fromJson(json);
}

/// @nodoc
mixin _$AtprotoSession {
  String get accessToken => throw _privateConstructorUsedError;
  String get tokenType => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  JsonWebKey get dpopJwk => throw _privateConstructorUsedError;
  String get issuer => throw _privateConstructorUsedError;
  String get subject => throw _privateConstructorUsedError;

  /// Serializes this AtprotoSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AtprotoSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AtprotoSessionCopyWith<AtprotoSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AtprotoSessionCopyWith<$Res> {
  factory $AtprotoSessionCopyWith(
    AtprotoSession value,
    $Res Function(AtprotoSession) then,
  ) = _$AtprotoSessionCopyWithImpl<$Res, AtprotoSession>;
  @useResult
  $Res call({
    String accessToken,
    String tokenType,
    DateTime expiresAt,
    JsonWebKey dpopJwk,
    String issuer,
    String subject,
  });
}

/// @nodoc
class _$AtprotoSessionCopyWithImpl<$Res, $Val extends AtprotoSession>
    implements $AtprotoSessionCopyWith<$Res> {
  _$AtprotoSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AtprotoSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? tokenType = null,
    Object? expiresAt = null,
    Object? dpopJwk = null,
    Object? issuer = null,
    Object? subject = null,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            tokenType: null == tokenType
                ? _value.tokenType
                : tokenType // ignore: cast_nullable_to_non_nullable
                      as String,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dpopJwk: null == dpopJwk
                ? _value.dpopJwk
                : dpopJwk // ignore: cast_nullable_to_non_nullable
                      as JsonWebKey,
            issuer: null == issuer
                ? _value.issuer
                : issuer // ignore: cast_nullable_to_non_nullable
                      as String,
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AtprotoSessionImplCopyWith<$Res>
    implements $AtprotoSessionCopyWith<$Res> {
  factory _$$AtprotoSessionImplCopyWith(
    _$AtprotoSessionImpl value,
    $Res Function(_$AtprotoSessionImpl) then,
  ) = __$$AtprotoSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accessToken,
    String tokenType,
    DateTime expiresAt,
    JsonWebKey dpopJwk,
    String issuer,
    String subject,
  });
}

/// @nodoc
class __$$AtprotoSessionImplCopyWithImpl<$Res>
    extends _$AtprotoSessionCopyWithImpl<$Res, _$AtprotoSessionImpl>
    implements _$$AtprotoSessionImplCopyWith<$Res> {
  __$$AtprotoSessionImplCopyWithImpl(
    _$AtprotoSessionImpl _value,
    $Res Function(_$AtprotoSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AtprotoSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? tokenType = null,
    Object? expiresAt = null,
    Object? dpopJwk = null,
    Object? issuer = null,
    Object? subject = null,
  }) {
    return _then(
      _$AtprotoSessionImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        tokenType: null == tokenType
            ? _value.tokenType
            : tokenType // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dpopJwk: null == dpopJwk
            ? _value.dpopJwk
            : dpopJwk // ignore: cast_nullable_to_non_nullable
                  as JsonWebKey,
        issuer: null == issuer
            ? _value.issuer
            : issuer // ignore: cast_nullable_to_non_nullable
                  as String,
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AtprotoSessionImpl implements _AtprotoSession {
  const _$AtprotoSessionImpl({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.dpopJwk,
    required this.issuer,
    required this.subject,
  });

  factory _$AtprotoSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AtprotoSessionImplFromJson(json);

  @override
  final String accessToken;
  @override
  final String tokenType;
  @override
  final DateTime expiresAt;
  @override
  final JsonWebKey dpopJwk;
  @override
  final String issuer;
  @override
  final String subject;

  @override
  String toString() {
    return 'AtprotoSession(accessToken: $accessToken, tokenType: $tokenType, expiresAt: $expiresAt, dpopJwk: $dpopJwk, issuer: $issuer, subject: $subject)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AtprotoSessionImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.tokenType, tokenType) ||
                other.tokenType == tokenType) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.dpopJwk, dpopJwk) || other.dpopJwk == dpopJwk) &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.subject, subject) || other.subject == subject));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessToken,
    tokenType,
    expiresAt,
    dpopJwk,
    issuer,
    subject,
  );

  /// Create a copy of AtprotoSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AtprotoSessionImplCopyWith<_$AtprotoSessionImpl> get copyWith =>
      __$$AtprotoSessionImplCopyWithImpl<_$AtprotoSessionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AtprotoSessionImplToJson(this);
  }
}

abstract class _AtprotoSession implements AtprotoSession {
  const factory _AtprotoSession({
    required final String accessToken,
    required final String tokenType,
    required final DateTime expiresAt,
    required final JsonWebKey dpopJwk,
    required final String issuer,
    required final String subject,
  }) = _$AtprotoSessionImpl;

  factory _AtprotoSession.fromJson(Map<String, dynamic> json) =
      _$AtprotoSessionImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get tokenType;
  @override
  DateTime get expiresAt;
  @override
  JsonWebKey get dpopJwk;
  @override
  String get issuer;
  @override
  String get subject;

  /// Create a copy of AtprotoSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AtprotoSessionImplCopyWith<_$AtprotoSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
