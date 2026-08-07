import 'package:supabase_flutter/supabase_flutter.dart';

import '../../projects/data/project_matching_service.dart';

class FeedService {
  FeedService._();

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

    final data = response as List<dynamic>;

    final projects = data
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    final userId = _client.auth.currentUser?.id;

    if (userId == null || projects.isEmpty) {
      return projects;
    }

    try {
      final userSkills =
          await ProjectMatchingService.getMySkills();

      if (userSkills.isEmpty) {
        return projects;
      }

      return ProjectMatchingService.rankProjects(
        projects: projects,
        userSkills: userSkills,
      );
    } catch (_) {
      // Le feed reste disponible même si le matchmaking
      // n'est temporairement pas disponible.
      return projects;
    }
  }
}
