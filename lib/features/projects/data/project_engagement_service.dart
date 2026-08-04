import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectEngagementService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? get _currentUserId {
    return _client.auth.currentUser?.id;
  }

  static Future<bool> isProjectLiked(
    String projectId,
  ) async {
    final userId = _currentUserId;

    if (userId == null) {
      return false;
    }

    final response = await _client
        .from('project_likes')
        .select('id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  static Future<bool> isProjectBookmarked(
    String projectId,
  ) async {
    final userId = _currentUserId;

    if (userId == null) {
      return false;
    }

    final response = await _client
        .from('project_bookmarks')
        .select('id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  static Future<bool> isFollowingCreator(
    String creatorId,
  ) async {
    final userId = _currentUserId;

    if (userId == null || userId == creatorId) {
      return false;
    }

    final response = await _client
        .from('user_follows')
        .select('id')
        .eq('follower_id', userId)
        .eq('following_id', creatorId)
        .maybeSingle();

    return response != null;
  }
    static Future<bool> toggleProjectLike({
    required String projectId,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final existing = await _client
        .from('project_likes')
        .select('id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('project_likes')
          .delete()
          .eq('id', existing['id']);

      return false;
    }

    await _client.from('project_likes').insert({
      'project_id': projectId,
      'user_id': userId,
    });

    return true;
  }

  static Future<bool> toggleProjectBookmark({
    required String projectId,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final existing = await _client
        .from('project_bookmarks')
        .select('id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('project_bookmarks')
          .delete()
          .eq('id', existing['id']);

      return false;
    }

    await _client.from('project_bookmarks').insert({
      'project_id': projectId,
      'user_id': userId,
    });

    return true;
  }
    static Future<bool> toggleCreatorFollow({
    required String creatorId,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw Exception('Utilisateur non connecté.');
    }

    if (userId == creatorId) {
      throw Exception('Impossible de se suivre soi-même.');
    }

    final existing = await _client
        .from('user_follows')
        .select('id')
        .eq('follower_id', userId)
        .eq('following_id', creatorId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('user_follows')
          .delete()
          .eq('id', existing['id']);

      return false;
    }

    await _client.from('user_follows').insert({
      'follower_id': userId,
      'following_id': creatorId,
    });

    return true;
  }
}
