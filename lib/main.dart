import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grain/splash_page.dart';
import 'package:grain/home_page.dart';

class AppConfig {
  static late final String apiUrl;

  static Future<void> init() async {
    if (!kReleaseMode) {
      await dotenv.load(fileName: '.env');
    }
    apiUrl = kReleaseMode
        ? const String.fromEnvironment(
            'API_URL',
            defaultValue: 'https://grain.social',
          )
        : dotenv.env['API_URL'] ?? 'http://localhost:8080';
  }
}

Future<void> main() async {
  await AppConfig.init();
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
    // Fetch current user profile from /oauth/session after login
    await apiService.fetchCurrentUser();
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
        textTheme: GoogleFonts.interTextTheme(),
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
