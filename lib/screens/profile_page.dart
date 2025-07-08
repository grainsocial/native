import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/app_theme.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/models/profile_with_galleries.dart';
import 'package:grain/providers/profile_provider.dart';
import 'package:grain/screens/hashtag_page.dart';
import 'package:grain/widgets/app_button.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/edit_profile_sheet.dart';
import 'package:grain/widgets/faceted_text.dart';
import 'package:grain/widgets/camera_pills.dart';
import 'package:url_launcher/url_launcher.dart';

import 'gallery_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final dynamic profile;
  final String? did;
  final bool showAppBar;
  const ProfilePage({super.key, this.profile, this.did, this.showAppBar = false});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with SingleTickerProviderStateMixin {
  List<Gallery> _favs = [];
  TabController? _tabController;
  bool _favsLoading = false;

  @override
  void initState() {
    super.initState();
    final did = widget.did ?? widget.profile?.did;
    final isOwnProfile = (apiService.currentUser?.did == did);
    _tabController = TabController(length: isOwnProfile ? 2 : 1, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() async {
    if (_tabController!.index == 1 && _favs.isEmpty && !_favsLoading) {
      if (mounted) {
        setState(() {
          _favsLoading = true;
        });
      }
      String? did = widget.did ?? widget.profile?.did;
      if (did != null && did.isNotEmpty) {
        try {
          final favs = await apiService.getActorFavs(did: did);
          if (mounted) {
            setState(() {
              _favs = favs;
              _favsLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _favs = [];
              _favsLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _favsLoading = false;
          });
        }
      }
    }
  }

  // Refactored: Just pop the sheet after save, don't return edited values
  Future<void> _handleProfileSave(
    String did,
    String displayName,
    String description,
    dynamic avatarFile,
  ) async {
    final notifier = ref.read(profileNotifierProvider(did).notifier);
    final success = await notifier.updateProfile(
      displayName: displayName,
      description: description,
      avatarFile: avatarFile,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      if (mounted) setState(() {}); // Force widget rebuild after modal closes
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final did = widget.did ?? widget.profile?.did;
    final asyncProfile = did != null
        ? ref.watch(profileNotifierProvider(did))
        : const AsyncValue<ProfileWithGalleries?>.loading();

    return asyncProfile.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text('Failed to load profile')),
      ),
      data: (profileWithGalleries) {
        if (profileWithGalleries == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: Text('Profile not found')),
          );
        }
        final profile = profileWithGalleries.profile;
        final galleries = profileWithGalleries.galleries;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: widget.showAppBar
              ? AppBar(
                  backgroundColor: theme.appBarTheme.backgroundColor,
                  surfaceTintColor: theme.appBarTheme.backgroundColor,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(color: theme.dividerColor, height: 1),
                  ),
                  leading: const BackButton(),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      if (profile.avatar != null)
                                        ClipOval(
                                          child: AppImage(
                                            url: profile.avatar,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.account_circle,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      const Spacer(),
                                      // Follow/Unfollow button
                                      if (profile.did != apiService.currentUser?.did)
                                        SizedBox(
                                          child: AppButton(
                                            size: AppButtonSize.small,
                                            variant: profile.viewer?.following?.isNotEmpty == true
                                                ? AppButtonVariant.secondary
                                                : AppButtonVariant.primary,
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    profileNotifierProvider(profile.did).notifier,
                                                  )
                                                  .toggleFollow(apiService.currentUser?.did);
                                            },
                                            label: (profile.viewer?.following?.isNotEmpty == true)
                                                ? 'Following'
                                                : 'Follow',
                                          ),
                                        )
                                      // Edit Profile button for current user
                                      else
                                        SizedBox(
                                          child: AppButton(
                                            size: AppButtonSize.small,
                                            variant: AppButtonVariant.secondary,
                                            onPressed: () async {
                                              showEditProfileSheet(
                                                context,
                                                initialDisplayName: profile.displayName,
                                                initialDescription: profile.description,
                                                initialAvatarUrl: profile.avatar,
                                                onSave:
                                                    (displayName, description, avatarFile) async {
                                                      await _handleProfileSave(
                                                        profile.did,
                                                        displayName,
                                                        description,
                                                        avatarFile,
                                                      );
                                                    },
                                                onCancel: () {
                                                  Navigator.of(context).maybePop();
                                                },
                                              );
                                            },
                                            label: 'Edit profile',
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.displayName ?? '',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${profile.handle}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileStatsRow(
                                    followers:
                                        (profile.followersCount is int
                                                ? profile.followersCount
                                                : int.tryParse(
                                                        profile.followersCount?.toString() ?? '0',
                                                      ) ??
                                                      0)
                                            .toString(),
                                    following:
                                        (profile.followsCount is int
                                                ? profile.followsCount
                                                : int.tryParse(
                                                        profile.followsCount?.toString() ?? '0',
                                                      ) ??
                                                      0)
                                            .toString(),
                                    galleries:
                                        (profile.galleryCount is int
                                                ? profile.galleryCount
                                                : int.tryParse(
                                                        profile.galleryCount?.toString() ?? '0',
                                                      ) ??
                                                      0)
                                            .toString(),
                                  ),
                                  if ((profile.cameras?.isNotEmpty ?? false)) ...[
                                    const SizedBox(height: 16),
                                    CameraPills(cameras: profile.cameras!),
                                  ],
                                  if ((profile.description ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    FacetedText(
                                      text: profile.description ?? '',
                                      facets: profile.descriptionFacets,
                                      onMentionTap: (didOrHandle) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePage(did: didOrHandle, showAppBar: true),
                                          ),
                                        );
                                      },
                                      onLinkTap: (url) async {
                                        final uri = Uri.parse(url);
                                        if (!await launchUrl(uri)) {
                                          throw Exception('Could not launch $url');
                                        }
                                      },
                                      onTagTap: (tag) => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HashtagPage(hashtag: tag),
                                        ),
                                      ),
                                      linkStyle: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            // TabBar with no horizontal padding
                            Container(
                              color: theme.scaffoldBackgroundColor,
                              child: TabBar(
                                dividerColor: theme.disabledColor,
                                controller: _tabController,
                                indicator: UnderlineTabIndicator(
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 3,
                                  ),
                                  insets: EdgeInsets.zero,
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: theme.colorScheme.onSurface,
                                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                tabs: [
                                  const Tab(text: 'Galleries'),
                                  if (apiService.currentUser?.did == profile.did)
                                    const Tab(text: 'Favs'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        // Galleries tab, edge-to-edge grid
                        galleries.isEmpty
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 3 / 4,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                                itemCount: 12, // Enough to fill the screen
                                itemBuilder: (context, index) {
                                  return Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                  );
                                },
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 3 / 4,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                                itemCount: (galleries.length < 12 ? 12 : galleries.length),
                                itemBuilder: (context, index) {
                                  if (galleries.isNotEmpty && index < galleries.length) {
                                    final gallery = galleries[index];
                                    final hasPhoto =
                                        gallery.items.isNotEmpty &&
                                        (gallery.items[0].thumb?.isNotEmpty ?? false);
                                    return GestureDetector(
                                      onTap: () {
                                        if (gallery.uri.isNotEmpty) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => GalleryPage(
                                                uri: gallery.uri,
                                                currentUserDid: apiService.currentUser?.did ?? '',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: hasPhoto
                                            ? AppImage(
                                                url: gallery.items[0].thumb,
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                child: Text(
                                                  gallery.title ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                      ),
                                    );
                                  }
                                  // Placeholder for empty slots
                                  return Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                  );
                                },
                              ),
                        // Favs tab
                        if (apiService.currentUser?.did == profile.did)
                          (_favsLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : _favs.isEmpty
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 3 / 4,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                                  itemCount: 12, // Enough to fill the screen
                                  itemBuilder: (context, index) {
                                    return Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                    );
                                  },
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 3 / 4,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                                  itemCount: _favs.length,
                                  itemBuilder: (context, index) {
                                    final gallery = _favs[index];
                                    final hasPhoto =
                                        gallery.items.isNotEmpty &&
                                        (gallery.items[0].thumb?.isNotEmpty ?? false);
                                    return GestureDetector(
                                      onTap: () {
                                        if (gallery.uri.isNotEmpty) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => GalleryPage(
                                                uri: gallery.uri,
                                                currentUserDid: apiService.currentUser?.did ?? '',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: hasPhoto
                                            ? AppImage(
                                                url: gallery.items[0].thumb,
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                child: Text(
                                                  gallery.title ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  final String followers;
  final String following;
  final String galleries;
  const _ProfileStatsRow({
    required this.followers,
    required this.following,
    required this.galleries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleCount = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14, // Set to 14
    );
    final styleLabel = TextStyle(
      color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700],
      fontSize: 14, // Set to 14
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(followers, style: styleCount),
        const SizedBox(width: 4),
        Text('followers', style: styleLabel),
        const SizedBox(width: 16),
        Text(following, style: styleCount),
        const SizedBox(width: 4),
        Text('following', style: styleLabel),
        const SizedBox(width: 16),
        Text(galleries, style: styleCount),
        const SizedBox(width: 4),
        Text('galleries', style: styleLabel),
      ],
    );
  }
}
