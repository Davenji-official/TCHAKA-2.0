import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectEngagementService {
  ProjectEngagementService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('Utilisateur non connecté.');
    }

    return user.id;
  }

  static Future<bool> isProjectLiked(String projectId) async {
    final response = await _client
        .from('project_likes')
        .select('project_id')
        .eq('project_id', projectId)
        .eq('profile_id', _userId)
        .maybeSingle();

    return response != null;
  }

  static Future<bool> toggleProjectLike({
    required String projectId,
  }) async {
    final userId = _userId;

    final existing = await _client
        .from('project_likes')
        .select('project_id')
        .eq('project_id', projectId)
        .eq('profile_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('project_likes')
          .delete()
          .eq('project_id', projectId)
          .eq('profile_id', userId);

      return false;
    }

    await _client.from('project_likes').insert({
      'project_id': projectId,
      'profile_id': userId,
    });

    return true;
  }

  static Future<bool> isProjectBookmarked(String projectId) async {
    final response = await _client
        .from('project_bookmarks')
        .select('project_id')
        .eq('project_id', projectId)
        .eq('profile_id', _userId)
        .maybeSingle();

    return response != null;
  }

  static Future<bool> toggleProjectBookmark({
    required String projectId,
  }) async {
    final userId = _userId;

    final existing = await _client
        .from('project_bookmarks')
        .select('project_id')
        .eq('project_id', projectId)
        .eq('profile_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('project_bookmarks')
          .delete()
          .eq('project_id', projectId)
          .eq('profile_id', userId);

      return false;
    }

    await _client.from('project_bookmarks').insert({
      'project_id': projectId,
      'profile_id': userId,
    });

    return true;
  }

  static Future<bool> isFollowingCreator(String creatorId) async {
    final response = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', _userId)
        .eq('following_id', creatorId)
        .maybeSingle();

    return response != null;
  }

  static Future<bool> toggleCreatorFollow({
    required String creatorId,
  }) async {
    final userId = _userId;

    if (userId == creatorId) {
      throw const PostgrestException(
        message: 'Impossible de se suivre soi-même.',
      );
    }

    final existing = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId)
        .eq('following_id', creatorId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', creatorId);

      return false;
    }

    await _client.from('follows').insert({
      'follower_id': userId,
      'following_id': creatorId,
    });

    return true;
  }

  static Future<Map<String, dynamic>?> getProjectStats({
    required String projectId,
  }) async {
    final response = await _client.rpc(
      'get_project_stats',
      params: {
        'p_project_id': projectId,
      },
    );

    if (response == null) {
      return null;
    }

    if (response is List) {
      if (response.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(
        response.first as Map,
      );
    }

    return Map<String, dynamic>.from(
      response as Map,
    );
  }
}
