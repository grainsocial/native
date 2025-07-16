import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/app_theme.dart';
import 'package:grain/auth.dart';
import 'package:grain/screens/home_page.dart';
import 'package:grain/screens/login_page.dart';
import 'package:grain/websocket_service.dart';

import 'providers/profile_provider.dart';
import 'widgets/skeleton_timeline.dart';

class AppConfig {
  static late final String apiUrl;
  static late final String wsUrl;

  static Future<void> init() async {
    if (!kReleaseMode) {
      await dotenv.load(fileName: '.env');
    }
    apiUrl = kReleaseMode
        ? const String.fromEnvironment('API_URL', defaultValue: 'https://grain.social')
        : dotenv.env['API_URL'] ?? '';
    wsUrl = kReleaseMode
        ? const String.fromEnvironment(
            'WS_URL',
            defaultValue: 'wss://notifications.grainsocial.network/ws',
          )
        : dotenv.env['WS_URL'] ?? '';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    appLogger.e('Flutter error: ${details.exception}\n${details.stack}');
  };
  await AppConfig.init();
  await apiService.loadToken(); // Restore access token before app starts
  appLogger.i('🚀 App started');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isSignedIn = false;
  bool _loading = true;
  WebSocketService? _wsService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectWebSocket();
    super.dispose();
  }

  void _connectWebSocket() {
    _disconnectWebSocket();
    if (!isSignedIn) return;
    final accessToken = apiService.getAccessToken();
    if (accessToken == null) return;
    _wsService = WebSocketService(
      wsUrl: AppConfig.wsUrl,
      accessToken: accessToken,
      onMessage: (message) {
        // Optionally: handle global messages or trigger provider updates
      },
    );
    _wsService!.connect();
  }

  void _disconnectWebSocket() {
    _wsService?.disconnect();
    _wsService = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isSignedIn) {
      _connectWebSocket();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _disconnectWebSocket();
    }
  }

  Future<void> _checkToken() async {
    await apiService.loadToken();
    bool valid = false;
    if (apiService.hasToken) {
      try {
        final session = await apiService.fetchSession();
        if (session != null) {
          await apiService.fetchCurrentUser();
          valid = true;
        } else {
          await auth.clearSession();
        }
      } catch (e) {
        await auth.clearSession();
      }
    }
    setState(() {
      isSignedIn = valid;
      _loading = false;
    });
    if (valid) {
      _connectWebSocket();
    }
  }

  void handleSignIn() async {
    setState(() {
      isSignedIn = true;
    });
    appLogger.i('Fetching current user after sign in');
    await apiService.fetchCurrentUser();
    _connectWebSocket();
  }

  void handleSignOut(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    await auth.clearSession();
    container.invalidate(profileNotifierProvider);
    setState(() {
      isSignedIn = false;
    });
    _disconnectWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_loading) {
      home = Scaffold(
        appBar: AppBar(title: const Text('Grain')),
        body: Column(
          children: [
            Expanded(
              child: SkeletonTimeline(padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8)),
            ),
          ],
        ),
      );
    } else {
      home = isSignedIn
          ? MyHomePage(title: 'Grain', onSignOut: () => handleSignOut(context))
          : LoginPage(onSignIn: handleSignIn);
    }
    return MaterialApp(
      title: 'Grain',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}
