import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/profile.dart';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search for users',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0ea5e9), // Tailwind sky-500
                  width: 2,
                ),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                          _searched = false;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search for "${_controller.text}"',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        Expanded(child: _buildResultsList(_results)),
      ],
    );
  }

  Widget _buildResultsList(List<Profile> results) {
    if (_loading) {
      return const ListTile(
        title: Text('Searching...'),
        leading: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF0EA5E9),
          ),
        ),
      );
    } else if (_searched && results.isEmpty) {
      return const ListTile(title: Text('No users found'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final profile = results[index];
        return ListTile(
          leading: profile.avatar.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(profile.avatar),
                  radius: 16,
                )
              : const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.account_circle, color: Colors.grey),
                ),
          title: Text(
            profile.displayName.isNotEmpty
                ? profile.displayName
                : '@${profile.handle}',
          ),
          subtitle: profile.handle.isNotEmpty
              ? Text('@${profile.handle}')
              : null,
          onTap: () async {
            final loadedProfile = await apiService.fetchProfile(
              did: profile.did,
            );
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ProfilePage(profile: loadedProfile, showAppBar: true),
                ),
              );
            }
          },
        );
      },
    );
  }
}
