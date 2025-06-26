import 'package:flutter/material.dart';
import 'package:grain/gallery.dart';
import 'package:grain/api.dart';
import 'package:grain/gallery_page.dart';

class ProfilePage extends StatefulWidget {
  final dynamic profile;
  const ProfilePage({super.key, this.profile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  dynamic _profile;
  bool _loading = true;
  List<Gallery> _galleries = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileAndGalleries();
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
    await apiService.fetchProfile(did: did);
    final galleries = await apiService.fetchActorGalleries(did: did);
    setState(() {
      _profile = apiService.currentUser;
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
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                if (profile.avatar != null)
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(profile.avatar),
                  )
                else
                  const Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.grey,
                  ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${profile.handle ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          (profile.followersCount is int
                                  ? profile.followersCount
                                  : int.tryParse(
                                          profile.followersCount?.toString() ??
                                              '0',
                                        ) ??
                                        0)
                              .toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'followers',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(
                          (profile.followsCount is int
                                  ? profile.followsCount
                                  : int.tryParse(
                                          profile.followsCount?.toString() ??
                                              '0',
                                        ) ??
                                        0)
                              .toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'following',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(
                          (profile.galleryCount is int
                                  ? profile.galleryCount
                                  : int.tryParse(
                                          profile.galleryCount?.toString() ??
                                              '0',
                                        ) ??
                                        0)
                              .toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'galleries',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if ((profile.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(profile.description, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                // Gallery grid (tappable)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _galleries.isNotEmpty ? _galleries.length : 24,
                  itemBuilder: (context, index) {
                    if (_galleries.isNotEmpty && index < _galleries.length) {
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
                          decoration: BoxDecoration(color: Colors.grey[200]),
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
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
