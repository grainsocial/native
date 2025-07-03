import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grain/app_theme.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/providers/gallery_cache_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/comments_page.dart';

class GalleryActionButtons extends ConsumerWidget {
  final Gallery gallery;
  final String? currentUserDid;
  final BuildContext parentContext;
  final VoidCallback? onFavorite;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool isLoggedIn;

  const GalleryActionButtons({
    super.key,
    required this.gallery,
    required this.parentContext,
    this.currentUserDid,
    this.onFavorite,
    this.onComment,
    this.onShare,
    this.isLoggedIn = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFav = gallery.viewer != null && gallery.viewer?.fav != null;
    return isLoggedIn
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap:
                    onFavorite ??
                    () async {
                      await ref.read(galleryCacheProvider.notifier).toggleFavorite(gallery.uri);
                    },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      FaIcon(
                        isFav ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        color: isFav ? AppTheme.favoriteColor : theme.iconTheme.color,
                        size: 21,
                      ),
                      if (gallery.favCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          gallery.favCount.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap:
                    onComment ??
                    () {
                      Navigator.of(parentContext).push(
                        MaterialPageRoute(
                          builder: (context) => CommentsPage(galleryUri: gallery.uri),
                        ),
                      );
                    },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.comment, color: theme.iconTheme.color, size: 21),
                      if (gallery.commentCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          gallery.commentCount.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap:
                    onShare ??
                    () {
                      final handle = gallery.creator?.handle ?? '';
                      final uriParts = gallery.uri.split('/');
                      final galleryRkey = uriParts.isNotEmpty ? uriParts.last : '';
                      final url = 'https://grain.social/profile/$handle/gallery/$galleryRkey';
                      final shareText = "Check out this gallery on @grain.social \n$url";
                      SharePlus.instance.share(ShareParams(text: shareText));
                    },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: FaIcon(
                    FontAwesomeIcons.arrowUpFromBracket,
                    color: theme.iconTheme.color,
                    size: 18,
                  ),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
