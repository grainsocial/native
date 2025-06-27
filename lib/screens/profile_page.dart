import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/api.dart';
import 'gallery_page.dart';

class ProfilePage extends StatefulWidget {
  final dynamic profile;
  final bool showAppBar;
  const ProfilePage({super.key, this.profile, this.showAppBar = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  dynamic _profile;
  bool _loading = true;
  List<Gallery> _galleries = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfileAndGalleries();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileAndGalleries() async {
    setState(() {
      _loading = true;
    });
    String? did = widget.profile?.did;
    if (did == null || did.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final profile = await apiService.fetchProfile(did: did);
    final galleries = await apiService.fetchActorGalleries(did: did);
    setState(() {
      _profile = profile;
      _galleries = galleries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? widget.profile;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profile == null) {
      return const Center(child: Text('No profile data'));
    }
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: Theme.of(context).dividerColor,
                  height: 1,
                ),
              ),
              leading: const BackButton(),
            )
          : null,
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            if (profile.avatar != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundImage: NetworkImage(profile.avatar),
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
                    ),
                  ],
                  body: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          indicator: UnderlineTabIndicator(
                            borderSide: const BorderSide(
                              color: Color(0xFF0EA5E9),
                              width: 3,
                            ),
                            insets: EdgeInsets.zero,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: const Color(0xFF0EA5E9),
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          tabs: const [
                            Tab(text: 'Galleries'),
                            Tab(text: 'Favs'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _tabController == null
                            ? Container()
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  // Galleries tab
                                  Padding(
                                    padding: EdgeInsets.zero,
                                    child: GridView.builder(
                                      padding: EdgeInsets.zero,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            childAspectRatio: 3 / 4,
                                            crossAxisSpacing: 2,
                                            mainAxisSpacing: 2,
                                          ),
                                      itemCount: _galleries.isNotEmpty
                                          ? _galleries.length
                                          : 24,
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
                                                    builder: (context) =>
                                                        GalleryPage(
                                                          uri: gallery.uri,
                                                          currentUserDid:
                                                              profile.did,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: hasPhoto
                                                  ? Image.network(
                                                      gallery.items[0].thumb,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        gallery.title,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        }
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Favs tab (placeholder)
                                  const Center(
                                    child: Text('No favorites yet'),
                                  ), // Replace with real content later
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    final styleCount = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14, // Set to 14
    );
    final styleLabel = TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
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
