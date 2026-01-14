import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

class EncryptionService {
  // ============================================================
  // ============================================================
  // LAYER 1: MODIFIED TRANSPOSITION CIPHER (CIPHER TRANSPOSISI TERMODIFIKASI)
  // ============================================================
  // Modifikasi: Transposisi kolom berbasis kunci dengan:
  // - Jumlah kolom dinamis yang diturunkan dari hash kunci
  // - Urutan kolom diacak berdasarkan kunci
  // - Permutasi baris sebagai pengacakan sekunder

  /// Dapatkan jumlah kolom dari kunci (antara 4-12)
  static int _getColumnCount(String key) {
    var bytes = sha256.convert(utf8.encode(key)).bytes;
    return (bytes[0] % 9) + 4; // 4-12 columns
  }

  /// Hasilkan permutasi urutan kolom dari kunci
  static List<int> _getColumnOrder(String key, int columnCount) {
    var bytes = sha256.convert(utf8.encode(key + "col")).bytes;
    List<int> indices = List.generate(columnCount, (i) => i);

    // Pengacakan Fisher-Yates menggunakan byte kunci
    for (int i = columnCount - 1; i > 0; i--) {
      int j = bytes[i % bytes.length] % (i + 1);
      int temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }
    return indices;
  }

  /// Modified Transposition Cipher - Enkripsi
  static String _modifiedTranspositionEncrypt(String plaintext, String key) {
    if (plaintext.isEmpty) return "";

    int columns = _getColumnCount(key);
    List<int> columnOrder = _getColumnOrder(key, columns);

    // Tambahkan header panjang untuk penghapusan padding (4 digit)
    String lengthHeader = plaintext.length.toString().padLeft(4, '0');
    String textWithHeader = lengthHeader + plaintext;

    // Pad ke kelipatan jumlah kolom
    int paddingNeeded = (columns - (textWithHeader.length % columns)) % columns;
    var hashBytes = sha256.convert(utf8.encode(key + "pad")).bytes;
    String paddingChars = "";
    for (int i = 0; i < paddingNeeded; i++) {
      paddingChars +=
          String.fromCharCode(65 + (hashBytes[i % hashBytes.length] % 26));
    }
    String padded = textWithHeader + paddingChars;

    // Tulis ke dalam matriks baris demi baris
    int rows = padded.length ~/ columns;
    List<List<String>> matrix = List.generate(rows, (r) {
      return List.generate(columns, (c) => padded[r * columns + c]);
    });

    // Baca kolom dalam urutan acak
    StringBuffer result = StringBuffer();
    for (int colIdx in columnOrder) {
      for (int r = 0; r < rows; r++) {
        result.write(matrix[r][colIdx]);
      }
    }

    return result.toString();
  }

  /// Modified Transposition Cipher - Dekripsi
  static String _modifiedTranspositionDecrypt(String ciphertext, String key) {
    if (ciphertext.isEmpty) return "";

    int columns = _getColumnCount(key);
    List<int> columnOrder = _getColumnOrder(key, columns);
    int rows = ciphertext.length ~/ columns;

    if (rows == 0) return "";

    // Buat pemetaan urutan kolom invers
    List<int> inverseOrder = List.filled(columns, 0);
    for (int i = 0; i < columns; i++) {
      inverseOrder[columnOrder[i]] = i;
    }

    // Baca cipher ke dalam kolom (dalam urutan acak)
    List<List<String>> matrix =
        List.generate(rows, (_) => List.filled(columns, ''));
    int idx = 0;
    for (int colIdx in columnOrder) {
      for (int r = 0; r < rows; r++) {
        matrix[r][colIdx] = ciphertext[idx++];
      }
    }

    // Baca matriks baris demi baris
    StringBuffer result = StringBuffer();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        result.write(matrix[r][c]);
      }
    }

    String withHeader = result.toString();

    // Ekstrak header panjang dan hapus padding
    if (withHeader.length < 4) return withHeader;
    int originalLength = int.tryParse(withHeader.substring(0, 4)) ?? 0;
    if (originalLength > 0 && originalLength + 4 <= withHeader.length) {
      return withHeader.substring(4, 4 + originalLength);
    }
    return withHeader.substring(4);
  }

  // ============================================================
  // LAYER 2: MODIFIED RSA (Disederhanakan untuk Tujuan Edukasi)
  // ============================================================
  // Menggunakan bilangan prima lebih kecil yang diturunkan dari kunci untuk demonstrasi
  // RSA asli harus menggunakan kunci 2048+ bit
  // ============================================================

  /// Hasilkan parameter RSA dari kunci
  static Map<String, BigInt> _generateRSAParams(String key) {
    var bytes = sha256.convert(utf8.encode(key + "rsa")).bytes;

    // Gunakan bilangan prima kecil yang telah ditentukan untuk demo (diturunkan dari hash kunci)
    // Dalam produksi, gunakan bilangan prima besar yang aman secara kriptografi
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

    // Pastikan e relatif prima dengan phi
    if (e >= phi || phi.gcd(e) != BigInt.one) {
      e = BigInt.from(17);
    }

    // Hitung d (invers perkalian modular)
    BigInt d = e.modInverse(phi);

    return {'n': n, 'e': e, 'd': d, 'p': p, 'q': q};
  }

  /// RSA Enkripsi satu integer
  static BigInt _rsaEncryptInt(BigInt m, BigInt e, BigInt n) {
    return m.modPow(e, n);
  }

  /// RSA Dekripsi satu integer
  static BigInt _rsaDecryptInt(BigInt c, BigInt d, BigInt n) {
    return c.modPow(d, n);
  }

  /// Modified RSA - Enkripsi byte
  static String _modifiedRSAEncrypt(String input, String key) {
    if (input.isEmpty) return "";

    var params = _generateRSAParams(key);
    BigInt n = params['n']!;
    BigInt e = params['e']!;

    // Enkripsi setiap byte secara individual (ukuran blok = 1 byte untuk demo)
    List<String> encryptedBlocks = [];
    for (int i = 0; i < input.length; i++) {
      int charCode = input.codeUnitAt(i);
      BigInt m = BigInt.from(charCode);
      BigInt c = _rsaEncryptInt(m, e, n);
      encryptedBlocks.add(c.toString());
    }

    return encryptedBlocks.join(',');
  }

  /// Modified RSA - Dekripsi
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
  // SUPER ENCRYPTION: Gabungan Layer
  // ============================================================

  /// Enkripsi data teks menggunakan Modified Transposition + Modified RSA
  static String encryptData(String plainText, String secretKey) {
    if (plainText.isEmpty) return "";

    try {
      // Layer 1: Modified Transposition Cipher
      String layer1 = _modifiedTranspositionEncrypt(plainText, secretKey);

      // Layer 2: Modified RSA
      String layer2 = _modifiedRSAEncrypt(layer1, secretKey);

      // Encode sebagai Base64 untuk penyimpanan aman
      return base64Encode(utf8.encode(layer2));
    } catch (e) {
      print("Encryption Error: $e");
      return "";
    }
  }

  /// Dekripsi data teks
  static String decryptData(String encryptedData, String secretKey) {
    if (encryptedData.isEmpty) return "";

    try {
      // Decode Base64
      String layer2 = utf8.decode(base64Decode(encryptedData));

      // Dekripsi Layer 2: Modified RSA
      String layer1 = _modifiedRSADecrypt(layer2, secretKey);

      // Dekripsi Layer 1: Modified Transposition
      return _modifiedTranspositionDecrypt(layer1, secretKey);
    } catch (e) {
      print("Decryption Error: $e");
      return "Decryption Failed";
    }
  }

  // ============================================================
  // ENKRIPSI GAMBAR (Pengacakan Pixel - Mempertahankan Format Gambar)
  // Menggunakan paket 'image' untuk dukungan lintas platform yang andal
  // ============================================================

  /// Enkripsi gambar - output tetap gambar valid dengan pixel acak
  /// Menggunakan XOR pada nilai pixel untuk mengacak warna
  /// Input: Byte gambar mentah (PNG/JPEG)
  /// Output: Byte PNG terenkripsi (acak tapi gambar valid)
  static Future<Uint8List> encryptImage(
      Uint8List imageBytes, String secretKey) async {
    if (imageBytes.isEmpty) return Uint8List(0);

    try {
      // Decode gambar menggunakan paket image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return Uint8List(0);

      int width = image.width;
      int height = image.height;

      // Hasilkan stream kunci untuk XOR
      var keyBytes = sha256.convert(utf8.encode(secretKey + "imgkey")).bytes;

      // Buat gambar baru dengan pixel acak
      img.Image encryptedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          img.Pixel pixel = image.getPixel(x, y);

          // Dapatkan komponen warna pixel
          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          int a = pixel.a.toInt();

          // XOR RGB dengan nilai turunan kunci (biarkan alpha utuh)
          int idx = (y * width + x) * 3;
          int newR = r ^ keyBytes[idx % keyBytes.length];
          int newG = g ^ keyBytes[(idx + 1) % keyBytes.length];
          int newB = b ^ keyBytes[(idx + 2) % keyBytes.length];

          // Set pixel acak
          encryptedImage.setPixelRgba(x, y, newR, newG, newB, a);
        }
      }

      // Encode kembali ke PNG
      Uint8List result = Uint8List.fromList(img.encodePng(encryptedImage));
      return result;
    } catch (e) {
      print("Image Encryption Error: $e");
      return Uint8List(0);
    }
  }

  /// Dekripsi gambar - kembalikan asli dari gambar acak
  static Future<Uint8List> decryptImage(
      Uint8List encryptedBytes, String secretKey) async {
    if (encryptedBytes.isEmpty) return Uint8List(0);

    try {
      // Decode gambar terenkripsi
      img.Image? image = img.decodeImage(encryptedBytes);
      if (image == null) return Uint8List(0);

      int width = image.width;
      int height = image.height;

      // Hasilkan stream kunci yang sama
      var keyBytes = sha256.convert(utf8.encode(secretKey + "imgkey")).bytes;

      // Buat gambar terdekripsi
      img.Image decryptedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          img.Pixel pixel = image.getPixel(x, y);

          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          int a = pixel.a.toInt();

          // XOR lagi untuk membalikkan (XOR bersifat simetris)
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
  // ENKRIPSI BINER LEGACY (Untuk File Non-Gambar)
  // ============================================================

  /// Enkripsi data biner menggunakan XOR dengan stream turunan kunci
  static Uint8List encryptBinary(Uint8List data, String secretKey) {
    if (data.isEmpty) return Uint8List(0);

    // Hasilkan stream kunci
    var keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
    Uint8List result = Uint8List(data.length);

    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }

    return result;
  }

  /// Dekripsi data biner (XOR bersifat simetris)
  static Uint8List decryptBinary(Uint8List data, String secretKey) {
    return encryptBinary(data, secretKey); // XOR bersifat simetris
  }
}
