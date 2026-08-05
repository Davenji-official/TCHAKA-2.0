import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/project_discovery_filter.dart';

class ProjectDiscoveryService {
  ProjectDiscoveryService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

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

    return _normalizeResponse(
      response,
      functionName: 'get_project_feed',
    );
  }

  static Future<List<Map<String, dynamic>>> searchProjects({
    String? query,
    String? category,
    String? country,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'search_projects',
      params: {
        'p_query': _nullableText(query),
        'p_category': _nullableText(category),
        'p_country': _nullableText(country),
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return _normalizeResponse(
      response,
      functionName: 'search_projects',
    );
  }

  static Future<List<Map<String, dynamic>>> discoverProjects({
    String? query,
    ProjectDiscoveryFilter filter =
        ProjectDiscoveryFilter.forYou,
    String? category,
    String? country,
    int limit = 20,
    int offset = 0,
  }) async {
    final normalizedQuery = _nullableText(query);
    final normalizedCategory = _nullableText(category);
    final normalizedCountry = _nullableText(country);

    final hasSearch =
        normalizedQuery != null ||
        normalizedCategory != null ||
        normalizedCountry != null;

    if (hasSearch) {
      final projects = await searchProjects(
        query: normalizedQuery,
        category: normalizedCategory,
        country: normalizedCountry,
        limit: limit,
        offset: offset,
      );

      return _applyClientFilter(
        projects,
        filter,
      );
    }

    return getProjectsForFilter(
      filter: filter,
      limit: limit,
      offset: offset,
    );
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
    final result =
        List<Map<String, dynamic>>.from(projects);

    switch (filter) {
      case ProjectDiscoveryFilter.forYou:
        return _sortByScore(result);

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
        return _sortByNearby(result);
    }
  }

  static List<Map<String, dynamic>> _sortByScore(
    List<Map<String, dynamic>> projects,
  ) {
    projects.sort((a, b) {
      final aScore =
          _numberValue(a['feed_score']);

      final bScore =
          _numberValue(b['feed_score']);

      final scoreComparison =
          bScore.compareTo(aScore);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return _dateValue(
        b['published_at'] ??
            b['created_at'],
      ).compareTo(
        _dateValue(
          a['published_at'] ??
              a['created_at'],
        ),
      );
    });

    return projects;
  }

  static List<Map<String, dynamic>> _sortByNumericField(
    List<Map<String, dynamic>> projects,
    String field,
  ) {
    projects.sort((a, b) {
      final aValue =
          _numberValue(a[field]);

      final bValue =
          _numberValue(b[field]);

      final comparison =
          bValue.compareTo(aValue);

      if (comparison != 0) {
        return comparison;
      }

      return _dateValue(
        b['published_at'] ??
            b['created_at'],
      ).compareTo(
        _dateValue(
          a['published_at'] ??
              a['created_at'],
        ),
      );
    });

    return projects;
  }

  static List<Map<String, dynamic>> _sortByRecentActivity(
    List<Map<String, dynamic>> projects,
  ) {
    projects.sort((a, b) {
      final aDate = _dateValue(
        a['published_at'] ??
            a['created_at'],
      );

      final bDate = _dateValue(
        b['published_at'] ??
            b['created_at'],
      );

      final dateComparison =
          bDate.compareTo(aDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final aScore =
          _numberValue(a['feed_score']);

      final bScore =
          _numberValue(b['feed_score']);

      return bScore.compareTo(aScore);
    });

    return projects;
  }

  static List<Map<String, dynamic>> _sortByNearby(
    List<Map<String, dynamic>> projects,
  ) {
    // Les coordonnées géographiques nécessaires
    // ne sont pas encore disponibles.
    return _sortByScore(projects);
  }
  static List<Map<String, dynamic>> _normalizeResponse(
    dynamic response, {
    required String functionName,
  }) {
    if (response == null) {
      return [];
    }

    if (response is! List) {
      throw FormatException(
        'Réponse invalide de $functionName.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static String? _nullableText(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized == null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
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

  static int _intValue(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double getProjectEngagementScore(
    Map<String, dynamic> project,
  ) {
    final likes =
        _intValue(project['likes_count']);

    final comments =
        _intValue(project['comments_count']);

    final bookmarks =
        _intValue(project['bookmarks_count']);

    final followers =
        _intValue(project['followers_count']);

    final matchingSkills =
        _intValue(
          project['matching_skills_count'],
        );

    final impactScore =
        _numberValue(
          project['impact_score'],
        );

    return (likes * 2) +
        (comments * 3) +
        (bookmarks * 2) +
        followers +
        (matchingSkills * 10) +
        impactScore;
  }

  static bool isTrending(
    Map<String, dynamic> project,
  ) {
    final score =
        _numberValue(project['feed_score']);

    return score >= 20;
  }

  static bool isRising(
    Map<String, dynamic> project,
  ) {
    final createdAt = _dateValue(
      project['published_at'] ??
          project['created_at'],
    );

    final age =
        DateTime.now().difference(createdAt);

    return age.inDays <= 7;
  }
}
