import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String secretKey;
  const HomeScreen({Key? key, required this.secretKey}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  List<Note> notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    // Key is now guaranteed from the widget
    setState(() => _isLoading = true);
    try {
      final data = await _storageService.fetchNotes();
      final loadedNotes = data.map((e) => Note.fromMap(e)).toList();

      for (var note in loadedNotes) {
        // New encryption format: use encryptedContent directly (no IV:CipherText)
        String decrypted = EncryptionService.decryptData(
            note.encryptedContent, widget.secretKey);

        if (decrypted == "Decryption Failed" || decrypted.isEmpty) {
          note.decryptedTitle = "Locked Note";
          note.decryptedContent = "Could not decrypt.";
        } else {
          final split = decrypted.split('\n\n');
          note.decryptedTitle = split.first;
          note.decryptedContent =
              split.length > 1 ? split.sublist(1).join('\n\n') : "";
        }
      }

      setState(() {
        notes = loadedNotes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching notes: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brightTealBlue.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("OneGate", style: AppTextStyles.display),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _fetchNotes,
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: _logout,
                            child: CircleAvatar(
                              backgroundColor:
                                  AppColors.brightTealBlue.withOpacity(0.2),
                              child: Icon(
                                Icons.logout,
                                color: AppColors.brightTealBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Your Secure Notes",
                    style: AppTextStyles.heading,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : notes.isEmpty
                          ? const Center(child: Text("No notes found."))
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: notes.length,
                              separatorBuilder: (c, i) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                return GlassCard(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NoteDetailScreen(
                                          note: note,
                                          secretKey: widget.secretKey,
                                        ),
                                      ),
                                    );
                                    _fetchNotes();
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.brightTealBlue
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          color: AppColors.brightTealBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note.decryptedTitle ??
                                                  "Encrypted",
                                              style: AppTextStyles.heading
                                                  .copyWith(
                                                fontSize: 18,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')} - ${note.createdAt.day}/${note.createdAt.month}",
                                              style: AppTextStyles.label,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brightTealBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddNoteScreen(secretKey: widget.secretKey)),
          );
          _fetchNotes();
        },
      ),
    );
  }
}
