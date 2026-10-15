import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/book_model.dart';
import '../../../core/services/auth_service.dart';

/// 'all' | one of [bookStatuses]
final bookFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

final booksListProvider = FutureProvider.autoDispose<List<Book>>((ref) async {
  final api = ref.watch(booksApiProvider);
  return api.getBooks();
});

class BookDetailNotifier extends StateNotifier<AsyncValue<BookDetail>> {
  BookDetailNotifier(this._ref, this.bookId) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final int bookId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final detail = await _ref.read(booksApiProvider).getBook(bookId);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Returns true if this update transitioned the book into "done"
  /// (used by the UI to trigger the confetti animation).
  Future<bool> setStatus(String status) async {
    final current = state.value;
    if (current == null) return false;
    final wasDone = current.status == 'done';

    await _ref.read(booksApiProvider).updateBook(bookId, {'status': status});
    state = AsyncValue.data(current.copyWith(status: status));
    _ref.invalidate(booksListProvider);

    return status == 'done' && !wasDone;
  }

  Future<void> addQuote(String content, String? source) async {
    final current = state.value;
    if (current == null) return;
    final quote = await _ref.read(booksApiProvider).addQuote(bookId, content: content, source: source);
    state = AsyncValue.data(current.copyWith(quotes: [...current.quotes, quote]));
    _ref.invalidate(booksListProvider);
  }

  Future<void> deleteQuote(int quoteId) async {
    final current = state.value;
    if (current == null) return;
    await _ref.read(booksApiProvider).deleteQuote(quoteId);
    state = AsyncValue.data(current.copyWith(quotes: current.quotes.where((q) => q.id != quoteId).toList()));
    _ref.invalidate(booksListProvider);
  }
}

final bookDetailProvider =
    StateNotifierProvider.autoDispose.family<BookDetailNotifier, AsyncValue<BookDetail>, int>((ref, bookId) {
  return BookDetailNotifier(ref, bookId);
});
