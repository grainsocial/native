import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/screens/splash_page.dart';
import 'package:grain/screens/home_page.dart';
import 'package:grain/auth.dart';

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
  appLogger.i('🚀 App started');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isSignedIn = false;
  String? displayName;

  void handleSignIn() async {
    setState(() {
      isSignedIn = true;
    });
    // Fetch current user profile from /oauth/session after login
    appLogger.i('Fetching current user after sign in');
    await apiService.fetchCurrentUser();
  }

  void handleSignOut() {
    setState(() {
      isSignedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grain',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        scaffoldBackgroundColor: Colors.white,
        dividerColor: const Color(0xFFF4F4F5),
        // textTheme: GoogleFonts.interTextTheme(),
      ),
      home: isSignedIn
          ? MyHomePage(title: 'Grain', onSignOut: handleSignOut)
          : SplashPage(onSignIn: handleSignIn),
    );
  }
}
