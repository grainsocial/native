import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/gallery.dart';
import 'package:grain/gallery_page.dart';
import 'package:grain/comments_page.dart';
import 'profile_page.dart';
import 'utils.dart';

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
  final String? displayName;
  const MyHomePage({
    super.key,
    required this.title,
    this.onSignOut,
    this.displayName,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showProfile = false;
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

  int get _navIndex => showProfile ? 1 : 0;

  Widget _buildTimeline() {
    if (_timelineLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_timeline.isEmpty) {
      return const Center(child: Text('No timeline items.'));
    }
    return ListView.separated(
      physics: const SlowScrollPhysics(speedFactor: 1.5),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
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
                                fontWeight: FontWeight.bold,
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
                const SizedBox(height: 12),
                if (gallery.items.isNotEmpty) _GalleryPreview(gallery: gallery),
                if (gallery.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      gallery.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (gallery.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      gallery.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        gallery.viewer != null && gallery.viewer!['fav'] != null
                            ? Icons
                                  .favorite // filled
                            : Icons.favorite_border, // outline
                        color:
                            gallery.viewer != null &&
                                gallery.viewer!['fav'] != null
                            ? Color(0xFFEC4899) // Tailwind pink-500
                            : Colors.black54,
                      ),
                      onPressed: () {},
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
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommentsPage(galleryUri: gallery.uri),
                          ),
                        );
                      },
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
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
          if (!showProfile) _buildTimeline(),
          if (showProfile)
            Positioned.fill(
              child: Material(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.98),
                child: SafeArea(
                  child: Stack(
                    children: [ProfilePage(profile: apiService.currentUser)],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _navIndex == 0
                ? const Icon(Icons.home)
                : const Icon(Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                setState(() {
                  showProfile = true;
                });
              },
              child: apiService.currentUser?.avatar != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _navIndex == 1
                                ? Colors.lightBlue
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            apiService.currentUser!.avatar,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    )
                  : Icon(
                      _navIndex == 1
                          ? Icons.account_circle
                          : Icons.account_circle_outlined,
                    ),
            ),
            label: '',
          ),
        ],
        currentIndex: _navIndex,
        selectedItemColor: Colors.lightBlue,
        onTap: (index) {
          if (index == 1) {
            setState(() {
              showProfile = true;
            });
            return;
          }
          setState(() {
            showProfile = false;
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Action',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GalleryPreview extends StatelessWidget {
  final Gallery gallery;

  const _GalleryPreview({required this.gallery});

  @override
  Widget build(BuildContext context) {
    final photos = gallery.items
        .where((item) => item.thumb.isNotEmpty)
        .toList();
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: photos.isNotEmpty
                ? Image.network(
                    photos[0].thumb,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(color: Colors.grey[300]),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: photos.length > 1
                      ? Image.network(
                          photos[1].thumb,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(color: Colors.grey[200]),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: photos.length > 2
                      ? Image.network(
                          photos[2].thumb,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(color: Colors.grey[200]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryThumbnail extends StatelessWidget {
  final Gallery gallery;

  const GalleryThumbnail({super.key, required this.gallery});

  @override
  Widget build(BuildContext context) {
    if (gallery.items.isEmpty) {
      return Container(color: Colors.grey[300]);
    }
    final firstItem = gallery.items[0];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        firstItem.thumb,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }
}

class SlowScrollPhysics extends ScrollPhysics {
  final double speedFactor;
  const SlowScrollPhysics({this.speedFactor = 1.5, super.parent});

  @override
  SlowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowScrollPhysics(
      speedFactor: speedFactor,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset / speedFactor);
  }
}
