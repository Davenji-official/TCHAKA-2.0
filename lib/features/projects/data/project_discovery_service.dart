import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectDiscoveryService {
  ProjectDiscoveryService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getProjectFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'get_project_feed',
      params: {
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      (response as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }
}
