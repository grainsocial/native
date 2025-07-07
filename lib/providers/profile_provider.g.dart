// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileNotifierHash() => r'0a4d40043196309ae74bdb3b88d7d63d25b8b4f6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ProfileNotifier
    extends BuildlessAsyncNotifier<ProfileWithGalleries?> {
  late final String did;

  FutureOr<ProfileWithGalleries?> build(String did);
}

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
const profileNotifierProvider = ProfileNotifierFamily();

/// See also [ProfileNotifier].
class ProfileNotifierFamily extends Family<AsyncValue<ProfileWithGalleries?>> {
  /// See also [ProfileNotifier].
  const ProfileNotifierFamily();

  /// See also [ProfileNotifier].
  ProfileNotifierProvider call(String did) {
    return ProfileNotifierProvider(did);
  }

  @override
  ProfileNotifierProvider getProviderOverride(
    covariant ProfileNotifierProvider provider,
  ) {
    return call(provider.did);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profileNotifierProvider';
}

/// See also [ProfileNotifier].
class ProfileNotifierProvider
    extends AsyncNotifierProviderImpl<ProfileNotifier, ProfileWithGalleries?> {
  /// See also [ProfileNotifier].
  ProfileNotifierProvider(String did)
    : this._internal(
        () => ProfileNotifier()..did = did,
        from: profileNotifierProvider,
        name: r'profileNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$profileNotifierHash,
        dependencies: ProfileNotifierFamily._dependencies,
        allTransitiveDependencies:
            ProfileNotifierFamily._allTransitiveDependencies,
        did: did,
      );

  ProfileNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.did,
  }) : super.internal();

  final String did;

  @override
  FutureOr<ProfileWithGalleries?> runNotifierBuild(
    covariant ProfileNotifier notifier,
  ) {
    return notifier.build(did);
  }

  @override
  Override overrideWith(ProfileNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileNotifierProvider._internal(
        () => create()..did = did,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        did: did,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<ProfileNotifier, ProfileWithGalleries?>
  createElement() {
    return _ProfileNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileNotifierProvider && other.did == did;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, did.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileNotifierRef on AsyncNotifierProviderRef<ProfileWithGalleries?> {
  /// The parameter `did` of this provider.
  String get did;
}

class _ProfileNotifierProviderElement
    extends AsyncNotifierProviderElement<ProfileNotifier, ProfileWithGalleries?>
    with ProfileNotifierRef {
  _ProfileNotifierProviderElement(super.provider);

  @override
  String get did => (origin as ProfileNotifierProvider).did;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
