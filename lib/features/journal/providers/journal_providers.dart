import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/journal_model.dart';
import '../../../core/services/auth_service.dart';

enum JournalSaveStatus { idle, saving, saved, error }

class JournalState {
  const JournalState({
    required this.date,
    required this.content,
    required this.isLoading,
    required this.saveStatus,
    this.error,
  });

  final DateTime date;
  final String content;
  final bool isLoading;
  final JournalSaveStatus saveStatus;
  final String? error;

  factory JournalState.initial(DateTime date) => JournalState(
        date: date,
        content: '',
        isLoading: true,
        saveStatus: JournalSaveStatus.idle,
      );

  JournalState copyWith({
    DateTime? date,
    String? content,
    bool? isLoading,
    JournalSaveStatus? saveStatus,
    String? error,
  }) {
    return JournalState(
      date: date ?? this.date,
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      saveStatus: saveStatus ?? this.saveStatus,
      error: error,
    );
  }
}

String formatApiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Holds the entry currently being viewed/edited, and debounces saves by
/// 1500ms after the last keystroke (per the spec).
class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier(this._ref) : super(JournalState.initial(DateTime.now())) {
    _load(state.date);
  }

  final Ref _ref;
  Timer? _debounce;

  Future<void> _load(DateTime date) async {
    _debounce?.cancel();
    state = JournalState.initial(date);
    try {
      final entry = await _ref.read(journalApiProvider).getEntry(date: formatApiDate(date));
      state = state.copyWith(content: entry.content ?? '', isLoading: false, saveStatus: JournalSaveStatus.idle);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void goToDate(DateTime date) => _load(date);

  void goToToday() => _load(DateTime.now());

  void updateContent(String content) {
    state = state.copyWith(content: content, saveStatus: JournalSaveStatus.saving, error: null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _save);
  }

  Future<void> _save() async {
    final targetDate = state.date;
    try {
      await _ref.read(journalApiProvider).saveEntry(date: formatApiDate(targetDate), content: state.content);
      if (state.date == targetDate) {
        state = state.copyWith(saveStatus: JournalSaveStatus.saved);
      }
    } catch (e) {
      if (state.date == targetDate) {
        state = state.copyWith(saveStatus: JournalSaveStatus.error, error: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final journalProvider = StateNotifierProvider.autoDispose<JournalNotifier, JournalState>((ref) {
  return JournalNotifier(ref);
});

final journalHistoryProvider = FutureProvider.autoDispose<List<JournalHistoryItem>>((ref) async {
  final api = ref.watch(journalApiProvider);
  return api.getHistory();
});
