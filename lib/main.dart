import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:grain_flutter/api.dart';
import 'package:grain_flutter/gallery.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isSignedIn = false;
  dynamic session;
  String? displayName;

  void handleSignIn(dynamic newSession) async {
    // Accept both Map and object with accessToken property
    final accessToken = newSession is Map<String, String>
        ? newSession['accessToken']
        : newSession.accessToken;
    setState(() {
      isSignedIn = true;
      session = newSession;
    });
    apiService.setToken(accessToken);
    // No need to fetchProfile here, ProfilePage will fetch on load
    setState(() {
      displayName = apiService.currentUser?.displayName;
    });
  }

  void handleSignOut() {
    setState(() {
      isSignedIn = false;
      session = null;
      displayName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grain',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: isSignedIn
          ? MyHomePage(
              title: 'Grain',
              onSignOut: handleSignOut,
              displayName: displayName,
            )
          : SplashPage(onSignIn: handleSignIn),
    );
  }
}

class SplashPage extends StatefulWidget {
  final void Function(dynamic session)? onSignIn;
  const SplashPage({super.key, this.onSignIn});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final TextEditingController _handleController = TextEditingController(
    text: '',
  );
  bool _signingIn = false;

  Future<void> _signInWithBluesky(BuildContext context) async {
    final handle = _handleController.text.trim();
    if (handle.isEmpty) return;
    setState(() {
      _signingIn = true;
    });
    try {
      final redirectedUrl = await FlutterWebAuth2.authenticate(
        url:
            'http://localhost:8080/oauth/login?client=native&handle=' +
            Uri.encodeComponent(handle),
        callbackUrlScheme: 'grainflutter',
      );
      final uri = Uri.parse(redirectedUrl);
      final token = uri.queryParameters['token'];
      if (token == null) {
        throw Exception('Token not found in redirect URL');
      }
      if (widget.onSignIn != null) {
        widget.onSignIn!({'accessToken': token});
      }
    } finally {
      setState(() {
        _signingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://cdn.bsky.app/img/feed_fullsize/plain/did:plc:bcgltzqazw5tb6k2g3ttenbj/bafkreiewhwu3ro5dv7omedphb62db4koa7qtvyzfhiiypg3ru4tvuxkrjy@jpeg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.4), // dark overlay for contrast
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _handleController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your handle',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    enabled: !_signingIn,
                    onSubmitted: (_) => _signInWithBluesky(context),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF0EA5E9,
                        ), // Tailwind sky-500
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _signingIn
                          ? null
                          : () => _signInWithBluesky(context),
                      child: _signingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
  int _selectedIndex = 0;
  bool showProfile = false;

  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('Home Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('Settings Page', style: TextStyle(fontSize: 24))),
  ];

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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (apiService.currentUser?.displayName != null)
                  Text(
                    'Welcome, ${apiService.currentUser!.displayName}!',
                    style: const TextStyle(fontSize: 28),
                  ),
                _widgetOptions[_selectedIndex],
              ],
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
                    children: [ProfilePage(profile: apiService.currentUser)],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
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
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          apiService.currentUser!.avatar,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    )
                  : const Icon(Icons.account_circle),
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlue,
        onTap: (index) {
          if (index == 2) {
            setState(() {
              showProfile = true;
            });
            return;
          }
          setState(() {
            _selectedIndex = index;
            showProfile = false; // Close profile page when switching tabs
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Example: increment counter or any action
        },
        tooltip: 'Action',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Convert ProfilePage to a StatefulWidget
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
    await apiService.fetchProfile();
    final galleriesRaw = await apiService.fetchActorGalleries();
    final List<Gallery> galleries = List<Gallery>.from(
      galleriesRaw.map(
        (g) => g is Gallery ? g : Gallery.fromJson(g as Map<String, dynamic>),
      ),
    );
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
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
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
                // Display name
                Text(
                  profile.displayName ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Handle
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
                // Followers, Following, Galleries
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Followers
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
                    // Following
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
                    // Galleries
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
                // Description
                if ((profile.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(profile.description, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                // Grid of gallery items (3/4 aspect ratio)
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
                      return Container(
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
