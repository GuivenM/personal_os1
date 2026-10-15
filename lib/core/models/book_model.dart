import '../utils/json_parsing.dart';

/// Possible book statuses.
const bookStatuses = ['to_read', 'reading', 'done', 'paused', 'abandoned'];

/// Phases 1→7, in order.
const bookPhaseNames = {
  1: 'Getting unstuck',
  2: 'Understanding people',
  3: 'Building yourself',
  4: 'Understanding systems',
  5: 'Political theory',
  6: 'Advanced strategy',
  7: 'Biographies',
};

String bookStatusLabel(String status) {
  switch (status) {
    case 'to_read':
      return 'To read';
    case 'reading':
      return 'Reading';
    case 'done':
      return 'Done';
    case 'paused':
      return 'Paused';
    case 'abandoned':
      return 'Abandoned';
    default:
      return status;
  }
}

/// GET /books list item
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.phase,
    required this.status,
    required this.rating,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.quotesCount,
  });

  final int id;
  final String title;
  final String author;
  final int phase;
  final String status;
  final int? rating;
  final String? startDate;
  final String? endDate;
  final String? summary;
  final int quotesCount;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: asInt(json['id']),
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      phase: asInt(json['phase'], 1),
      status: json['status'] as String? ?? 'to_read',
      rating: asIntOrNull(json['rating']),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      summary: json['summary'] as String?,
      quotesCount: asInt(json['quotes_count']),
    );
  }

  Book copyWith({String? status, int? rating, String? summary}) {
    return Book(
      id: id,
      title: title,
      author: author,
      phase: phase,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      startDate: startDate,
      endDate: endDate,
      summary: summary ?? this.summary,
      quotesCount: quotesCount,
    );
  }
}

class BookQuote {
  const BookQuote({required this.id, required this.content, required this.source});

  final int id;
  final String content;
  final String? source;

  factory BookQuote.fromJson(Map<String, dynamic> json) {
    return BookQuote(
      id: asInt(json['id']),
      content: json['content'] as String? ?? '',
      source: json['source'] as String?,
    );
  }
}

/// GET /books/{id} — detail + citations
class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.author,
    required this.phase,
    required this.status,
    required this.rating,
    required this.summary,
    required this.notes,
    required this.quotes,
  });

  final int id;
  final String title;
  final String author;
  final int phase;
  final String status;
  final int? rating;
  final String? summary;
  final String? notes;
  final List<BookQuote> quotes;

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: asInt(json['id']),
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      phase: asInt(json['phase'], 1),
      status: json['status'] as String? ?? 'to_read',
      rating: asIntOrNull(json['rating']),
      summary: json['summary'] as String?,
      notes: json['notes'] as String?,
      quotes: (json['quotes'] as List<dynamic>? ?? [])
          .map((e) => BookQuote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  BookDetail copyWith({String? status, List<BookQuote>? quotes}) {
    return BookDetail(
      id: id,
      title: title,
      author: author,
      phase: phase,
      status: status ?? this.status,
      rating: rating,
      summary: summary,
      notes: notes,
      quotes: quotes ?? this.quotes,
    );
  }
}
