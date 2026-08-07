import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  MessagingService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Tu dois être connecté pour utiliser la messagerie.');
    }
    return id;
  }

  static Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final response = await _client
        .from('profiles')
        .select('id, username, full_name, avatar_url, is_verified')
        .or('username.ilike.%$clean%,full_name.ilike.%$clean%')
        .neq('id', _userId)
        .order('username')
        .limit(20);

    return response
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = _userId;

    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id, last_read_at, is_muted')
        .eq('profile_id', userId);

    if (memberships.isEmpty) return [];

    final conversationIds = memberships
        .map((row) => row['conversation_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (conversationIds.isEmpty) return [];

    final conversations = await _client
        .from('conversations')
        .select('id, type, title, created_by, created_at, updated_at')
        .inFilter('id', conversationIds)
        .order('updated_at', ascending: false);

    final memberRows = await _client
        .from('conversation_members')
        .select('conversation_id, profile_id, last_read_at, is_muted')
        .inFilter('conversation_id', conversationIds);

    final profileIds = memberRows
        .map((row) => row['profile_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final profiles = profileIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('profiles')
            .select('id, username, full_name, avatar_url, is_verified')
            .inFilter('id', profileIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final row in profiles)
        row['id'].toString(): Map<String, dynamic>.from(row),
    };

    final membersByConversation = <String, List<Map<String, dynamic>>>{};
    for (final row in memberRows) {
      final conversationId = row['conversation_id']?.toString();
      if (conversationId == null) continue;
      membersByConversation.putIfAbsent(conversationId, () => []).add({
        ...Map<String, dynamic>.from(row),
        'profile': profileMap[row['profile_id']?.toString()],
      });
    }

    return conversations.map<Map<String, dynamic>>((row) {
      final conversation = Map<String, dynamic>.from(row);
      final id = conversation['id'].toString();
      final members = membersByConversation[id] ?? [];
      final other = members.cast<Map<String, dynamic>?>().firstWhere(
            (member) => member?['profile_id']?.toString() != userId,
            orElse: () => null,
          );

      conversation['members'] = members;
      conversation['other_profile'] = other?['profile'];
      conversation['last_read_at'] = members
          .where((member) => member['profile_id']?.toString() == userId)
          .map((member) => member['last_read_at'])
          .firstOrNull;
      conversation['is_muted'] = members
          .where((member) => member['profile_id']?.toString() == userId)
          .map((member) => member['is_muted'] == true)
          .firstOrNull ?? false;
      return conversation;
    }).toList();
  }

  static Future<String> createDirectConversation(String otherProfileId) async {
    final userId = _userId;
    final otherId = otherProfileId.trim();

    if (otherId.isEmpty || otherId == userId) {
      throw const FormatException('Destinataire invalide.');
    }

    final existingMembership = await _client
        .from('conversation_members')
        .select('conversation_id')
        .eq('profile_id', userId);

    final existingIds = existingMembership
        .map((row) => row['conversation_id']?.toString())
        .whereType<String>()
        .toList();

    if (existingIds.isNotEmpty) {
      final directConversations = await _client
          .from('conversations')
          .select('id, type')
          .inFilter('id', existingIds)
          .eq('type', 'direct');

      for (final conversation in directConversations) {
        final conversationId = conversation['id'].toString();
        final members = await _client
            .from('conversation_members')
            .select('profile_id')
            .eq('conversation_id', conversationId);
        final ids = members.map((row) => row['profile_id']?.toString()).toSet();
        if (ids.length == 2 && ids.contains(userId) && ids.contains(otherId)) {
          return conversationId;
        }
      }
    }

    final conversation = await _client
        .from('conversations')
        .insert({'type': 'direct', 'created_by': userId})
        .select('id')
        .single();

    final conversationId = conversation['id'].toString();

    try {
      await _client.from('conversation_members').insert([
        {'conversation_id': conversationId, 'profile_id': userId},
        {'conversation_id': conversationId, 'profile_id': otherId},
      ]);
    } catch (_) {
      await _client.from('conversations').delete().eq('id', conversationId);
      rethrow;
    }

    return conversationId;
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 100,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) throw const FormatException('Conversation invalide.');

    final response = await _client
        .from('messages')
        .select('id, conversation_id, sender_id, reply_to_id, content, message_type, created_at, edited_at, deleted_at')
        .eq('conversation_id', id)
        .order('created_at', ascending: true)
        .limit(limit);

    final messages = response
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();

    final senderIds = messages
        .map((message) => message['sender_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (senderIds.isEmpty) return messages;

    final profiles = await _client
        .from('profiles')
        .select('id, username, full_name, avatar_url, is_verified')
        .inFilter('id', senderIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final row in profiles)
        row['id'].toString(): Map<String, dynamic>.from(row),
    };

    for (final message in messages) {
      message['sender_profile'] = profileMap[message['sender_id']?.toString()];
    }

    return messages;
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? replyToId,
  }) async {
    final text = content.trim();
    if (messageType == 'text' && text.isEmpty) {
      throw const FormatException('Le message ne peut pas être vide.');
    }

    final allowedTypes = {'text', 'image', 'video', 'file', 'system'};
    if (!allowedTypes.contains(messageType)) {
      throw const FormatException('Type de message invalide.');
    }

    final data = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_id': _userId,
      'content': text.isEmpty ? null : text,
      'message_type': messageType,
    };

    if (replyToId != null && replyToId.trim().isNotEmpty) {
      data['reply_to_id'] = replyToId.trim();
    }

    final response = await _client.from('messages').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  static Future<void> markConversationRead(String conversationId) async {
    await _client
        .from('conversation_members')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('profile_id', _userId);
  }

  static Future<void> editMessage({
    required String messageId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) throw const FormatException('Le message ne peut pas être vide.');

    await _client
        .from('messages')
        .update({
          'content': text,
          'edited_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', _userId);
  }

  static Future<void> deleteMessage(String messageId) async {
    await _client
        .from('messages')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', messageId)
        .eq('sender_id', _userId);
  }

  static RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function() onChange,
  ) {
    final channel = _client.channel('tchaka:messages:$conversationId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (_) => onChange(),
    );
    channel.subscribe();
    return channel;
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
