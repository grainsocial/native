import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/app_theme.dart';
import 'package:grain/auth.dart';
import 'package:grain/screens/home_page.dart';
import 'package:grain/screens/splash_page.dart';

import 'providers/profile_provider.dart';

class AppConfig {
  static late final String apiUrl;

  static Future<void> init() async {
    if (!kReleaseMode) {
      await dotenv.load(fileName: '.env');
    }
    apiUrl = kReleaseMode
        ? const String.fromEnvironment('API_URL', defaultValue: 'https://grain.social')
        : dotenv.env['API_URL'] ?? 'http://localhost:8080';
  }
}

Future<void> main() async {
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

class _MyAppState extends State<MyApp> {
  bool isSignedIn = false;
  bool _loading = true;
  String? displayName;

  @override
  void initState() {
    super.initState();
    _checkToken();
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
          // Session fetch failed, clear session
          await auth.clearSession();
        }
      } catch (e) {
        // Error fetching session, clear session
        await auth.clearSession();
      }
    }
    setState(() {
      isSignedIn = valid;
      _loading = false;
    });
  }

  void handleSignIn() async {
    final container = ProviderScope.containerOf(context, listen: false);

    setState(() {
      isSignedIn = true;
    });
    // Fetch current user profile from /oauth/session after login
    appLogger.i('Fetching current user after sign in');
    await apiService.fetchCurrentUser();
  }

  void handleSignOut(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    await auth.clearSession(); // Clear session data
    // Invalidate Riverpod providers for profile and gallery state
    container.invalidate(profileNotifierProvider);
    // Add any other providers you want to invalidate here
    setState(() {
      isSignedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_loading) {
      home = Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      );
    } else {
      home = isSignedIn
          ? MyHomePage(title: 'Grain', onSignOut: () => handleSignOut(context))
          : SplashPage(onSignIn: handleSignIn);
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
