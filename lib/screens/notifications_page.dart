import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/notification.dart' as grain;
import 'package:grain/utils.dart';

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
    final record = notification.record;
    String message = '';
    String? createdAt;
    switch (notification.reason) {
      case 'gallery-favorite':
        message = 'favorited your gallery';
        createdAt = record['createdAt'] as String?;
        break;
      case 'gallery-comment':
        message = 'commented on your gallery';
        createdAt = record['createdAt'] as String?;
        break;
      case 'gallery-mention':
      case 'gallery-comment-mention':
        message = 'mentioned you in a gallery';
        createdAt = record['createdAt'] as String?;
        break;
      case 'reply':
        message = 'replied to your comment';
        createdAt = record['createdAt'] as String?;
        break;
      case 'follow':
        message = 'followed you';
        createdAt = record['createdAt'] as String?;
        break;
      default:
        message = notification.reason;
        createdAt = record['createdAt'] as String?;
    }
    return ListTile(
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
      subtitle: Text(
        '$message · ${createdAt != null ? formatRelativeTime(createdAt) : ''}',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      ),
      onTap: () {
        // TODO: Navigate to gallery/comment/profile as appropriate
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
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
