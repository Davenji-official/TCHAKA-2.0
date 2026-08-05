import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectApplicationService {
  ProjectApplicationService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static String? get _currentUserId {
    return _client.auth.currentUser?.id;
  }

  static Future<Map<String, dynamic>?> getMyApplication(
    String projectId,
  ) async {
    final userId = _currentUserId;

    if (userId == null) {
      return null;
    }

    final response = await _client
        .from('project_applications')
        .select()
        .eq('project_id', projectId)
        .eq('applicant_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }
  static Future<Map<String, dynamic>>
      submitApplication({
    required String projectId,
    String? proposedRole,
    String? coverMessage,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw const AuthException(
        'Tu dois être connecté pour candidater.',
      );
    }

    final cleanProjectId = projectId.trim();

    if (cleanProjectId.isEmpty) {
      throw const FormatException(
        'Identifiant du projet invalide.',
      );
    }

    final data = <String, dynamic>{
      'project_id': cleanProjectId,
      'applicant_id': userId,
    };

    final role = proposedRole?.trim();
    if (role != null && role.isNotEmpty) {
      data['proposed_role'] = role;
    }

    final message = coverMessage?.trim();
    if (message != null && message.isNotEmpty) {
      data['cover_message'] = message;
    }

    final response = await _client
        .from('project_applications')
        .insert(data)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>>
      withdrawApplication(
    String applicationId,
  ) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw const AuthException(
        'Tu dois être connecté.',
      );
    }

    final response = await _client
        .from('project_applications')
        .update({
          'status': 'withdrawn',
        })
        .eq('id', applicationId)
        .eq('applicant_id', userId)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }
  static Future<List<Map<String, dynamic>>>
      getProjectApplications(
    String projectId,
  ) async {
    final userId = _currentUserId;

    if (userId == null) {
      throw const AuthException(
        'Tu dois être connecté.',
      );
    }

    final response = await _client
        .from('project_applications')
        .select()
        .eq('project_id', projectId)
        .order(
          'created_at',
          ascending: false,
        );

    return response
        .map<Map<String, dynamic>>(
          (application) =>
              Map<String, dynamic>.from(application),
        )
        .toList();
  }

  static Future<Map<String, dynamic>>
      reviewApplication({
    required String applicationId,
    required String status,
  }) async {
    final normalizedStatus = status.trim().toLowerCase();

    if (![
      'reviewing',
      'accepted',
      'rejected',
    ].contains(normalizedStatus)) {
      throw const FormatException(
        'Statut de candidature invalide.',
      );
    }

    final response = await _client.rpc(
      'review_project_application',
      params: {
        'p_application_id': applicationId,
        'p_status': normalizedStatus,
      },
    );

    return Map<String, dynamic>.from(response);
  }
  static Future<Map<String, dynamic>>
      acceptApplication({
    required String applicationId,
    String role = 'contributor',
  }) async {
    final response = await _client.rpc(
      'accept_project_application',
      params: {
        'p_application_id': applicationId,
        'p_role': role,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>>
      rejectApplication(
    String applicationId,
  ) async {
    final response = await _client.rpc(
      'reject_project_application',
      params: {
        'p_application_id': applicationId,
      },
    );

    return Map<String, dynamic>.from(response);
  }
}
