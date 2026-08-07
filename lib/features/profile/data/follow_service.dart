import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  FollowService._();

  static final SupabaseClient _client = Supabase.instance.client;

  /// Follower/following counts plus the rest of the profile's activity
  /// stats, via the existing get_user_activity_stats RPC. Returns null
  /// when the RPC has nothing to show (own profile always resolves;
  /// other profiles resolve only if they have a published public
  /// project — an existing constraint from migration 025, not
  /// something this call changes).
  static Future<Map<String, dynamic>?> getActivityStats(
    String profileId,
  ) async {
    final response = await _client.rpc(
      'get_user_activity_stats',
      params: {'p_profile_id': profileId},
    );

    final rows = response as List<dynamic>;

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first as Map);
  }

  static Future<List<Map<String, dynamic>>> getFollowers(
    String profileId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('follows')
        .select('follower_id, created_at')
        .eq('following_id', profileId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return _attachProfiles(rows, idKey: 'follower_id');
  }

  static Future<List<Map<String, dynamic>>> getFollowing(
    String profileId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('follows')
        .select('following_id, created_at')
        .eq('follower_id', profileId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return _attachProfiles(rows, idKey: 'following_id');
  }

  /// Batch-fetches public_profiles for every row's [idKey] and merges
  /// each one back onto the row under a `profile` key.
  static Future<List<Map<String, dynamic>>> _attachProfiles(
    List<Map<String, dynamic>> rows, {
    required String idKey,
  }) async {
    final ids = rows
        .map((row) => row[idKey] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return rows;
    }

    final response = await _client
        .from('public_profiles')
        .select('id, username, full_name, avatar_url, bio')
        .inFilter('id', ids);

    final profilesById = <String, Map<String, dynamic>>{
      for (final profile in (response as List<dynamic>))
        (profile as Map)['id'] as String: Map<String, dynamic>.from(
          profile,
        ),
    };

    for (final row in rows) {
      final id = row[idKey] as String?;

      if (id != null) {
        row['profile'] = profilesById[id];
      }
    }

    // Drop rows whose profile could not be resolved (e.g. a stale
    // reference or a profile that no longer passes visibility rules).
    return rows.where((row) => row['profile'] != null).toList();
  }
}
