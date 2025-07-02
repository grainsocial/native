import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/profile.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/plain_text_field.dart';
import 'profile_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _controller = TextEditingController();
  List<Profile> _results = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _searched = true;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await apiService.searchActors(value);
        if (mounted) {
          setState(() {
            _results = results;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _results = [];
            _loading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: PlainTextField(
            label: '',
            controller: _controller,
            hintText: 'Search for users',
            onChanged: _onSearchChanged,
            enabled: true,
          ),
        ),
        if (_controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search for "${_controller.text}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        Expanded(child: _buildResultsList(_results, theme)),
      ],
    );
  }

  Widget _buildResultsList(List<Profile> results, ThemeData theme) {
    if (_loading) {
      return ListTile(
        title: Text('Searching...', style: theme.textTheme.bodyMedium),
        leading: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    } else if (_searched && results.isEmpty) {
      return ListTile(
        title: Text('No users found', style: theme.textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final profile = results[index];
        return ListTile(
          leading: profile.avatar.isNotEmpty
              ? ClipOval(
                  child: AppImage(
                    url: profile.avatar,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.account_circle,
                    color: theme.iconTheme.color,
                  ),
                ),
          title: Text(
            profile.displayName.isNotEmpty
                ? profile.displayName
                : '@${profile.handle}',
            style: theme.textTheme.bodyLarge,
          ),
          subtitle: profile.handle.isNotEmpty
              ? Text(
                  '@${profile.handle}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                )
              : null,
          onTap: () async {
            FocusScope.of(context).unfocus();
            _debounce?.cancel();
            setState(() {
              _searched = false;
              _loading = false;
            });
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ProfilePage(did: profile.did, showAppBar: true),
                ),
              );
            }
          },
        );
      },
    );
  }
}
