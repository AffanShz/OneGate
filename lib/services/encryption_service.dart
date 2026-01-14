import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

class EncryptionService {
  // ============================================================
  // LAYER 1: MODIFIED TRANSPOSITION CIPHER
  // ============================================================
  // Modification: Key-based columnar transposition with:
  // - Dynamic column count derived from key hash
  // - Column order shuffled based on key
  // - Row permutation as secondary scrambling

  /// Get column count from key (between 4-12)
  static int _getColumnCount(String key) {
    var bytes = sha256.convert(utf8.encode(key)).bytes;
    return (bytes[0] % 9) + 4; // 4-12 columns
  }

  /// Generate column order permutation from key
  static List<int> _getColumnOrder(String key, int columnCount) {
    var bytes = sha256.convert(utf8.encode(key + "col")).bytes;
    List<int> indices = List.generate(columnCount, (i) => i);

    // Fisher-Yates shuffle using key bytes
    for (int i = columnCount - 1; i > 0; i--) {
      int j = bytes[i % bytes.length] % (i + 1);
      int temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }
    return indices;
  }

  /// Modified Transposition Cipher - Encrypt
  static String _modifiedTranspositionEncrypt(String plaintext, String key) {
    if (plaintext.isEmpty) return "";

    int columns = _getColumnCount(key);
    List<int> columnOrder = _getColumnOrder(key, columns);

    // Add length header for padding removal (4 digits)
    String lengthHeader = plaintext.length.toString().padLeft(4, '0');
    String textWithHeader = lengthHeader + plaintext;

    // Pad to multiple of column count
    int paddingNeeded = (columns - (textWithHeader.length % columns)) % columns;
    var hashBytes = sha256.convert(utf8.encode(key + "pad")).bytes;
    String paddingChars = "";
    for (int i = 0; i < paddingNeeded; i++) {
      paddingChars +=
          String.fromCharCode(65 + (hashBytes[i % hashBytes.length] % 26));
    }
    String padded = textWithHeader + paddingChars;

    // Write into matrix row by row
    int rows = padded.length ~/ columns;
    List<List<String>> matrix = List.generate(rows, (r) {
      return List.generate(columns, (c) => padded[r * columns + c]);
    });

    // Read columns in shuffled order
    StringBuffer result = StringBuffer();
    for (int colIdx in columnOrder) {
      for (int r = 0; r < rows; r++) {
        result.write(matrix[r][colIdx]);
      }
    }

    return result.toString();
  }

  /// Modified Transposition Cipher - Decrypt
  static String _modifiedTranspositionDecrypt(String ciphertext, String key) {
    if (ciphertext.isEmpty) return "";

    int columns = _getColumnCount(key);
    List<int> columnOrder = _getColumnOrder(key, columns);
    int rows = ciphertext.length ~/ columns;

    if (rows == 0) return "";

    // Create inverse column order mapping
    List<int> inverseOrder = List.filled(columns, 0);
    for (int i = 0; i < columns; i++) {
      inverseOrder[columnOrder[i]] = i;
    }

    // Read cipher into columns (in shuffled order)
    List<List<String>> matrix =
        List.generate(rows, (_) => List.filled(columns, ''));
    int idx = 0;
    for (int colIdx in columnOrder) {
      for (int r = 0; r < rows; r++) {
        matrix[r][colIdx] = ciphertext[idx++];
      }
    }

    // Read matrix row by row
    StringBuffer result = StringBuffer();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        result.write(matrix[r][c]);
      }
    }

    String withHeader = result.toString();

    // Extract length header and remove padding
    if (withHeader.length < 4) return withHeader;
    int originalLength = int.tryParse(withHeader.substring(0, 4)) ?? 0;
    if (originalLength > 0 && originalLength + 4 <= withHeader.length) {
      return withHeader.substring(4, 4 + originalLength);
    }
    return withHeader.substring(4);
  }

  // ============================================================
  // LAYER 2: MODIFIED RSA (Simplified for Educational Purposes)
  // ============================================================
  // Uses smaller primes derived from key for demonstration
  // Real RSA should use 2048+ bit keys

  /// Generate RSA parameters from key
  static Map<String, BigInt> _generateRSAParams(String key) {
    var bytes = sha256.convert(utf8.encode(key + "rsa")).bytes;

    // Use predefined small primes for demo (derived from key hash)
    // In production, use cryptographically secure large primes
    List<int> primes = [
      251,
      257,
      263,
      269,
      271,
      277,
      281,
      283,
      293,
      307,
      311,
      313,
      317,
      331,
      337,
      347,
      349,
      353,
      359,
      367,
      373,
      379,
      383,
      389,
      397,
      401,
      409,
      419,
      421,
      431
    ];

    int pIdx = bytes[0] % primes.length;
    int qIdx = (bytes[1] % (primes.length - 1));
    if (qIdx >= pIdx) qIdx++;

    BigInt p = BigInt.from(primes[pIdx]);
    BigInt q = BigInt.from(primes[qIdx]);
    BigInt n = p * q;
    BigInt phi = (p - BigInt.one) * (q - BigInt.one);
    BigInt e = BigInt.from(65537);

    // Ensure e is coprime with phi
    if (e >= phi || phi.gcd(e) != BigInt.one) {
      e = BigInt.from(17);
    }

    // Calculate d (modular multiplicative inverse)
    BigInt d = e.modInverse(phi);

    return {'n': n, 'e': e, 'd': d, 'p': p, 'q': q};
  }

  /// RSA Encrypt a single integer
  static BigInt _rsaEncryptInt(BigInt m, BigInt e, BigInt n) {
    return m.modPow(e, n);
  }

  /// RSA Decrypt a single integer
  static BigInt _rsaDecryptInt(BigInt c, BigInt d, BigInt n) {
    return c.modPow(d, n);
  }

  /// Modified RSA - Encrypt bytes
  static String _modifiedRSAEncrypt(String input, String key) {
    if (input.isEmpty) return "";

    var params = _generateRSAParams(key);
    BigInt n = params['n']!;
    BigInt e = params['e']!;

    // Encrypt each byte individually (block size = 1 byte for demo)
    List<String> encryptedBlocks = [];
    for (int i = 0; i < input.length; i++) {
      int charCode = input.codeUnitAt(i);
      BigInt m = BigInt.from(charCode);
      BigInt c = _rsaEncryptInt(m, e, n);
      encryptedBlocks.add(c.toString());
    }

    return encryptedBlocks.join(',');
  }

  /// Modified RSA - Decrypt
  static String _modifiedRSADecrypt(String encrypted, String key) {
    if (encrypted.isEmpty) return "";

    var params = _generateRSAParams(key);
    BigInt n = params['n']!;
    BigInt d = params['d']!;

    List<String> blocks = encrypted.split(',');
    StringBuffer result = StringBuffer();

    for (String block in blocks) {
      if (block.isEmpty) continue;
      BigInt c = BigInt.tryParse(block) ?? BigInt.zero;
      BigInt m = _rsaDecryptInt(c, d, n);
      result.write(String.fromCharCode(m.toInt()));
    }

    return result.toString();
  }

  // ============================================================
  // SUPER ENCRYPTION: Combined Layers
  // ============================================================

  /// Encrypt text data using Modified Transposition + Modified RSA
  static String encryptData(String plainText, String secretKey) {
    if (plainText.isEmpty) return "";

    try {
      // Layer 1: Modified Transposition Cipher
      String layer1 = _modifiedTranspositionEncrypt(plainText, secretKey);

      // Layer 2: Modified RSA
      String layer2 = _modifiedRSAEncrypt(layer1, secretKey);

      // Encode as Base64 for safe storage
      return base64Encode(utf8.encode(layer2));
    } catch (e) {
      print("Encryption Error: $e");
      return "";
    }
  }

  /// Decrypt text data
  static String decryptData(String encryptedData, String secretKey) {
    if (encryptedData.isEmpty) return "";

    try {
      // Decode Base64
      String layer2 = utf8.decode(base64Decode(encryptedData));

      // Decrypt Layer 2: Modified RSA
      String layer1 = _modifiedRSADecrypt(layer2, secretKey);

      // Decrypt Layer 1: Modified Transposition
      return _modifiedTranspositionDecrypt(layer1, secretKey);
    } catch (e) {
      print("Decryption Error: $e");
      return "Decryption Failed";
    }
  }

  // ============================================================
  // IMAGE ENCRYPTION (Pixel Shuffling - Preserves Image Format)
  // Using 'image' package for reliable cross-platform support
  // ============================================================

  /// Encrypt image - output is still a valid image with scrambled pixels
  /// Uses XOR on pixel values to scramble colors
  /// Input: Raw image bytes (PNG/JPEG)
  /// Output: Encrypted PNG bytes (scrambled but valid image)
  static Future<Uint8List> encryptImage(
      Uint8List imageBytes, String secretKey) async {
    if (imageBytes.isEmpty) return Uint8List(0);

    try {
      // Decode image using image package
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return Uint8List(0);

      int width = image.width;
      int height = image.height;

      // Generate key stream for XOR
      var keyBytes = sha256.convert(utf8.encode(secretKey + "imgkey")).bytes;

      // Create new image with scrambled pixels
      img.Image encryptedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          img.Pixel pixel = image.getPixel(x, y);

          // Get pixel color components
          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          int a = pixel.a.toInt();

          // XOR RGB with key-derived values (keep alpha intact)
          int idx = (y * width + x) * 3;
          int newR = r ^ keyBytes[idx % keyBytes.length];
          int newG = g ^ keyBytes[(idx + 1) % keyBytes.length];
          int newB = b ^ keyBytes[(idx + 2) % keyBytes.length];

          // Set scrambled pixel
          encryptedImage.setPixelRgba(x, y, newR, newG, newB, a);
        }
      }

      // Encode back to PNG
      Uint8List result = Uint8List.fromList(img.encodePng(encryptedImage));
      return result;
    } catch (e) {
      print("Image Encryption Error: $e");
      return Uint8List(0);
    }
  }

  /// Decrypt image - restore original from scrambled image
  static Future<Uint8List> decryptImage(
      Uint8List encryptedBytes, String secretKey) async {
    if (encryptedBytes.isEmpty) return Uint8List(0);

    try {
      // Decode encrypted image
      img.Image? image = img.decodeImage(encryptedBytes);
      if (image == null) return Uint8List(0);

      int width = image.width;
      int height = image.height;

      // Generate same key stream
      var keyBytes = sha256.convert(utf8.encode(secretKey + "imgkey")).bytes;

      // Create decrypted image
      img.Image decryptedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          img.Pixel pixel = image.getPixel(x, y);

          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          int a = pixel.a.toInt();

          // XOR again to reverse (XOR is symmetric)
          int idx = (y * width + x) * 3;
          int origR = r ^ keyBytes[idx % keyBytes.length];
          int origG = g ^ keyBytes[(idx + 1) % keyBytes.length];
          int origB = b ^ keyBytes[(idx + 2) % keyBytes.length];

          decryptedImage.setPixelRgba(x, y, origR, origG, origB, a);
        }
      }

      // Encode back to PNG
      Uint8List result = Uint8List.fromList(img.encodePng(decryptedImage));
      return result;
    } catch (e) {
      print("Image Decryption Error: $e");
      return Uint8List(0);
    }
  }

  // ============================================================
  // LEGACY BINARY ENCRYPTION (For Non-Image Files)
  // ============================================================

  /// Encrypt binary data using XOR with key-derived stream
  static Uint8List encryptBinary(Uint8List data, String secretKey) {
    if (data.isEmpty) return Uint8List(0);

    // Generate key stream
    var keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
    Uint8List result = Uint8List(data.length);

    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }

    return result;
  }

  /// Decrypt binary data (XOR is symmetric)
  static Uint8List decryptBinary(Uint8List data, String secretKey) {
    return encryptBinary(data, secretKey); // XOR is symmetric
  }
}
