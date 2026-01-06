import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/crypto_utils.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/glass_button.dart';
import '../models/note.dart';
import 'package:uuid/uuid.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({Key? key}) : super(key: key);

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAes = true;

  void _saveNote() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final rawContent = _contentController.text;
    final encrypted = _isAes
        ? CryptoUtils.encryptAES(rawContent)
        : CryptoUtils.classicModifiedPlayfair(rawContent);

    final newNote = Note(
      id: const Uuid()
          .v4(), // Uuid package not added, let's just use DateTime for now or random
      title: _titleController.text,
      encryptedContent: encrypted,
      timestamp: DateTime.now(),
      isAes: _isAes,
    );

    Navigator.pop(context, newNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.shadowGrey),
        title: Text("Add Note", style: AppTextStyles.heading),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brightTealBlue.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassTextField(hintText: "Title", controller: _titleController),
                const SizedBox(height: 16),
                GlassTextField(
                  hintText: "Write your secure note...",
                  controller: _contentController,
                  maxLines: 8,
                ),
                const SizedBox(height: 24),

                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCipherOption("Modern (AES-256)", true),
                      _buildCipherOption("Classic (Playfair)", false),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                GlassButton(text: "Encrypt & Save", onPressed: _saveNote),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Data encrypted client-side before save",
                    style: AppTextStyles.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCipherOption(String label, bool isAesOption) {
    final isSelected = _isAes == isAesOption;
    return GestureDetector(
      onTap: () => setState(() => _isAes = isAesOption),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brightTealBlue.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.brightTealBlue)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              isAesOption ? Icons.memory : Icons.lock_clock,
              color: isSelected
                  ? AppColors.brightTealBlue
                  : AppColors.shadowGrey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected
                    ? AppColors.brightTealBlue
                    : AppColors.shadowGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
