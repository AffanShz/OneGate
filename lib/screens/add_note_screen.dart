import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../widgets/glass_text_field.dart';

class AddNoteScreen extends StatefulWidget {
  final String secretKey;
  const AddNoteScreen({Key? key, required this.secretKey}) : super(key: key);

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullText = "${_titleController.text}\n\n${_contentController.text}";
      final encryptedData =
          EncryptionService.encryptData(fullText, widget.secretKey);

      await _storageService.createNote(
        combinedEncryptedData: encryptedData,
        hmac: "hmac-placeholder",
        cipherMeta: {"algo": "vigenere+aes"},
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        title: const Text("New Note"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator())
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GlassTextField(
              controller: _titleController,
              hintText: "Title",
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _contentController,
              hintText: "Write something secure...",
              maxLines: 10,
            ),
          ],
        ),
      ),
    );
  }
}
