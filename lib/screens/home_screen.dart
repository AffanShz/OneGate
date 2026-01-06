import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/glass_card.dart';
import '../models/note.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use local state to show updates for demo
  List<Note> notes = Note.mockNotes;

  void _addNote(Note note) {
    setState(() {
      notes.insert(0, note);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      body: Stack(
        children: [
          // Background Elements
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
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SecureVault", style: AppTextStyles.display),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: AppColors.brightTealBlue.withOpacity(
                            0.2,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppColors.brightTealBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Your Encrypted Notes",
                    style: AppTextStyles.heading,
                  ),
                ),
                const SizedBox(height: 16),

                // Notes List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: notes.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return GlassCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoteDetailScreen(note: note),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.brightTealBlue.withOpacity(
                                  0.1,
                                ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: AppTextStyles.heading.copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${note.timestamp.hour}:${note.timestamp.minute.toString().padLeft(2, '0')} - ${note.timestamp.day}/${note.timestamp.month}",
                                    style: AppTextStyles.label,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.shadowGrey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                note.isAes ? "AES" : "Classic",
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                ),
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
          final newNote = await Navigator.push<Note>(
            context,
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          );
          if (newNote != null) {
            _addNote(newNote);
          }
        },
      ),
    );
  }
}
