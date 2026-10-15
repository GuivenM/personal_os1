import '../api/api_client.dart';
import '../models/book_model.dart';

class BooksApi {
  BooksApi(this._client);

  final ApiClient _client;

  Future<List<Book>> getBooks({String? status, int? phase}) async {
    final json = await _client.get('/books', query: {
      if (status != null) 'status': status,
      if (phase != null) 'phase': phase,
    });
    return (json as List<dynamic>).map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Book> createBook({
    required String title,
    required String author,
    required int phase,
    required String status,
  }) async {
    final json = await _client.post('/books', body: {
      'title': title,
      'author': author,
      'phase': phase,
      'status': status,
    });
    return Book.fromJson(json as Map<String, dynamic>);
  }

  Future<BookDetail> getBook(int id) async {
    final json = await _client.get('/books/$id');
    return BookDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateBook(int id, Map<String, dynamic> fields) async {
    await _client.put('/books/$id', body: fields);
  }

  Future<void> deleteBook(int id) async {
    await _client.delete('/books/$id');
  }

  Future<List<BookQuote>> getQuotes(int bookId) async {
    final json = await _client.get('/books/$bookId/quotes');
    return (json as List<dynamic>).map((e) => BookQuote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookQuote> addQuote(int bookId, {required String content, String? source}) async {
    final json = await _client.post('/books/$bookId/quotes', body: {
      'content': content,
      if (source != null && source.isNotEmpty) 'source': source,
    });
    return BookQuote.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteQuote(int quoteId) async {
    await _client.delete('/quotes/$quoteId');
  }
}
