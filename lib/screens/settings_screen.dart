import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../models/note.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  bool _isProcessing = false;

  Future<void> _showChangePinDialog() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Change Encryption PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Warning: This will re-encrypt ALL your notes. It may take a moment.",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: oldPinController,
              decoration: const InputDecoration(
                labelText: "Old PIN",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(
                labelText: "New PIN",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (oldPinController.text.isEmpty ||
                  newPinController.text.isEmpty) {
                return;
              }
              Navigator.pop(context); // Close dialog
              await _changePin(oldPinController.text, newPinController.text);
            },
            child: const Text("Change PIN"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePin(String oldPin, String newPin) async {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Re-encrypting notes... Please wait.")),
    );

    try {
      // 1. Fetch all notes
      final data = await _storageService.fetchNotes();
      final notes = data.map((e) => Note.fromMap(e)).toList();
      int successCount = 0;

      // 2. Process each note
      for (var note in notes) {
        String combined = "${note.iv}:${note.encryptedContent}";

        // A. Decrypt with OLD PIN
        String decrypted = EncryptionService.decryptData(combined, oldPin);

        if (decrypted == "Decryption Failed" || decrypted.isEmpty) {
          // Skip or error? If we can't decrypt, we can't re-encrypt safely without data loss.
          // For now, we skip and warn.
          print("Could not decrypt note ${note.id}");
          continue;
        }

        // B. Encrypt with NEW PIN
        String newEncryptedData =
            EncryptionService.encryptData(decrypted, newPin);

        // C. Update in DB
        await _storageService.updateNote(
          noteId: note.id,
          combinedEncryptedData: newEncryptedData,
          hmac: "re-encrypted", // simplified
          cipherMeta: {"algo": "vigenere+aes", "rotated": true},
        );
        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! Re-encrypted $successCount notes.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.shadowGrey),
        title: Text("Settings", style: AppTextStyles.heading),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ACCOUNT SECURITY", style: AppTextStyles.label),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Change Encryption PIN",
                          style: AppTextStyles.body,
                        ),
                        subtitle: const Text("Re-encrypts all data"),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.shadowGrey,
                        ),
                        onTap: _isProcessing ? null : _showChangePinDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 40,
                        color: AppColors.brightTealBlue,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CRYPTO EXPLANATION",
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Learn about how your data is protected with advanced encryption techniques. Your keys remain on your device.",
                              style: AppTextStyles.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : GlassButton(
                        text: "LOGOUT",
                        isPrimary: false,
                        onPressed: () async {
                          await AuthService().signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                const SizedBox(height: 32),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ACADEMIC INFO", style: AppTextStyles.label),
                      const SizedBox(height: 16),
                      _buildInfoBullet("Classic + Modern Cryptography"),
                      const SizedBox(height: 8),
                      _buildInfoBullet("Client-side Encryption"),
                      const SizedBox(height: 8),
                      _buildInfoBullet("Flutter Liquid Glass UI"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brightTealBlue,
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.body),
      ],
    );
  }
}
