import 'package:flutter/material.dart';
import 'package:grain/auth.dart';
import 'package:grain/widgets/app_button.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/plain_text_field.dart';

class SplashPage extends StatefulWidget {
  final void Function()? onSignIn;
  const SplashPage({super.key, this.onSignIn});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final TextEditingController _handleController = TextEditingController(text: '');
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PlainTextField(
                    label: '',
                    controller: _handleController,
                    hintText: 'Enter your handle',
                    enabled: !_signingIn,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Login',
                      onPressed: _signingIn ? null : () => _signInWithBluesky(context),
                      loading: _signingIn,
                      variant: AppButtonVariant.primary,
                      height: 44,
                      fontSize: 15,
                      borderRadius: 6,
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
