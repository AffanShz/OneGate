import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'user_pin';

  /// Save the PIN securely
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Check if a PIN is already set
  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  /// Verify if the entered PIN matches the stored PIN
  static Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == enteredPin;
  }

  /// Remove PIN (e.g. on logout or reset)
  static Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
  }
}
