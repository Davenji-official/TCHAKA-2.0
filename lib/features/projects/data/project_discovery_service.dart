import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/project_discovery_filter.dart';

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

    if (response is! List) {
      throw const FormatException(
        'Réponse invalide de get_project_feed.',
      );
    }

    return response
        .map(
          (item) => Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getProjectsForFilter({
    required ProjectDiscoveryFilter filter,
    int limit = 20,
    int offset = 0,
  }) async {
    final projects = await getProjectFeed(
      limit: limit,
      offset: offset,
    );

    return _applyClientFilter(
      projects,
      filter,
    );
  }
    static List<Map<String, dynamic>> _applyClientFilter(
    List<Map<String, dynamic>> projects,
    ProjectDiscoveryFilter filter,
  ) {
    final result = List<Map<String, dynamic>>.from(
      projects,
    );

    switch (filter) {
      case ProjectDiscoveryFilter.forYou:
        return result;

      case ProjectDiscoveryFilter.trending:
        return _sortByScore(result);

      case ProjectDiscoveryFilter.rising:
        return _sortByRecentActivity(result);

      case ProjectDiscoveryFilter.mostLiked:
        return _sortByNumericField(
          result,
          'likes_count',
        );

      case ProjectDiscoveryFilter.mostFollowed:
        return _sortByNumericField(
          result,
          'followers_count',
        );

      case ProjectDiscoveryFilter.impact:
        return _sortByNumericField(
          result,
          'impact_score',
        );

      case ProjectDiscoveryFilter.nearby:
        return result;
    }
  }

  static List<Map<String, dynamic>> _sortByScore(
    List<Map<String, dynamic>> projects,
  ) {
    projects.sort((a, b) {
      final aScore = _numberValue(
        a['feed_score'],
      );

      final bScore = _numberValue(
        b['feed_score'],
      );

      return bScore.compareTo(aScore);
    });

    return projects;
  }

  static List<Map<String, dynamic>> _sortByNumericField(
    List<Map<String, dynamic>> projects,
    String field,
  ) {
    projects.sort((a, b) {
      final aValue = _numberValue(a[field]);
      final bValue = _numberValue(b[field]);

      return bValue.compareTo(aValue);
    });

    return projects;
  }
    static List<Map<String, dynamic>> _sortByRecentActivity(
    List<Map<String, dynamic>> projects,
  ) {
    projects.sort((a, b) {
      final aDate = _dateValue(
        a['created_at'],
      );

      final bDate = _dateValue(
        b['created_at'],
      );

      return bDate.compareTo(aDate);
    });

    return projects;
  }

  static double _numberValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime _dateValue(
    dynamic value,
  ) {
    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
