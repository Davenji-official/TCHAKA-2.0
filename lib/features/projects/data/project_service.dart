import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  ProjectService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<Map<String, dynamic>> createProject({
    required String title,
    String? description,
    String? problemStatement,
    String? solutionDescription,
    String? category,
    String? country,
    String? city,
    String? coverImageUrl,
    String status = 'draft',
    String visibility = 'public',
    double? fundingGoal,
    String fundingCurrency = 'USD',
    int teamSize = 1,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'Tu dois être connecté pour créer un projet.',
      );
    }

    final cleanTitle = title.trim();

    if (cleanTitle.length < 3) {
      throw const PostgrestException(
        message:
            'Le titre doit contenir au moins 3 caractères.',
      );
    }

    if (cleanTitle.length > 150) {
      throw const PostgrestException(
        message:
            'Le titre ne peut pas dépasser 150 caractères.',
      );
    }

    if (teamSize < 1) {
      throw const PostgrestException(
        message:
            'La taille de l’équipe doit être supérieure ou égale à 1.',
      );
    }

    final slug = _buildUniqueSlug(cleanTitle);

    final data = <String, dynamic>{
      'creator_id': user.id,
      'title': cleanTitle,
      'slug': slug,
      'status': status,
      'visibility': visibility,
      'funding_currency': fundingCurrency,
      'team_size': teamSize,
    };

    _addOptionalValue(
      data,
      'description',
      description,
    );

    _addOptionalValue(
      data,
      'problem_statement',
      problemStatement,
    );

    _addOptionalValue(
      data,
      'solution_description',
      solutionDescription,
    );

    _addOptionalValue(
      data,
      'category',
      category,
    );

    _addOptionalValue(
      data,
      'country',
      country,
    );

    _addOptionalValue(
      data,
      'city',
      city,
    );

    _addOptionalValue(
      data,
      'cover_image_url',
      coverImageUrl,
    );

    if (fundingGoal != null) {
      data['funding_goal'] = fundingGoal;
    }

    final response = await _client
        .from('projects')
        .insert(data)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> getProject(
    String projectId,
  ) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('id', projectId)
        .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getMyProjects()
      async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'Tu dois être connecté pour voir tes projets.',
      );
    }

    final response = await _client
        .from('projects')
        .select()
        .eq('creator_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    return response
        .map<Map<String, dynamic>>(
          (project) =>
              Map<String, dynamic>.from(project),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>>
      getPublicProjectsByCreator(
    String creatorId,
  ) async {
    final normalizedCreatorId = creatorId.trim();

    if (normalizedCreatorId.isEmpty) {
      throw const FormatException(
        'Identifiant du créateur invalide.',
      );
    }

    final response = await _client
        .from('projects')
        .select()
        .eq('creator_id', normalizedCreatorId)
        .eq('visibility', 'public')
        .eq('status', 'published')
        .order(
          'published_at',
          ascending: false,
        );

    return response
        .map<Map<String, dynamic>>(
          (project) =>
              Map<String, dynamic>.from(project),
        )
        .toList();
  }
    static Future<Map<String, dynamic>> updateProject({
    required String projectId,
    String? title,
    String? description,
    String? problemStatement,
    String? solutionDescription,
    String? category,
    String? country,
    String? city,
    String? coverImageUrl,
    String? status,
    String? visibility,
    double? fundingGoal,
    String? fundingCurrency,
    int? teamSize,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) {
      final cleanTitle = title.trim();

      if (cleanTitle.length < 3) {
        throw const PostgrestException(
          message:
              'Le titre doit contenir au moins 3 caractères.',
        );
      }

      if (cleanTitle.length > 150) {
        throw const PostgrestException(
          message:
              'Le titre ne peut pas dépasser 150 caractères.',
        );
      }

      data['title'] = cleanTitle;
    }

    _addOptionalValue(
      data,
      'description',
      description,
    );

    _addOptionalValue(
      data,
      'problem_statement',
      problemStatement,
    );

    _addOptionalValue(
      data,
      'solution_description',
      solutionDescription,
    );

    _addOptionalValue(
      data,
      'category',
      category,
    );

    _addOptionalValue(
      data,
      'country',
      country,
    );

    _addOptionalValue(
      data,
      'city',
      city,
    );

    _addOptionalValue(
      data,
      'cover_image_url',
      coverImageUrl,
    );

    if (status != null) {
      data['status'] = status;
    }

    if (visibility != null) {
      data['visibility'] = visibility;
    }

    if (fundingGoal != null) {
      data['funding_goal'] = fundingGoal;
    }

    if (fundingCurrency != null) {
      data['funding_currency'] = fundingCurrency;
    }

    if (teamSize != null) {
      if (teamSize < 1) {
        throw const PostgrestException(
          message:
              'La taille de l’équipe doit être supérieure ou égale à 1.',
        );
      }

      data['team_size'] = teamSize;
    }

    if (data.isEmpty) {
      return getProject(projectId);
    }

    final response = await _client
        .from('projects')
        .update(data)
        .eq('id', projectId)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<void> deleteProject(
    String projectId,
  ) async {
    await _client
        .from('projects')
        .delete()
        .eq('id', projectId);
  }
    static String _buildUniqueSlug(
    String title,
  ) {
    final normalized = title
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9\s-]'),
          '',
        )
        .trim()
        .replaceAll(
          RegExp(r'\s+'),
          '-',
        )
        .replaceAll(
          RegExp(r'-+'),
          '-',
        );

    final base =
        normalized.isEmpty ? 'projet' : normalized;

    final timestamp =
        DateTime.now().microsecondsSinceEpoch;

    return '$base-$timestamp';
  }

  static void _addOptionalValue(
    Map<String, dynamic> data,
    String key,
    String? value,
  ) {
    if (value == null) {
      return;
    }

    final cleanValue = value.trim();

    if (cleanValue.isNotEmpty) {
      data[key] = cleanValue;
    }
  }
}
