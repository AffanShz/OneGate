class Note {
  final String id;
  final String title;
  final String encryptedContent;
  final DateTime timestamp;
  final bool isAes; // true = AES, false = Modified Playfair

  Note({
    required this.id,
    required this.title,
    required this.encryptedContent,
    required this.timestamp,
    required this.isAes,
  });

  // Mock data for demo
  static List<Note> mockNotes = [
    Note(
      id: '1',
      title: 'Project X - Phase 2',
      encryptedContent: 'U2FsdGVkX1+...', // Mock AES
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isAes: true,
    ),
    Note(
      id: '2',
      title: 'Secret Journal',
      encryptedContent: 'OLLEH DLROW', // Mock Playfair
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isAes: false,
    ),
  ];
}
