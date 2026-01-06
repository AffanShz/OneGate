import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CryptoUtils {
  // Fixed key for demo purposes. In production, this should be derived securely.
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  static final _iv = encrypt.IV.fromLength(16);

  static String encryptAES(String plainText) {
    if (plainText.isEmpty) return "";
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptAES(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return "";
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      return "Error decrypting";
    }
  }

  static String classicModifiedPlayfair(String text) {
    // Placeholder for "Modified Playfair" logic
    // Just reversing + some shift for demo visuals
    return text.split('').reversed.join().toUpperCase();
  }

  static String generateSha256(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
