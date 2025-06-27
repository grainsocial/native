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
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Widget _buildNotificationTile(grain.Notification notification) {
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
        backgroundImage: author.avatar.isNotEmpty
            ? NetworkImage(author.avatar)
            : null,
        child: author.avatar.isEmpty ? const Icon(Icons.account_circle) : null,
      ),
      title: Text(
        author.displayName.isNotEmpty
            ? author.displayName
            : '@${author.handle}',
      ),
      subtitle: Text(
        '$message · ${createdAt != null ? formatRelativeTime(createdAt) : ''}',
      ),
      onTap: () {
        // TODO: Navigate to gallery/comment/profile as appropriate
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? const Center(child: Text('Failed to load notifications.'))
          : _notifications.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).dividerColor, // Use theme divider color
              ),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
    );
  }
}
