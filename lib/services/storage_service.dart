import 'dart:typed_data';
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
    required String combinedEncryptedData, // Encrypted data (base64)
    required String
        hmac, // You might generate a HMAC of the ciphertext/iv for integrity
    required Map<String, dynamic> cipherMeta,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // New encryption format: single base64 string (no IV:CipherText split)
    // For backwards compatibility, store entire string in encrypted_content
    // IV field is now just a placeholder since Modified RSA doesn't use IV
    final encryptedContent = combinedEncryptedData;
    const iv = 'NO_IV_USED'; // Placeholder for new encryption algorithm

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

    // New encryption format: single base64 string (no IV:CipherText split)
    final encryptedContent = combinedEncryptedData;
    const iv = 'NO_IV_USED'; // Placeholder for new encryption algorithm

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

  Future<void> deleteNote(String noteId) async {
    try {
      await _supabase.from('encrypted_notes').delete().eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  /// ONEGATE ATTACHMENT

  /// Upload encrypted attachment bytes to Supabase Storage
  /// Returns the path to the file.
  Future<String> uploadAttachment(
      String userId, String noteId, Uint8List encryptedData) async {
    try {
      // Filename: timestamp_uuid_part.bin
      String shortId = noteId.length >= 8 ? noteId.substring(0, 8) : noteId;
      final filename = '${DateTime.now().millisecondsSinceEpoch}_$shortId.bin';
      final path = '$userId/$filename'; // userId/filename folder structure

      await _supabase.storage.from('attachment').uploadBinary(
            path,
            encryptedData,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return path;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  /// Get Signed URL for downloading attachment
  Future<String> getAttachmentUrl(String path) async {
    try {
      // Private bucket requires signed URL
      return await _supabase.storage
          .from('attachment')
          .createSignedUrl(path, 60 * 60); // 1 hour expiry
    } catch (e) {
      throw Exception('Failed to get attachment URL: $e');
    }
  }

  /// Download attachment bytes directly (alternative to URL)
  Future<Uint8List> downloadAttachment(String path) async {
    try {
      return await _supabase.storage.from('attachment').download(path);
    } catch (e) {
      throw Exception('Failed to download attachment: $e');
    }
  }
}
