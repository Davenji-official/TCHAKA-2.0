import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _client
        .from('profiles')
        .select(
          'id, username, full_name, avatar_url, bio, country, city, '
          'is_verified, is_premium, created_at, updated_at',
        )
        .eq('id', user.id)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> getProfileById(
    String userId,
  ) async {
    return _client
        .from('public_profiles')
        .select(
          'id, username, full_name, avatar_url, bio, country, city, '
          'is_verified, is_premium, created_at',
        )
        .eq('id', userId)
        .maybeSingle();
  }

  static Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? country,
    String? city,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('Utilisateur non authentifié.');
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (username != null) {
      updates['username'] = username.trim();
    }

    if (fullName != null) {
      updates['full_name'] = fullName.trim();
    }

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl.trim();
    }

    if (bio != null) {
      updates['bio'] = bio.trim();
    }

    if (country != null) {
      updates['country'] = country.trim();
    }

    if (city != null) {
      updates['city'] = city.trim();
    }

    await _client.from('profiles').update(updates).eq('id', user.id);
  }
}
