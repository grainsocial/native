import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/widgets/gallery_preview.dart';
import 'gallery_page.dart';
import 'comments_page.dart';
import 'profile_page.dart';
import 'package:grain/utils.dart';
import 'log_page.dart';
import 'package:grain/widgets/app_version_text.dart';
import 'notifications_page.dart';
import 'explore_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  bool showProfile = false;
  bool showNotifications = false;
  bool showExplore = false;
  List<TimelineItem> _timeline = [];
  bool _timelineLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    setState(() {
      _timelineLoading = true;
    });
    try {
      final galleries = await apiService.getTimeline();
      setState(() {
        _timeline = galleries.map((g) => TimelineItem.fromGallery(g)).toList();
        _timelineLoading = false;
      });
    } catch (e) {
      setState(() {
        _timeline = [];
        _timelineLoading = false;
      });
    }
  }

  int get _navIndex {
    if (showProfile) return 3;
    if (showNotifications) return 2;
    if (showExplore) return 1;
    return 0;
  }

  Widget _buildTimeline() {
    if (_timelineLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_timeline.isEmpty) {
      return const Center(child: Text('No timeline items.'));
    }
    return ListView.separated(
      itemCount: _timeline.length,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey[200], thickness: 1, height: 1),
      itemBuilder: (context, index) {
        final item = _timeline[index];
        final gallery = item.gallery;
        final actor = gallery.creator;
        final createdAt = gallery.createdAt;
        return GestureDetector(
          onTap: () {
            if (gallery.uri.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GalleryPage(
                    uri: gallery.uri,
                    currentUserDid: apiService.currentUser?.did,
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (actor != null) {
                          final loadedProfile = await apiService.fetchProfile(
                            did: actor.did,
                          );
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                profile: loadedProfile,
                                showAppBar: true,
                              ),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            actor?.avatar != null && actor!.avatar.isNotEmpty
                            ? NetworkImage(actor.avatar)
                            : null,
                        backgroundColor: Colors.transparent,
                        child: (actor == null || actor.avatar.isEmpty)
                            ? const Icon(
                                Icons.account_circle,
                                size: 24,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              actor != null && actor.displayName.isNotEmpty
                                  ? actor.displayName
                                  : (actor != null ? '@${actor.handle}' : ''),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (actor != null && actor.handle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '@${actor.handle}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formatRelativeTime(createdAt ?? ''),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (gallery.items.isNotEmpty)
                GalleryPreview(gallery: gallery)
              else
                const SizedBox.shrink(),
              if (gallery.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Text(
                    gallery.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (gallery.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    gallery.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 12,
                  left: 12,
                  right: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          size: 18,
                          gallery.viewer != null &&
                                  gallery.viewer!['fav'] != null
                              ? FontAwesomeIcons.solidHeart
                              : FontAwesomeIcons.heart,
                          color:
                              gallery.viewer != null &&
                                  gallery.viewer!['fav'] != null
                              ? Color(0xFFEC4899)
                              : Colors.black54,
                        ),
                      ),
                      onTap: () {},
                    ),
                    if (gallery.favCount != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          gallery.favCount.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CommentsPage(galleryUri: gallery.uri),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Icon(
                          FontAwesomeIcons.comment,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    if (gallery.commentCount != null)
                      Text(
                        gallery.commentCount.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22, // Smaller avatar
                    backgroundImage:
                        apiService.currentUser?.avatar != null &&
                            apiService.currentUser!.avatar.isNotEmpty
                        ? NetworkImage(apiService.currentUser!.avatar)
                        : null,
                    backgroundColor: Colors.white,
                    child:
                        (apiService.currentUser == null ||
                            apiService.currentUser!.avatar.isEmpty)
                        ? const Icon(
                            Icons.account_circle,
                            size: 32,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    apiService.currentUser?.displayName ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15, // Smaller text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (apiService.currentUser?.handle != null)
                    Text(
                      '@${apiService.currentUser!.handle}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11, // Smaller text
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        (apiService.currentUser?.followersCount ?? 0)
                            .toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Followers',
                        style: TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        (apiService.currentUser?.followsCount ?? 0).toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Following',
                        style: TextStyle(color: Colors.black54, fontSize: 10),
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
            // Add more menu items here
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(child: AppVersionText()),
            ),
          ],
        ),
      ),
      appBar: showProfile
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: Theme.of(context).dividerColor,
                  height: 1,
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                showNotifications
                    ? 'Notifications'
                    : showExplore
                    ? 'Explore'
                    : widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
      body: Stack(
        children: [
          if (!showProfile && !showNotifications && !showExplore)
            _buildTimeline(),
          if (showExplore)
            Positioned.fill(
              child: Material(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(child: Stack(children: [ExplorePage()])),
              ),
            ),
          if (showNotifications)
            Positioned.fill(
              child: Material(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(child: Stack(children: [NotificationsPage()])),
              ),
            ),
          if (showProfile)
            Positioned.fill(
              child: Material(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(
                  child: Stack(
                    children: [
                      ProfilePage(
                        profile: apiService.currentUser,
                        showAppBar: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        height: 42 + MediaQuery.of(context).padding.bottom, // Ultra-slim
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    showProfile = false;
                    showNotifications = false;
                    showExplore = false;
                  });
                },
                child: SizedBox(
                  height: 42 + MediaQuery.of(context).padding.bottom,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.house,
                        size: 20,
                        color: _navIndex == 0
                            ? const Color(0xFF0EA5E9)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    showExplore = true;
                    showProfile = false;
                    showNotifications = false;
                  });
                },
                child: SizedBox(
                  height: 42 + MediaQuery.of(context).padding.bottom,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 20,
                        color: _navIndex == 1
                            ? const Color(0xFF0EA5E9)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    showNotifications = true;
                    showProfile = false;
                    showExplore = false;
                  });
                },
                child: SizedBox(
                  height: 42 + MediaQuery.of(context).padding.bottom,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.solidBell,
                        size: 20,
                        color: _navIndex == 2
                            ? const Color(0xFF0EA5E9)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    showProfile = true;
                    showNotifications = false;
                    showExplore = false;
                  });
                },
                child: SizedBox(
                  height: 42 + MediaQuery.of(context).padding.bottom,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Center(
                      child: apiService.currentUser?.avatar != null
                          ? Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: _navIndex == 3
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0EA5E9),
                                        width: 2.2,
                                      ),
                                    )
                                  : null,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(
                                  apiService.currentUser!.avatar,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            )
                          : FaIcon(
                              _navIndex == 3
                                  ? FontAwesomeIcons.solidUser
                                  : FontAwesomeIcons.user,
                              size: 16,
                              color: _navIndex == 3
                                  ? const Color(0xFF0EA5E9)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   tooltip: 'Action',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
