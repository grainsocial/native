import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/screens/hashtag_page.dart';
import 'package:grain/utils.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/faceted_text.dart';
import 'package:grain/widgets/gallery_action_buttons.dart';
import 'package:grain/widgets/gallery_preview.dart';

import '../providers/gallery_cache_provider.dart';
import '../screens/gallery_page.dart';
import '../screens/profile_page.dart';

class TimelineItemWidget extends ConsumerWidget {
  final String galleryUri;
  final VoidCallback? onProfileTap;
  const TimelineItemWidget({super.key, required this.galleryUri, this.onProfileTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryCacheProvider)[galleryUri];
    if (gallery == null) {
      return const SizedBox.shrink(); // or a loading/placeholder widget
    }
    final actor = gallery.creator;
    final createdAt = gallery.createdAt;
    final theme = Theme.of(context);
    final isLoggedIn = apiService.currentUser?.did != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap:
                    onProfileTap ??
                    () {
                      if (actor != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(did: actor.did, showAppBar: true),
                          ),
                        );
                      }
                    },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: (actor != null && (actor.avatar?.isNotEmpty ?? false))
                      ? ClipOval(
                          child: AppImage(
                            url: actor.avatar,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.account_circle,
                          size: 24,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        actor != null && (actor.displayName?.isNotEmpty ?? false)
                            ? actor.displayName ?? ''
                            : (actor != null ? '@${actor.handle}' : ''),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actor != null && actor.handle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '@${actor.handle}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                formatRelativeTime(createdAt ?? ''),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (gallery.items.isNotEmpty)
          GestureDetector(
            onTap: () {
              if (gallery.uri.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        GalleryPage(uri: gallery.uri, currentUserDid: apiService.currentUser?.did),
                  ),
                );
              }
            },
            child: GalleryPreview(gallery: gallery),
          )
        else
          const SizedBox.shrink(),
        if (gallery.title?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            child: Text(
              gallery.title ?? '',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        if (gallery.description?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: FacetedText(
              text: gallery.description ?? '',
              facets: gallery.facets,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              linkStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              onMentionTap: (did) {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => ProfilePage(did: did)));
              },
              onTagTap: (tag) => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HashtagPage(hashtag: tag)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (isLoggedIn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GalleryActionButtons(
              gallery: gallery,
              parentContext: context,
              currentUserDid: gallery.creator?.did, // or apiService.currentUser?.did if available
              isLoggedIn: isLoggedIn,
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
