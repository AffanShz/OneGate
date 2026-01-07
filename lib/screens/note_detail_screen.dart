import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool _showCiphertext = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        title: const Text("Note Detail"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showCiphertext ? Icons.visibility_off : Icons.visibility,
              color: AppColors.brightTealBlue,
            ),
            onPressed: () {
              setState(() {
                _showCiphertext = !_showCiphertext;
              });
            },
            tooltip: "Toggle Ciphertext View",
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Note?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete")),
                  ],
                ),
              );

              if (confirm == true) {
                await StorageService().deleteNote(widget.note.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.note.decryptedTitle ?? "Unknown Title",
                  style: AppTextStyles.display.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  "${widget.note.createdAt}",
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_showCiphertext) ...[
                          Text("ENCRYPTED DATA (IV:Ciphertext)",
                              style: AppTextStyles.label
                                  .copyWith(color: Colors.redAccent)),
                          const SizedBox(height: 8),
                          SelectableText(
                            "${widget.note.iv}:${widget.note.encryptedContent}",
                            style: AppTextStyles.body
                                .copyWith(fontFamily: 'Courier', fontSize: 12),
                          ),
                        ] else ...[
                          Text(
                            widget.note.decryptedContent ?? "No content",
                            style: AppTextStyles.body,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Algorithm Info Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.porcelain.withOpacity(0.9),
              child: Center(
                child: Text(
                  "Secured with Dual-Layer Encryption:\nVigenère Cipher (Classic) + AES-256 (Modern)",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label
                      .copyWith(fontSize: 10, color: AppColors.shadowGrey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
