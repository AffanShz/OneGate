import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'dart:typed_data';

class EncryptionService {
  // Classic Alphabet (100 chars)
  static const String _classicAlphabet =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 !\"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~";

  /// SUPER ENCRYPTION:
  /// 1. Layer 1: Modified Autokey Cipher (Substitution)
  /// 2. Layer 2: Dynamic Rail Fence Cipher (Transposition)
  /// 3. Layer 3: Modern AES-GCM (Authenticated Encryption)
  static String encryptData(String plainText, String secretKey) {
    if (plainText.isEmpty) return "";

    try {
      // 1. Classic Layer 1: Modified Autokey Cipher
      String layer1 = _modifiedAutokeyEncrypt(plainText, secretKey);

      // 2. Classic Layer 2: Dynamic Rail Fence Cipher
      String layer2 = _dynamicRailFenceEncrypt(layer1, secretKey);

      // 3. Modern Layer 3: AES-GCM
      // Derive a 32-byte key (256 bit) from the secretKey
      final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
      final key = encrypt_lib.Key(Uint8List.fromList(keyBytes));

      // Generate a random 12-byte IV (Nonce) standard for GCM
      final iv = encrypt_lib.IV.fromLength(12);

      // Use AES-GCM for authenticated encryption
      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));

      final encrypted = encrypter.encrypt(layer2, iv: iv);

      // Format: IV:Ciphertext (Base64)
      return "${iv.base64}:${encrypted.base64}";
    } catch (e) {
      print("Encryption Error: $e");
      return "";
    }
  }

  static String decryptData(String encryptedData, String secretKey) {
    if (encryptedData.isEmpty) return "";

    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return "Invalid Data";

      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final cipherText = parts[1];

      // 1. Decrypt Layer 3: Modern AES-GCM
      final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
      final key = encrypt_lib.Key(Uint8List.fromList(keyBytes));

      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));

      final decryptedLayer3 = encrypter.decrypt64(cipherText, iv: iv);

      // 2. Decrypt Layer 2: Dynamic Rail Fence Cipher
      String decryptedLayer2 =
          _dynamicRailFenceDecrypt(decryptedLayer3, secretKey);

      // 3. Decrypt Layer 1: Modified Autokey Cipher
      return _modifiedAutokeyDecrypt(decryptedLayer2, secretKey);
    } catch (e) {
      // print("Decryption Error: $e");
      return "Decryption Failed"; // Or return generic error
    }
  }

  // --- Layer 1: Modified Autokey Implementation ---
  // Modification: The key shift evolves based on the *Ciphertext* output of the previous step.
  // This creates a Ciphertext Autokey (CT-AK) dependancy.

  static String _modifiedAutokeyEncrypt(String input, String key) {
    StringBuffer result = StringBuffer();
    int alphabetLen = _classicAlphabet.length;
    int dynamicShift = 0; // The evolving component

    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      int pIdx = _classicAlphabet.indexOf(char);

      if (pIdx != -1) {
        // Base shift from the secret key (repeated)
        int kIdx = _classicAlphabet.indexOf(key[i % key.length]);

        // Total Shift = Base Key + Dynamic Accumulator
        int shift = (kIdx + dynamicShift) % alphabetLen;

        // Encrypt
        int cIdx = (pIdx + shift) % alphabetLen;
        result.write(_classicAlphabet[cIdx]);

        // MODIFICATION: Update dynamicShift with the Resulting Index
        // This links the next encryption to the current ciphertext
        dynamicShift = cIdx;
      } else {
        result.write(char);
        // Do not update dynamicShift for non-alphabet chars
      }
    }
    return result.toString();
  }

  static String _modifiedAutokeyDecrypt(String input, String key) {
    StringBuffer result = StringBuffer();
    int alphabetLen = _classicAlphabet.length;
    int dynamicShift = 0;

    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      int cIdx = _classicAlphabet.indexOf(char);

      if (cIdx != -1) {
        int kIdx = _classicAlphabet.indexOf(key[i % key.length]);

        // Reconstruct Total Shift
        int shift = (kIdx + dynamicShift) % alphabetLen;

        // Decrypt
        int pIdx = (cIdx - shift + alphabetLen) % alphabetLen;
        result.write(_classicAlphabet[pIdx]);

        // UPDATE: dynamicShift must be updated exactly as it was during encryption
        // Encryption set dynamicShift = cIdx (the ciphertext index being produced)
        // So we use cIdx directly.
        dynamicShift = cIdx;
      } else {
        result.write(char);
      }
    }
    return result.toString();
  }

  // --- Layer 2: Dynamic Rail Fence Implementation ---
  // Modification: Number of rails is dynamic based on Key Hash.

  static int _getDynamicRails(String key) {
    // Generate deterministic rail count between 2 and 9
    var bytes = sha256.convert(utf8.encode(key)).bytes;
    // Use first byte
    return (bytes[0] % 8) + 2;
  }

  static String _dynamicRailFenceEncrypt(String text, String key) {
    int rails = _getDynamicRails(key);
    if (rails <= 1) return text;
    if (text.isEmpty) return "";

    List<StringBuffer> railBuffers =
        List.generate(rails, (_) => StringBuffer());
    int currentRail = 0;
    bool goingDown = false;

    for (int i = 0; i < text.length; i++) {
      railBuffers[currentRail].write(text[i]);

      // Reverse direction at edges
      if (currentRail == 0 || currentRail == rails - 1) {
        goingDown = !goingDown;
      }
      currentRail += goingDown ? 1 : -1;
    }

    return railBuffers.map((b) => b.toString()).join();
  }

  static String _dynamicRailFenceDecrypt(String cipher, String key) {
    int rails = _getDynamicRails(key);
    if (rails <= 1) return cipher;
    if (cipher.isEmpty) return "";

    // 1. Map out the pattern to determine length of each rail
    List<int> railLengths = List.filled(rails, 0);
    int currentRail = 0;
    bool goingDown = false;

    // Simulate "placing" chars to count
    for (int i = 0; i < cipher.length; i++) {
      railLengths[currentRail]++;
      if (currentRail == 0 || currentRail == rails - 1) goingDown = !goingDown;
      currentRail += goingDown ? 1 : -1;
    }

    // 2. Reconstruct the rails from the flat ciphertext
    List<String> constructedRails = [];
    int currentIndex = 0;
    for (int len in railLengths) {
      if (currentIndex + len > cipher.length) break; // Safety
      constructedRails.add(cipher.substring(currentIndex, currentIndex + len));
      currentIndex += len;
    }

    // 3. Read off the rails in ZigZag order
    StringBuffer result = StringBuffer();
    currentRail = 0;
    goingDown = false;
    List<int> railIndices = List.filled(rails, 0);

    for (int i = 0; i < cipher.length; i++) {
      // Pop char from the correct rail
      if (currentRail < constructedRails.length &&
          railIndices[currentRail] < constructedRails[currentRail].length) {
        result.write(constructedRails[currentRail][railIndices[currentRail]]);
        railIndices[currentRail]++;
      }

      if (currentRail == 0 || currentRail == rails - 1) goingDown = !goingDown;
      currentRail += goingDown ? 1 : -1;
    }
    return result.toString();
  }
  // --- Binary Encryption (AES-GCM Only) ---
  // We skip classic layers for binary data to prevent corruption and ensure performance.

  static Uint8List encryptBinary(Uint8List data, String secretKey) {
    if (data.isEmpty) return Uint8List(0);

    final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
    final key = encrypt_lib.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt_lib.IV.fromLength(12); // Standard GCM IV

    final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));

    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Return combined IV + Ciphertext for storage
    // IV is always 12 bytes.
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return combined;
  }

  static Uint8List decryptBinary(Uint8List combinedData, String secretKey) {
    if (combinedData.isEmpty) return Uint8List(0);

    try {
      // Extract IV (first 12 bytes)
      final ivBytes = combinedData.sublist(0, 12);
      final cipherBytes = combinedData.sublist(12);

      final iv = encrypt_lib.IV(ivBytes);
      final encrypted = encrypt_lib.Encrypted(cipherBytes);

      final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
      final key = encrypt_lib.Key(Uint8List.fromList(keyBytes));

      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));

      return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: iv));
    } catch (e) {
      print("Binary Decryption Error: $e");
      return Uint8List(0);
    }
  }
}
