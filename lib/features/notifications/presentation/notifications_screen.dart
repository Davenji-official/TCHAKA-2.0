import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  String? _error;

  int _offset = 0;

  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });

    try {
      final notifications = await NotificationService.getNotifications(
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        _notifications
          ..clear()
          ..addAll(notifications);

        _offset = notifications.length;
        _hasMore = notifications.length >= _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger tes notifications.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final notifications = await NotificationService.getNotifications(
        limit: _pageSize,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        _notifications.addAll(notifications);
        _offset += notifications.length;
        _hasMore = notifications.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingMore = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final hadUnread = _notifications.any(
      (notification) => notification['is_read'] != true,
    );

    if (!hadUnread) {
      return;
    }

    setState(() {
      for (final notification in _notifications) {
        notification['is_read'] = true;
      }
    });

    try {
      await NotificationService.markAllAsRead();
    } catch (_) {
      // The next refresh will re-sync the real state if this failed.
    }
  }

  Future<void> _onNotificationTap(
    Map<String, dynamic> notification,
  ) async {
    if (notification['is_read'] != true) {
      setState(() {
        notification['is_read'] = true;
      });

      unawaited(
        NotificationService.markAsRead(notification['id'] as String),
      );
    }

    final entityType = notification['entity_type'] as String?;
    final entityId = notification['entity_id'] as String?;

    if (!mounted || entityId == null) {
      return;
    }

    if (entityType == 'project') {
      context.push('/projects/$entityId');
    }
  }

  Future<void> _onDeleteNotification(
    Map<String, dynamic> notification,
  ) async {
    setState(() {
      _notifications.remove(notification);
    });

    try {
      await NotificationService.deleteNotification(
        notification['id'] as String,
      );
    } catch (_) {
      // Best-effort: if this fails silently, it reappears on next refresh.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any(
            (notification) => notification['is_read'] != true,
          ))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tout marquer comme lu'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_notifications.isEmpty) {
      return _buildEmpty();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final notification = _notifications[index];

          return _NotificationTile(
            key: ValueKey(notification['id']),
            notification: notification,
            onTap: () => _onNotificationTap(notification),
            onDismiss: () => _onDeleteNotification(notification),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _loadingTile(),
    );
  }

  Widget _loadingTile() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _loadingBox(width: 44, height: 44, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _loadingBox(width: 160, height: 14),
                  const SizedBox(height: 10),
                  _loadingBox(width: double.infinity, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.cloud_off_rounded,
          size: 58,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 18),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 22),
        Center(
          child: FilledButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.10),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Rien de neuf pour l’instant.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tes likes, messages, financements et mises à jour '
          'de projet apparaîtront ici.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  bool get _isUnread => notification['is_read'] != true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actor = notification['actor'] as Map<String, dynamic>?;
    final avatarUrl = actor?['avatar_url'] as String?;
    final (icon, iconColor) = _iconForType(
      notification['type'] as String? ?? 'system',
    );

    return Dismissible(
      key: ValueKey(notification['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: TchakaTheme.danger.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(TchakaTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Material(
        color: _isUnread
            ? colorScheme.primary.withValues(alpha: 0.06)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(TchakaTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TchakaTheme.radiusLarge),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TchakaTheme.radiusLarge),
              border: _isUnread
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          avatarUrl?.trim().isNotEmpty == true
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl?.trim().isNotEmpty != true
                          ? const Icon(Icons.person_outline, size: 20)
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                              fontWeight: _isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                      if ((notification['body'] as String?)
                              ?.trim()
                              .isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification['body'] as String,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: TchakaTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _relativeTime(
                          DateTime.parse(
                            notification['created_at'] as String,
                          ),
                        ),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: TchakaTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_isUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'like':
        return (Icons.favorite_rounded, TchakaTheme.danger);
      case 'comment':
        return (Icons.chat_bubble_rounded, TchakaTheme.info);
      case 'follow':
        return (Icons.person_add_rounded, TchakaTheme.tchakaYellow);
      case 'message':
        return (Icons.mail_rounded, TchakaTheme.info);
      case 'funding':
        return (Icons.volunteer_activism_rounded, TchakaTheme.success);
      case 'project_update':
        return (Icons.campaign_rounded, TchakaTheme.tchakaYellow);
      case 'team_invite':
        return (Icons.groups_rounded, TchakaTheme.tchakaYellow);
      case 'verification':
        return (Icons.verified_rounded, TchakaTheme.success);
      default:
        return (Icons.info_rounded, TchakaTheme.textMuted);
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }
}
