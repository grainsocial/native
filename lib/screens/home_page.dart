import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/widgets/timeline_item.dart';
import 'package:grain/widgets/app_version_text.dart';
import 'package:grain/widgets/bottom_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'explore_page.dart';
import 'log_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/screens/create_gallery_page.dart';

class TimelineItem {
  final Gallery gallery;
  TimelineItem({required this.gallery});
  factory TimelineItem.fromGallery(Gallery gallery) {
    return TimelineItem(gallery: gallery);
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final VoidCallback? onSignOut;
  const MyHomePage({super.key, required this.title, this.onSignOut});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool showProfile = false;
  bool showNotifications = false;
  bool showExplore = false;
  List<TimelineItem> _timeline = [];
  List<TimelineItem> _followingTimeline = [];
  bool _timelineLoading = true;
  bool _followingTimelineLoading = false;
  int _tabIndex = 0; // 0 = Timeline, 1 = Following
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
    _initTabController();
  }

  Future<void> _fetchTimeline({String? algorithm}) async {
    if (algorithm == "following") {
      setState(() {
        _followingTimelineLoading = true;
      });
      try {
        final galleries = await apiService.getTimeline(algorithm: algorithm);
        setState(() {
          _followingTimeline = galleries
              .map((g) => TimelineItem.fromGallery(g))
              .toList();
          _followingTimelineLoading = false;
        });
      } catch (e) {
        setState(() {
          _followingTimeline = [];
          _followingTimelineLoading = false;
        });
      }
    } else {
      setState(() {
        _timelineLoading = true;
      });
      try {
        final galleries = await apiService.getTimeline(algorithm: algorithm);
        setState(() {
          _timeline = galleries
              .map((g) => TimelineItem.fromGallery(g))
              .toList();
          _timelineLoading = false;
        });
      } catch (e) {
        setState(() {
          _timeline = [];
          _timelineLoading = false;
        });
      }
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _tabIndex = index;
    });
    if (index == 1) {
      _fetchTimeline(algorithm: "following");
    } else {
      _fetchTimeline();
    }
  }

  void _initTabController() {
    _tabController?.dispose();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _tabIndex,
    );
    _tabController!.addListener(() {
      if (_tabController!.index != _tabIndex) {
        _onTabChanged(_tabController!.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tabController == null || _tabController!.length != 2) {
      _initTabController();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  int get _navIndex {
    if (showProfile) return 3;
    if (showNotifications) return 2;
    if (showExplore) return 1;
    return 0;
  }

  Widget _buildTimelineSliver(BuildContext context, {bool following = false}) {
    final loading = following ? _followingTimelineLoading : _timelineLoading;
    final timeline = following ? _followingTimeline : _timeline;
    return CustomScrollView(
      key: PageStorageKey(following ? 'following' : 'timeline'),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        if (timeline.isEmpty && loading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        if (timeline.isEmpty && !loading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                following
                    ? 'No following timeline items.'
                    : 'No timeline items.',
              ),
            ),
          ),
        if (timeline.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = timeline[index];
              return TimelineItemWidget(gallery: item.gallery);
            }, childCount: timeline.length),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (apiService.currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }
    // Home page: show tabs
    if (!showProfile && !showNotifications && !showExplore) {
      if (_tabController == null) _initTabController();
      return Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 115, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: ClipOval(
                        child: AppImage(
                          url: apiService.currentUser!.avatar,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          (apiService.currentUser?.followersCount ?? 0)
                              .toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Followers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          (apiService.currentUser?.followsCount ?? 0)
                              .toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Following',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LogPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(child: AppVersionText()),
              ),
            ],
          ),
        ),
        body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                backgroundColor: theme.appBarTheme.backgroundColor,
                surfaceTintColor: theme.appBarTheme.backgroundColor,
                floating: false,
                snap: false,
                pinned: true,
                elevation: 0.5,
                title: Text(
                  widget.title,
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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: TabBar(
                      dividerColor: theme.dividerColor,
                      controller: _tabController,
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
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
                      tabs: const [
                        Tab(text: 'Timeline'),
                        Tab(text: 'Following'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Builder(
                builder: (context) =>
                    _buildTimelineSliver(context, following: false),
              ),
              Builder(
                builder: (context) =>
                    _buildTimelineSliver(context, following: true),
              ),
            ],
          ),
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
          avatarUrl: apiService.currentUser?.avatar,
        ),
        floatingActionButton:
            (!showProfile && !showNotifications && !showExplore)
            ? FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => CreateGalleryPage(),
                  );
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    child: ClipOval(
                      child: AppImage(
                        url: apiService.currentUser!.avatar,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    apiService.currentUser?.displayName ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (apiService.currentUser?.handle != null)
                    Text(
                      '@${apiService.currentUser!.handle}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        (apiService.currentUser?.followersCount ?? 0)
                            .toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Followers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        (apiService.currentUser?.followsCount ?? 0).toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Following',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 10,
                        ),
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LogPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(child: AppVersionText()),
            ),
          ],
        ),
      ),
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
                    children: [
                      ProfilePage(
                        did: apiService.currentUser?.did,
                        showAppBar: false,
                      ),
                    ],
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
        avatarUrl: apiService.currentUser?.avatar,
      ),
    );
  }
} // End of _MyHomePageState and file
