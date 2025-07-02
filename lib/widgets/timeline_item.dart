import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grain/widgets/gallery_preview.dart';
import '../screens/gallery_page.dart';
import '../screens/comments_page.dart';
import '../screens/profile_page.dart';
import 'package:grain/api.dart';
import 'package:grain/utils.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/app_theme.dart';

class TimelineItemWidget extends StatelessWidget {
  final Gallery gallery;
  final VoidCallback? onProfileTap;
  const TimelineItemWidget({
    super.key,
    required this.gallery,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final actor = gallery.creator;
    final createdAt = gallery.createdAt;
    final theme = Theme.of(context);
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
                            builder: (context) =>
                                ProfilePage(did: actor.did, showAppBar: true),
                          ),
                        );
                      }
                    },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: (actor != null && actor.avatar.isNotEmpty)
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
                        actor != null && actor.displayName.isNotEmpty
                            ? actor.displayName
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
                    builder: (context) => GalleryPage(
                      uri: gallery.uri,
                      currentUserDid: apiService.currentUser?.did,
                    ),
                  ),
                );
              }
            },
            child: GalleryPreview(gallery: gallery),
          )
        else
          const SizedBox.shrink(),
        if (gallery.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            child: Text(
              gallery.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (gallery.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Text(
              gallery.description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 12,
            left: 12,
            right: 12,
          ),
          child: Row(
            children: [
              GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    size: 18,
                    gallery.viewer != null && gallery.viewer!['fav'] != null
                        ? FontAwesomeIcons.solidHeart
                        : FontAwesomeIcons.heart,
                    color:
                        gallery.viewer != null && gallery.viewer!['fav'] != null
                        ? AppTheme.favoriteColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {},
              ),
              if (gallery.favCount != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    gallery.favCount.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CommentsPage(galleryUri: gallery.uri),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Icon(
                    FontAwesomeIcons.comment,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (gallery.commentCount != null)
                Text(
                  gallery.commentCount.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
