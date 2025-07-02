import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/api.dart';
import 'gallery_page.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final dynamic profile;
  final String? did;
  final bool showAppBar;
  const ProfilePage({
    super.key,
    this.profile,
    this.did,
    this.showAppBar = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  dynamic _profile;
  bool _loading = true;
  List<Gallery> _galleries = [];
  List<Gallery> _favs = [];
  TabController? _tabController;
  bool _favsLoading = false;
  bool _galleriesLoading = false;

  @override
  void initState() {
    super.initState();
    final did = widget.did ?? widget.profile?.did;
    final isOwnProfile = (apiService.currentUser?.did == did);
    _tabController = TabController(length: isOwnProfile ? 2 : 1, vsync: this);
    _tabController!.addListener(_onTabChanged);
    _fetchProfileAndGalleries();
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
      String? did = (_profile ?? widget.profile)?.did;
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

  Future<void> _fetchProfileAndGalleries() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    String? did = widget.did ?? widget.profile?.did;
    if (did == null || did.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    final profile = await apiService.fetchProfile(did: did);
    final galleries = await apiService.fetchActorGalleries(did: did);
    if (mounted) {
      setState(() {
        _profile = profile;
        _galleries = galleries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _profile ?? widget.profile;
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }
    if (profile == null) {
      return const Center(child: Text('No profile data'));
    }
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
                              if (profile.avatar != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ClipOval(
                                    child: AppImage(
                                      url: profile.avatar,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.account_circle,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
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
                                '@${profile.handle ?? ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
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
                                                    profile.followersCount
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0)
                                        .toString(),
                                following:
                                    (profile.followsCount is int
                                            ? profile.followsCount
                                            : int.tryParse(
                                                    profile.followsCount
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0)
                                        .toString(),
                                galleries:
                                    (profile.galleryCount is int
                                            ? profile.galleryCount
                                            : int.tryParse(
                                                    profile.galleryCount
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0)
                                        .toString(),
                              ),
                              if ((profile.description ?? '').isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  profile.description,
                                  textAlign: TextAlign.left,
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
                            unselectedLabelColor:
                                theme.colorScheme.onSurfaceVariant,
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
                    _galleriesLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : _galleries.isEmpty
                        ? const Center(child: Text('No galleries yet'))
                        : GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 3 / 4,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                            itemCount: (_galleries.length < 12
                                ? 12
                                : _galleries.length),
                            itemBuilder: (context, index) {
                              if (_galleries.isNotEmpty &&
                                  index < _galleries.length) {
                                final gallery = _galleries[index];
                                final hasPhoto =
                                    gallery.items.isNotEmpty &&
                                    gallery.items[0].thumb.isNotEmpty;
                                return GestureDetector(
                                  onTap: () {
                                    if (gallery.uri.isNotEmpty) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => GalleryPage(
                                            uri: gallery.uri,
                                            currentUserDid: profile.did,
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
                                              gallery.title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                  ),
                                );
                              }
                              // Placeholder for empty slots
                              return Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                          ? const Center(child: Text('No favorites yet'))
                          : GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    gallery.items[0].thumb.isNotEmpty;
                                return GestureDetector(
                                  onTap: () {
                                    if (gallery.uri.isNotEmpty) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => GalleryPage(
                                            uri: gallery.uri,
                                            currentUserDid: profile.did,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasPhoto
                                        ? AppImage(
                                            url: gallery.items[0].thumb,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Text(
                                              gallery.title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
      color: theme.brightness == Brightness.dark
          ? Colors.grey[400]
          : Colors.grey[700],
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
