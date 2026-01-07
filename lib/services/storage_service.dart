import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all notes for the current user
  /// The RLS policies ensure we only get our own notes.
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    try {
      final response = await _supabase
          .from('encrypted_notes')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }

  /// Create a new encrypted note
  /// [encryptedContent] should be the result of EncryptionService.encryptData
  /// which returns (iv:content).
  ///
  /// The user schema requires:
  /// - encrypted_content
  /// - iv (we need to split the result from EncryptionService)
  /// - hmac (we might need to generate this or just store dummy/hash if not using specific HMAC logic separately)
  /// - cipher_meta (jsonb)
  Future<void> createNote({
    required String combinedEncryptedData, // "IV:CipherText"
    required String
        hmac, // You might generate a HMAC of the ciphertext/iv for integrity
    required Map<String, dynamic> cipherMeta,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Split the combined string from EncryptionService
    final parts = combinedEncryptedData.split(':');
    final iv = parts[0];
    final encryptedContent = parts[1];

    try {
      await _supabase.from('encrypted_notes').insert({
        'user_id': user.id,
        'encrypted_content': encryptedContent,
        'iv': iv,
        'hmac':
            hmac, // For this MVP, we can store a placeholder or detailed HMAC if implemented
        'cipher_meta': cipherMeta,
      });
    } catch (e) {
      throw Exception('Failed to save note: $e');
    }
  }

  /// Update an existing note (e.g., for re-encryption)
  Future<void> updateNote({
    required String noteId,
    required String combinedEncryptedData,
    required String hmac,
    required Map<String, dynamic> cipherMeta,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final parts = combinedEncryptedData.split(':');
    final iv = parts[0];
    final encryptedContent = parts[1];

    try {
      await _supabase.from('encrypted_notes').update({
        'encrypted_content': encryptedContent,
        'iv': iv,
        'hmac': hmac,
        'cipher_meta': cipherMeta,
        // 'updated_at': DateTime.now().toIso8601String(), // If you have this column
      }).eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  /// Delete a note by ID
  Future<void> deleteNote(String noteId) async {
    try {
      await _supabase.from('encrypted_notes').delete().eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }
}
