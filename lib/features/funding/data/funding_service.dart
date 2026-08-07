import 'package:supabase_flutter/supabase_flutter.dart';

class FundingService {
  FundingService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Tu dois être connecté.');
    return id;
  }

  static Future<Map<String, dynamic>?> getCampaign(String projectId) async {
    final response = await _client
        .from('funding_campaigns')
        .select('id, project_id, creator_id, goal_amount, currency, description, status, starts_at, ends_at, created_at, updated_at')
        .eq('project_id', projectId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>?> getPublicStats(String projectId) async {
    final response = await _client.rpc(
      'get_project_funding_stats',
      params: {'p_project_id': projectId},
    );
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) return Map<String, dynamic>.from(response);
    return null;
  }

  static Future<Map<String, dynamic>> createCampaign({
    required String projectId,
    required double goalAmount,
    required String currency,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final amount = goalAmount;
    if (amount <= 0) throw const FormatException('L’objectif doit être supérieur à zéro.');
    const currencies = {'USD', 'HTG', 'EUR', 'CAD'};
    if (!currencies.contains(currency)) throw const FormatException('Devise non supportée.');

    final response = await _client.from('funding_campaigns').insert({
      'project_id': projectId,
      'creator_id': _userId,
      'goal_amount': amount,
      'currency': currency,
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> updateCampaign({
    required String campaignId,
    double? goalAmount,
    String? currency,
    String? description,
    String? status,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final data = <String, dynamic>{};
    if (goalAmount != null) {
      if (goalAmount <= 0) throw const FormatException('L’objectif doit être supérieur à zéro.');
      data['goal_amount'] = goalAmount;
    }
    if (currency != null) {
      const currencies = {'USD', 'HTG', 'EUR', 'CAD'};
      if (!currencies.contains(currency)) throw const FormatException('Devise non supportée.');
      data['currency'] = currency;
    }
    if (description != null) data['description'] = description.trim().isEmpty ? null : description.trim();
    if (status != null) {
      const statuses = {'draft', 'active', 'paused', 'completed', 'cancelled'};
      if (!statuses.contains(status)) throw const FormatException('Statut de campagne invalide.');
      data['status'] = status;
    }
    if (startsAt != null) data['starts_at'] = startsAt.toUtc().toIso8601String();
    if (endsAt != null) data['ends_at'] = endsAt.toUtc().toIso8601String();
    if (data.isEmpty) throw const FormatException('Aucune modification.');

    final response = await _client
        .from('funding_campaigns')
        .update(data)
        .eq('id', campaignId)
        .eq('creator_id', _userId)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> createPendingContribution({
    required String campaignId,
    required double amount,
    required String currency,
    String? paymentProvider,
    String? providerReference,
  }) async {
    if (amount <= 0) throw const FormatException('Le montant doit être supérieur à zéro.');
    const currencies = {'USD', 'HTG', 'EUR', 'CAD'};
    if (!currencies.contains(currency)) throw const FormatException('Devise non supportée.');

    final response = await _client.from('funding_contributions').insert({
      'campaign_id': campaignId,
      'contributor_id': _userId,
      'amount': amount,
      'currency': currency,
      'status': 'pending',
      'payment_provider': paymentProvider,
      'provider_reference': providerReference,
    }).select().single();
    return Map<String, dynamic>.from(response);
  }
}
