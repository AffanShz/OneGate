import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../widgets/glass_card.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final String secretKey; // Need key for image decryption

  const NoteDetailScreen(
      {Key? key, required this.note, required this.secretKey})
      : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  // Default to FALSE (Show Encrypted/Ciphertext by default)
  bool _showDecrypted = false;
  Uint8List? _decryptedImage;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadAttachment();
  }

  Future<void> _loadAttachment() async {
    final meta = widget.note.cipherMeta;
    if (meta != null && meta['attachment'] != null) {
      final attachment = meta['attachment'];
      if (attachment['type'] == 'image' && attachment['path'] != null) {
        setState(() => _isLoadingImage = true);
        try {
          // Download encrypted bytes
          final encryptedBytes =
              await StorageService().downloadAttachment(attachment['path']);

          // Decrypt bytes
          final decryptedBytes =
              EncryptionService.decryptBinary(encryptedBytes, widget.secretKey);

          if (mounted) {
            setState(() {
              _decryptedImage = decryptedBytes;
            });
          }
        } catch (e) {
          print("Error loading attachment: $e");
        } finally {
          if (mounted) setState(() => _isLoadingImage = false);
        }
      }
    }
  }

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
              // If Decrypted is shown, button is to Hide (Off)
              // If Encrypted is shown, button is to Show (On)
              _showDecrypted ? Icons.visibility_off : Icons.visibility,
              color: AppColors.brightTealBlue,
            ),
            onPressed: () {
              setState(() {
                _showDecrypted = !_showDecrypted;
              });
            },
            tooltip: _showDecrypted ? "Hide Content" : "Show Content",
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

                // Content Card
                GlassCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_showDecrypted) ...[
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

                const SizedBox(height: 24),

                // Attachment Section
                if (_isLoadingImage)
                  const Center(child: CircularProgressIndicator())
                else if (_decryptedImage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Attachment", style: AppTextStyles.heading),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _decryptedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
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
                  "Secured with Modified Super Encryption:\nAutokey (Classic) + Rail Fence (Classic) + AES-GCM (Modern)",
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
