class Note {
  final String id;
  final String encryptedContent;
  final String iv;
  final DateTime createdAt;

  final String hmac;
  final Map<String, dynamic>? cipherMeta;

  // Decrypted property (not stored in DB)
  String? decryptedContent;
  String? decryptedTitle;

  Note({
    required this.id,
    required this.encryptedContent,
    required this.iv,
    required this.createdAt,
    required this.hmac,
    this.cipherMeta,
    this.decryptedContent,
    this.decryptedTitle,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      encryptedContent: map['encrypted_content'] as String,
      iv: (map['iv'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      hmac: (map['hmac'] as String?) ?? '',
      cipherMeta: map['cipher_meta'] as Map<String, dynamic>?,
    );
  }
}
