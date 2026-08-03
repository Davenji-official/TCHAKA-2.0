import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() {
    return _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }
}
