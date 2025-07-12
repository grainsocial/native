import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grain/api.dart';
import 'package:grain/screens/create_gallery_page.dart';
import 'package:grain/widgets/app_version_text.dart';
import 'package:grain/widgets/bottom_nav_bar.dart';
import 'package:grain/widgets/timeline_item.dart';

import '../providers/gallery_cache_provider.dart';
import 'explore_page.dart';
import 'log_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final int initialTab; // 0: Home, 1: Explore, 2: Notifications, 3: Profile
  final String? did;
  final VoidCallback? onSignOut;
  const MyHomePage({super.key, required this.title, this.initialTab = 0, this.did, this.onSignOut});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool showProfile = false;
  bool showNotifications = false;
  bool showExplore = false;
  List<String> _timelineUris = [];
  bool _timelineLoading = true;

  @override
  void initState() {
    super.initState();
    // Set tab state based on initialTab
    showProfile = widget.initialTab == 3;
    showExplore = widget.initialTab == 1;
    showNotifications = widget.initialTab == 2;
    _fetchTimeline();
  }

  Future<void> _fetchTimeline({String? algorithm}) async {
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _timelineLoading = true;
    });
    try {
      final galleries = await container.read(galleryCacheProvider.notifier).fetchTimeline();
      setState(() {
        _timelineUris = galleries.map((g) => g.uri).toList();
        _timelineLoading = false;
      });
    } catch (e) {
      setState(() {
        _timelineUris = [];
        _timelineLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _navIndex {
    if (showProfile) return 3;
    if (showNotifications) return 2;
    if (showExplore) return 1;
    return 0;
  }

  Widget _buildTimelineSliver(BuildContext context, {bool following = false}) {
    final loading = _timelineLoading;
    final uris = _timelineUris;
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchTimeline();
      },
      child: CustomScrollView(
        key: const PageStorageKey('timeline'),
        slivers: [
          if (uris.isEmpty && loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          if (uris.isEmpty && !loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No timeline items.')),
            ),
          if (uris.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final uri = uris[index];
                return TimelineItemWidget(galleryUri: uri);
              }, childCount: uris.length),
            ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(ThemeData theme, String? avatarUrl) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 115, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Icon(Icons.person, size: 44, color: theme.hintColor)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  apiService.currentUser?.displayName ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (apiService.currentUser?.handle != null)
                  Text(
                    '@${apiService.currentUser!.handle}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      (apiService.currentUser?.followersCount ?? 0).toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Followers',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      (apiService.currentUser?.followsCount ?? 0).toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Following',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.house),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                showProfile = false;
                showNotifications = false;
                showExplore = false;
              });
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.magnifyingGlass),
            title: const Text('Explore'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                showExplore = true;
                showProfile = false;
                showNotifications = false;
              });
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.user),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                showProfile = true;
                showNotifications = false;
                showExplore = false;
              });
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.list),
            title: const Text('Logs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LogPage()));
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(child: AppVersionText()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = apiService.currentUser?.avatar;
    if (apiService.currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
        ),
      );
    }
    // Home page: show default timeline only
    if (!showProfile && !showNotifications && !showExplore) {
      return Scaffold(
        onDrawerChanged: (isOpen) {
          setState(() {});
        },
        drawer: _buildAppDrawer(theme, avatarUrl),
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          surfaceTintColor: theme.appBarTheme.backgroundColor,
          elevation: 0.5,
          title: Text(widget.title),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: widget.onSignOut,
            ),
          ],
        ),
        body: _buildTimelineSliver(context),
        bottomNavigationBar: BottomNavBar(
          navIndex: _navIndex,
          onHome: () {
            setState(() {
              showProfile = false;
              showNotifications = false;
              showExplore = false;
            });
          },
          onExplore: () {
            setState(() {
              showProfile = false;
              showNotifications = false;
              showExplore = true;
            });
          },
          onNotifications: () {
            setState(() {
              showProfile = false;
              showNotifications = true;
              showExplore = false;
            });
          },
          onProfile: () {
            setState(() {
              showProfile = true;
              showNotifications = false;
              showExplore = false;
            });
          },
        ),
        floatingActionButton: (!showProfile && !showNotifications && !showExplore)
            ? FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final createdGalleryUri = await showCreateGallerySheet(context);
                  if (createdGalleryUri != null) {
                    _fetchTimeline();
                  }
                },
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                tooltip: 'Create Gallery',
                child: const Icon(Icons.add_a_photo),
              )
            : null,
      );
    }
    // Explore, Notifications, Profile: no tabs, no TabController
    return Scaffold(
      drawer: _buildAppDrawer(theme, avatarUrl),
      appBar: (showExplore || showNotifications)
          ? AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              surfaceTintColor: theme.appBarTheme.backgroundColor,
              elevation: 0.5,
              title: Text(
                showExplore ? 'Explore' : 'Notifications',
                style: theme.appBarTheme.titleTextStyle,
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: widget.onSignOut,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          if (showExplore)
            Positioned.fill(
              child: Material(
                color: theme.scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(child: Stack(children: [ExplorePage()])),
              ),
            ),
          if (showNotifications)
            Positioned.fill(
              child: Material(
                color: theme.scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(child: Stack(children: [NotificationsPage()])),
              ),
            ),
          if (showProfile)
            Positioned.fill(
              child: Material(
                color: theme.scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(
                  child: Stack(
                    children: [ProfilePage(did: apiService.currentUser?.did, showAppBar: false)],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        navIndex: _navIndex,
        onHome: () {
          setState(() {
            showProfile = false;
            showNotifications = false;
            showExplore = false;
          });
        },
        onExplore: () {
          setState(() {
            showProfile = false;
            showNotifications = false;
            showExplore = true;
          });
        },
        onNotifications: () {
          setState(() {
            showProfile = false;
            showNotifications = true;
            showExplore = false;
          });
        },
        onProfile: () {
          setState(() {
            showProfile = true;
            showNotifications = false;
            showExplore = false;
          });
        },
      ),
    );
  }
} // End of _MyHomePageState and file
