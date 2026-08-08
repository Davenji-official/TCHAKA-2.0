import 'package:supabase_flutter/supabase_flutter.dart';

class SkillService {
  SkillService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static String _requireUserId() {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw const AuthException('Utilisateur non authentifié.');
    }

    return userId;
  }

  /// Récupère toutes les compétences disponibles dans le catalogue.
  static Future<List<Map<String, dynamic>>> getAllSkills() async {
    final response = await _client
        .from('skills')
        .select('id, name, slug, category')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Recherche des compétences par nom, slug ou catégorie.
  static Future<List<Map<String, dynamic>>> searchSkills(
    String query,
  ) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return getAllSkills();
    }

    final response = await _client
        .from('skills')
        .select('id, name, slug, category')
        .or(
          'name.ilike.%$normalizedQuery%,'
          'slug.ilike.%$normalizedQuery%,'
          'category.ilike.%$normalizedQuery%',
        )
        .order('name')
        .limit(30);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupère les compétences du profil actuellement connecté.
  static Future<List<Map<String, dynamic>>> getMySkills() async {
    final userId = _requireUserId();

    final response = await _client
        .from('user_skills')
        .select(
          'profile_id, skill_id, proficiency, created_at, '
          'skills(id, name, slug, category)',
        )
        .eq('profile_id', userId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupère les compétences publiques d'un profil.
  static Future<List<Map<String, dynamic>>> getUserSkills(
    String profileId,
  ) async {
    final normalizedProfileId = profileId.trim();

    if (normalizedProfileId.isEmpty) {
      throw const FormatException(
        'Identifiant de profil invalide.',
      );
    }

    final response = await _client
        .from('user_skills')
        .select(
          'profile_id, skill_id, proficiency, created_at, '
          'skills(id, name, slug, category)',
        )
        .eq('profile_id', normalizedProfileId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Ajoute une compétence au profil actuel.
  static Future<void> addSkill({
    required String skillId,
    int? proficiency,
  }) async {
    final userId = _requireUserId();

    final normalizedProficiency = proficiency?.clamp(1, 5);

    await _client.from('user_skills').upsert(
      {
        'profile_id': userId,
        'skill_id': skillId,
        'proficiency': normalizedProficiency,
      },
      onConflict: 'profile_id,skill_id',
    );
  }

  /// Modifie le niveau de maîtrise d'une compétence.
  static Future<void> updateProficiency({
    required String skillId,
    required int proficiency,
  }) async {
    final userId = _requireUserId();

    final normalizedProficiency = proficiency.clamp(1, 5);

    await _client
        .from('user_skills')
        .update({
          'proficiency': normalizedProficiency,
        })
        .eq('profile_id', userId)
        .eq('skill_id', skillId);
  }

  /// Supprime une compétence du profil actuel.
  static Future<void> removeSkill({
    required String skillId,
  }) async {
    final userId = _requireUserId();

    await _client
        .from('user_skills')
        .delete()
        .eq('profile_id', userId)
        .eq('skill_id', skillId);
  }
}
