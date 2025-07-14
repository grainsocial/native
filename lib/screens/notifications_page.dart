import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/app_icons.dart';
import 'package:grain/models/notification.dart' as grain;
import 'package:grain/providers/notifications_provider.dart';
import 'package:grain/screens/gallery_page.dart';
import 'package:grain/screens/profile_page.dart';
import 'package:grain/utils.dart';
import 'package:grain/widgets/gallery_preview.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _seenCalled = false;

  @override
  void initState() {
    super.initState();
    // Only call updateSeen once per visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_seenCalled) {
        ref.read(notificationsProvider.notifier).updateSeen();
        _seenCalled = true;
      }
    });
  }

  Widget _buildNotificationTile(BuildContext context, grain.Notification notification) {
    final theme = Theme.of(context);
    final author = notification.author;
    String message = '';
    String? createdAt = notification.record['createdAt'];
    void Function()? onTap;
    final gallery = notification.reasonSubjectGallery;
    final comment = notification.reasonSubjectComment;
    final profile = notification.reasonSubjectProfile;
    final currentUserDid = apiService.currentUser?.did;

    switch (notification.reason) {
      case 'gallery-favorite':
        message = 'favorited your gallery';
        if (gallery != null) {
          onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GalleryPage(uri: gallery.uri, currentUserDid: currentUserDid),
              ),
            );
          };
        }
        break;
      case 'gallery-comment':
        message = 'commented on your gallery';
        if (comment != null) {
          onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GalleryPage(uri: comment.subject.uri, currentUserDid: currentUserDid),
              ),
            );
          };
        }
        break;
      case 'gallery-mention':
      case 'gallery-comment-mention':
        message = 'mentioned you in a gallery';
        if (comment != null) {
          onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GalleryPage(uri: comment.subject.uri, currentUserDid: currentUserDid),
              ),
            );
          };
        }
        break;
      case 'reply':
        message = 'replied to your comment';
        if (comment != null) {
          onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GalleryPage(uri: comment.subject.uri, currentUserDid: currentUserDid),
              ),
            );
          };
        }
        break;
      case 'follow':
        message = 'followed you';
        if (profile != null) {
          onTap = () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(profile: profile, showAppBar: true)),
            );
          };
        }
        break;
      default:
        message = notification.reason;
    }

    bool isFollow = notification.reason == 'follow';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceVariant,
        backgroundImage: (author.avatar?.isNotEmpty ?? false) ? NetworkImage(author.avatar!) : null,
        child: (author.avatar?.isEmpty ?? true)
            ? Icon(AppIcons.accountCircle, color: theme.iconTheme.color)
            : null,
      ),
      title: Text(
        (author.displayName?.isNotEmpty ?? false) ? author.displayName! : '@${author.handle}',
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '$message · ${createdAt != null ? formatRelativeTime(createdAt) : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          if (notification.reasonSubjectComment != null) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 3),
                ),
              ),
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.reasonSubjectComment!.text, style: theme.textTheme.bodyMedium),
                  if (notification.reasonSubjectComment!.focus?.thumb != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          notification.reasonSubjectComment!.focus!.thumb!,
                          height: 64,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (gallery != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 160),
              child: GalleryPreview(gallery: gallery),
            ),
          ],
        ],
      ),
      isThreeLine: !isFollow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: notifications.isEmpty
          ? Center(child: Text('No notifications yet.', style: theme.textTheme.bodyMedium))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(context, notification);
              },
            ),
    );
  }
}
