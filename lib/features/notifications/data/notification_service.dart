import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final SupabaseClient _client = Supabase.instance.client;

  /// Fetches the current user's notifications, newest first, with the
  /// triggering actor's public profile attached under the `actor` key.
  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return [];
    }

    final response = await _client
        .from('notifications')
        .select(
          'id, actor_id, type, title, body, entity_type, entity_id, '
          'is_read, created_at, read_at',
        )
        .eq('recipient_id', user.id)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final notifications = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    await _attachActors(notifications);

    return notifications;
  }

  /// Attaches the public profile of each notification's actor, in a single
  /// batched query, so the UI never has to fetch profiles one by one.
  static Future<void> _attachActors(
    List<Map<String, dynamic>> notifications,
  ) async {
    final actorIds = notifications
        .map((notification) => notification['actor_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (actorIds.isEmpty) {
      return;
    }

    final response = await _client
        .from('public_profiles')
        .select('id, username, full_name, avatar_url')
        .inFilter('id', actorIds);

    final actorsById = <String, Map<String, dynamic>>{
      for (final actor in (response as List<dynamic>))
        (actor as Map)['id'] as String: Map<String, dynamic>.from(actor),
    };

    for (final notification in notifications) {
      final actorId = notification['actor_id'] as String?;

      if (actorId != null) {
        notification['actor'] = actorsById[actorId];
      }
    }
  }

  /// Number of unread notifications for the current user (for the bell
  /// badge). Returns 0 when signed out.
  static Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return 0;
    }

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', user.id)
        .eq('is_read', false);

    return (response as List<dynamic>).length;
  }

  static Future<void> markAsRead(String notificationId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return;
    }

    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId)
        .eq('recipient_id', user.id);
  }

  static Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return;
    }

    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('recipient_id', user.id)
        .eq('is_read', false);
  }

  static Future<void> deleteNotification(String notificationId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return;
    }

    await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('recipient_id', user.id);
  }
}
