import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/glass_button.dart';

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
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Content are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Siapkan Konten Catatan
      final fullText = "${_titleController.text}\n\n${_contentController.text}";

      // 2. Enkripsi Konten Teks (Logika yang Ada)
      final encryptedData =
          EncryptionService.encryptData(fullText, widget.secretKey);

      // 3. Enkripsi & Unggah Lampiran (Jika ada)
      Map<String, dynamic> cipherMeta = {
        'layer1': 'Modified Transposition Cipher',
        'layer2': 'Modified RSA',
        'attachment': null,
      };

      if (_selectedImage != null) {
        // Baca byte file
        final imageBytes = await _selectedImage!.readAsBytes();

        // Enkripsi gambar menggunakan pengacakan piksel (mempertahankan format gambar)
        final encryptedImage =
            await EncryptionService.encryptImage(imageBytes, widget.secretKey);

        // Dapatkan ID Pengguna untuk jalur penyimpanan
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Unggah (menggunakan ID sementara untuk nama file)
        final tempId = DateTime.now().toIso8601String();

        final path = await _storageService.uploadAttachment(
            userId, tempId, encryptedImage);

        // Perbarui meta
        cipherMeta['attachment'] = {
          'type': 'image',
          'path': path,
          'encrypted': true,
          'algorithm': 'Pixel Shuffling + XOR'
        };
      }

      // 4. Buat Rekaman Catatan
      await _storageService.createNote(
        combinedEncryptedData: encryptedData,
        hmac: "HMAC-SHA256", // Placeholder untuk saat ini
        cipherMeta: cipherMeta,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        title: Text("Add Secure Note", style: AppTextStyles.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.shadowGrey),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GlassTextField(hintText: "Title", controller: _titleController),
            const SizedBox(height: 16),
            GlassTextField(
              hintText: "Secret Content...",
              controller: _contentController,
              maxLines: 10,
            ),
            const SizedBox(height: 16),

            // Attachment Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.brightTealBlue.withOpacity(0.3)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: AppColors.brightTealBlue),
                          const SizedBox(height: 8),
                          Text("Attach Image (Encrypted)",
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.brightTealBlue)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : GlassButton(text: "Encrypt & Save", onPressed: _saveNote),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "Encryption: Modified Transposition + Modified RSA\nAttachments: Pixel Shuffling + XOR",
                textAlign: TextAlign.center,
                style: AppTextStyles.label
                    .copyWith(fontSize: 10, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}
