import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/profile.dart';
import 'profile_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  Future<List<Profile>> _delayedSearch(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return apiService.searchActors(query);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SearchAnchor.bar(
        barHintText: 'Search for users',
        barShape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        barElevation: WidgetStateProperty.all(0),
        suggestionsBuilder: (context, controller) {
          if (controller.text.isEmpty) {
            return [];
          }
          return [
            FutureBuilder<List<Profile>>(
              future: _delayedSearch(controller.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Searching...'),
                    leading: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const ListTile(title: Text('Error searching users'));
                }
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return const ListTile(title: Text('No users found'));
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: results.map((profile) {
                    return ListTile(
                      leading: profile.avatar.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(profile.avatar),
                              radius: 16,
                            )
                          : const CircleAvatar(
                              radius: 16,
                              child: Icon(
                                Icons.account_circle,
                                color: Colors.grey,
                              ),
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
                        // Navigate to the profile page for the selected user
                        final loadedProfile = await apiService.fetchProfile(
                          did: profile.did,
                        );
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                profile: loadedProfile,
                                showAppBar: true,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ];
        },
      ),
    );
  }
}
