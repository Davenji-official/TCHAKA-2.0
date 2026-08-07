import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/urgent_need.dart';

class UrgentService {
  UrgentService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;

  static Future<List<UrgentNeed>> getActiveUrgencies({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('urgent_needs')
        .select()
        .inFilter('status', [
          UrgentStatus.active.name,
          UrgentStatus.mobilizing.name,
        ])
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response)
        .map(UrgentNeed.fromMap)
        .where((need) => need.isActive)
        .toList();
  }

  static Future<UrgentNeed?> getUrgency(
    String urgencyId,
  ) async {
    final response = await _client
        .from('urgent_needs')
        .select()
        .eq('id', urgencyId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UrgentNeed.fromMap(response);
  }

  static Future<UrgentNeed> createUrgency({
    required String title,
    required String description,
    required String category,
    required UrgentSeverity severity,
    String? location,
    double? latitude,
    double? longitude,
    List<String> requiredSkillIds = const [],
    List<String> resourceTypes = const [],
    List<UrgentTargetType> targetTypes = const [],
    DateTime? expiresAt,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError(
        'Vous devez être connecté pour créer une urgence.',
      );
    }

    if (title.trim().isEmpty) {
      throw ArgumentError(
        'Le titre de l’urgence est obligatoire.',
      );
    }

    if (description.trim().isEmpty) {
      throw ArgumentError(
        'La description de l’urgence est obligatoire.',
      );
    }

    final response = await _client
        .from('urgent_needs')
        .insert({
          'title': title.trim(),
          'description': description.trim(),
          'category': category.trim().isEmpty
              ? 'general'
              : category.trim(),
          'severity': severity.name,
          'status': UrgentStatus.active.name,
          'author_id': userId,
          'location': location?.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'required_skill_ids': requiredSkillIds,
          'resource_types': resourceTypes,
          'target_types':
              targetTypes.map((type) => type.name).toList(),
          'expires_at': expiresAt?.toIso8601String(),
        })
        .select()
        .single();

    return UrgentNeed.fromMap(response);
  }

  static Future<UrgentNeed> updateUrgency({
    required String urgencyId,
    String? title,
    String? description,
    String? category,
    UrgentSeverity? severity,
    UrgentStatus? status,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? requiredSkillIds,
    List<String>? resourceTypes,
    List<UrgentTargetType>? targetTypes,
    DateTime? expiresAt,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError(
        'Vous devez être connecté.',
      );
    }

    final values = <String, dynamic>{};

    if (title != null) {
      values['title'] = title.trim();
    }

    if (description != null) {
      values['description'] = description.trim();
    }

    if (category != null) {
      values['category'] = category.trim();
    }

    if (severity != null) {
      values['severity'] = severity.name;
    }

    if (status != null) {
      values['status'] = status.name;
    }

    if (location != null) {
      values['location'] = location.trim();
    }

    if (latitude != null) {
      values['latitude'] = latitude;
    }

    if (longitude != null) {
      values['longitude'] = longitude;
    }

    if (requiredSkillIds != null) {
      values['required_skill_ids'] = requiredSkillIds;
    }

    if (resourceTypes != null) {
      values['resource_types'] = resourceTypes;
    }

    if (targetTypes != null) {
      values['target_types'] =
          targetTypes.map((type) => type.name).toList();
    }

    if (expiresAt != null) {
      values['expires_at'] =
          expiresAt.toIso8601String();
    }

    if (values.isEmpty) {
      final current = await getUrgency(urgencyId);

      if (current == null) {
        throw StateError(
          'Urgence introuvable.',
        );
      }

      return current;
    }

    final response = await _client
        .from('urgent_needs')
        .update(values)
        .eq('id', urgencyId)
        .eq('author_id', userId)
        .select()
        .single();

    return UrgentNeed.fromMap(response);
  }

  static Future<UrgentNeed> startMobilization(
    String urgencyId,
  ) {
    return updateUrgency(
      urgencyId: urgencyId,
      status: UrgentStatus.mobilizing,
    );
  }

  static Future<UrgentNeed> resolveUrgency(
    String urgencyId,
  ) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError(
        'Vous devez être connecté.',
      );
    }

    final response = await _client
        .from('urgent_needs')
        .update({
          'status': UrgentStatus.resolved.name,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', urgencyId)
        .eq('author_id', userId)
        .select()
        .single();

    return UrgentNeed.fromMap(response);
  }

  static Future<void> expireOldUrgencies() async {
    await _client.rpc('expire_old_urgent_needs');
  }

  static Stream<List<Map<String, dynamic>>>
      watchUrgencies() {
    return _client
        .from('urgent_needs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
