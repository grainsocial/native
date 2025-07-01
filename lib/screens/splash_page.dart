import 'package:flutter/material.dart';
import 'package:grain/auth.dart';
import 'package:grain/widgets/app_image.dart';

class SplashPage extends StatefulWidget {
  final void Function()? onSignIn;
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
      await auth.login(handle);

      if (widget.onSignIn != null) {
        widget.onSignIn!();
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
          AppImage(
            url:
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
