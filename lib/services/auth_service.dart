import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(
      String email, String password, String username) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Storing username in user_metadata
      );

      // Also insert into public user_profiles table directly if needed,
      // but usually a Trigger is better.
      // Based on the SQL schema provided, there is a user_profiles table.
      // Often with Supabase, you use a trigger on auth.users to populate public.user_profiles.
      // If no trigger, we should insert manually.
      // Since the user didn't mention a trigger, we should try to insert.

      if (response.user != null) {
        await _supabase.from('user_profiles').insert({
          'id': response.user!.id,
          'username': username,
          'email': email,
        });
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
