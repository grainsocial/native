import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/notification.dart' as grain;
import 'package:grain/screens/gallery_page.dart';
import 'package:grain/screens/profile_page.dart';
import 'package:grain/utils.dart';
import 'package:grain/widgets/gallery_preview.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  bool _error = false;
  List<grain.Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final notifications = await apiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Widget _buildNotificationTile(grain.Notification notification) {
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
            ? Icon(Icons.account_circle, color: theme.iconTheme.color)
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

  Widget _buildSkeletonTile(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
        width: 120,
        height: 16,
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        margin: const EdgeInsets.only(bottom: 4),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 14,
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            margin: const EdgeInsets.only(bottom: 8),
          ),
          Container(
            width: 140,
            height: 12,
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? ListView.separated(
              itemCount: 6,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, index) => _buildSkeletonTile(context),
            )
          : _error
          ? Center(child: Text('Failed to load notifications.', style: theme.textTheme.bodyMedium))
          : _notifications.isEmpty
          ? Center(child: Text('No notifications yet.', style: theme.textTheme.bodyMedium))
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
    );
  }
}
