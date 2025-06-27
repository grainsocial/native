import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/main.dart';

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
      final apiUrl = AppConfig.apiUrl;
      final redirectedUrl = await FlutterWebAuth2.authenticate(
        url:
            '$apiUrl/oauth/login?client=native&handle=${Uri.encodeComponent(handle)}',
        callbackUrlScheme: 'grainflutter',
      );
      final uri = Uri.parse(redirectedUrl);
      final token = uri.queryParameters['token'];

      appLogger.i('Redirected URL: $redirectedUrl');
      appLogger.i('User signed in with handle: $handle');

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
          Container(color: Colors.black.withOpacity(0.4)),
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
                        backgroundColor: const Color(0xFF0EA5E9),
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
