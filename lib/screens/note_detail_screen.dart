import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/crypto_utils.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool _showRaw = false;
  String? _decryptedContent;
  String _integrityHash = "";

  @override
  void initState() {
    super.initState();
    _decrypt();
    _calculateHash();
  }

  void _decrypt() {
    if (widget.note.isAes) {
      _decryptedContent = CryptoUtils.decryptAES(widget.note.encryptedContent);
    } else {
      // Classic
      _decryptedContent = CryptoUtils.classicModifiedPlayfair(
        widget.note.encryptedContent,
      ); // Reversible for demo
    }
  }

  void _calculateHash() {
    _integrityHash = CryptoUtils.generateSha256(widget.note.encryptedContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.shadowGrey),
        title: Text("Note Detail", style: AppTextStyles.heading),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.rosewood.withOpacity(0.1),
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
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.rosewood.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security,
                              color: AppColors.rosewood,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.note.title,
                              style: AppTextStyles.heading,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 200),
                        child: Text(
                          _showRaw
                              ? widget.note.encryptedContent
                              : (_decryptedContent ?? ""),
                          style: _showRaw
                              ? GoogleFonts.firaCode(
                                  fontSize: 14,
                                  color: AppColors.shadowGrey,
                                )
                              : AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                GlassButton(
                  text: _showRaw ? "Show Decrypted" : "Show Raw Ciphertext",
                  isPrimary: false,
                  onPressed: () => setState(() => _showRaw = !_showRaw),
                ),

                const SizedBox(height: 16),

                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 20,
                            color: AppColors.brightTealBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Integrity Check (SHA-256)",
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.brightTealBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _integrityHash,
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: AppColors.shadowGrey.withOpacity(0.7),
                        ),
                      ),
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
}
