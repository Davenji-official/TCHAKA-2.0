import 'package:supabase_flutter/supabase_flutter.dart';

class CollaborationService {
  CollaborationService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getMembers(
    String projectId,
  ) async {
    final response = await _client.rpc(
      'get_project_members',
      params: {'p_project_id': projectId},
    );

    return List<Map<String, dynamic>>.from(response as List);
  }

  static Future<Map<String, dynamic>> updateMemberRole({
    required String projectId,
    required String profileId,
    required String role,
  }) async {
    final response = await _client.rpc(
      'update_project_member_role',
      params: {
        'p_project_id': projectId,
        'p_profile_id': profileId,
        'p_role': role,
      },
    );

    return _singleRow(response);
  }

  static Future<Map<String, dynamic>> removeMember({
    required String projectId,
    required String profileId,
  }) async {
    final response = await _client.rpc(
      'remove_project_member',
      params: {
        'p_project_id': projectId,
        'p_profile_id': profileId,
      },
    );

    return _singleRow(response);
  }

  static Map<String, dynamic> _singleRow(dynamic response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    throw const FormatException('Réponse de collaboration invalide.');
  }
}
