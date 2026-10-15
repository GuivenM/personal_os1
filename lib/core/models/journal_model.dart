import '../utils/json_parsing.dart';

/// GET /journal — today's (or a given date's) entry.
class JournalEntry {
  const JournalEntry({
    required this.entryDate,
    required this.content,
    required this.exists,
  });

  final String entryDate;
  final String? content;
  final bool exists;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      entryDate: json['entry_date'] as String? ?? '',
      content: json['content'] as String?,
      exists: json['exists'] as bool? ?? false,
    );
  }
}

/// One entry inside GET /journal/history
class JournalHistoryItem {
  const JournalHistoryItem({
    required this.date,
    required this.charCount,
    required this.preview,
  });

  final String date;
  final int charCount;
  final String preview;

  factory JournalHistoryItem.fromJson(Map<String, dynamic> json) {
    return JournalHistoryItem(
      date: json['date'] as String? ?? '',
      charCount: asInt(json['char_count']),
      preview: json['preview'] as String? ?? '',
    );
  }
}
