import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;

class EncryptionService {
  // Static key components for demonstration (ideally should be user-specific or environment based)
  // For this implementation, we will use a derived key concept.

  // Classic Encryption: Vigenère Cipher
  // We will use a mixed alphabet for better "classic" security
  static const String _vigenereAlphabet =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 !\"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~";

  /// 2-Layer Encryption:
  /// 1. Classic (Vigenere)
  /// 2. Modern (AES-256)
  static String encryptData(String plainText, String secretKey) {
    if (plainText.isEmpty) return "";

    // Layer 1: Classic - Vigenère Cipher
    String vigenereEncrypted = _vigenereEncrypt(plainText, secretKey);

    // Layer 2: Modern - AES-256
    // We derive a proper AES key from the secretKey passed (using SHA256)
    final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
    final key = encrypt_lib.Key.fromBase64(base64Encode(keyBytes));
    final iv = encrypt_lib.IV
        .fromLength(16); // Random IV ideally, or fixed for deterministic reqs.
    // NOTE: For better security, IV should be random and stored with the ciphertext.
    // Here we use a generated IV and prepending it to the result or using a fixed one if simplistic.
    // Let's use a random IV and start it with the ciphertext.

    final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));
    final encrypted = encrypter.encrypt(vigenereEncrypted, iv: iv);

    // Combine IV and CipherText for storage: iv:ciphertext
    return "${iv.base64}:${encrypted.base64}";
  }

  static String decryptData(String encryptedData, String secretKey) {
    if (encryptedData.isEmpty) return "";

    try {
      // Split IV and Ciphertext
      final parts = encryptedData.split(':');
      if (parts.length != 2) return "Invalid format";

      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final cipherText = parts[1];

      // Layer 2 Decryption: Modern - AES-256
      final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
      final key = encrypt_lib.Key.fromBase64(base64Encode(keyBytes));

      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));
      final decryptedModern = encrypter.decrypt64(cipherText, iv: iv);

      // Layer 1 Decryption: Classic - Vigenère Cipher
      return _vigenereDecrypt(decryptedModern, secretKey);
    } catch (e) {
      // print("Decryption error: $e");
      return "Decryption Failed";
    }
  }

  // --- Classic Verification Implementation (Vigenère) ---

  static String _vigenereEncrypt(String input, String key) {
    StringBuffer result = StringBuffer();
    int keyIndex = 0;
    int alphabetLen = _vigenereAlphabet.length;

    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      int charIndex = _vigenereAlphabet.indexOf(char);

      if (charIndex != -1) {
        int keyCharIndex =
            _vigenereAlphabet.indexOf(key[keyIndex % key.length]);
        int newIndex = (charIndex + keyCharIndex) % alphabetLen;
        result.write(_vigenereAlphabet[newIndex]);
        keyIndex++;
      } else {
        // If char is not in our alphabet, keep it as is
        result.write(char);
      }
    }
    return result.toString();
  }

  static String _vigenereDecrypt(String input, String key) {
    StringBuffer result = StringBuffer();
    int keyIndex = 0;
    int alphabetLen = _vigenereAlphabet.length;

    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      int charIndex = _vigenereAlphabet.indexOf(char);

      if (charIndex != -1) {
        int keyCharIndex =
            _vigenereAlphabet.indexOf(key[keyIndex % key.length]);
        int newIndex = (charIndex - keyCharIndex + alphabetLen) % alphabetLen;
        result.write(_vigenereAlphabet[newIndex]);
        keyIndex++;
      } else {
        result.write(char);
      }
    }
    return result.toString();
  }
}
