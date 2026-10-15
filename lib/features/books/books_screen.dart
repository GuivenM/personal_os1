import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/book_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'book_detail_screen.dart';
import 'providers/books_providers.dart';

const _filters = [
  {'value': 'all', 'label': 'All'},
  {'value': 'reading', 'label': 'Reading'},
  {'value': 'to_read', 'label': 'To read'},
  {'value': 'done', 'label': 'Done'},
  {'value': 'paused', 'label': 'Paused'},
];

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksListProvider);
    final filter = ref.watch(bookFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddBookSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(booksListProvider.future),
        child: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          error: (error, _) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                error is ApiException ? error.message : 'Could not load your books.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(onPressed: () => ref.invalidate(booksListProvider), child: const Text('Retry')),
              ),
            ],
          ),
          data: (books) => _BooksBody(books: books, filter: filter),
        ),
      ),
    );
  }

  Future<void> _openAddBookSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _AddBookSheet(),
    );
  }
}

class _BooksBody extends ConsumerWidget {
  const _BooksBody({required this.books, required this.filter});

  final List<Book> books;
  final String filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneCount = books.where((b) => b.status == 'done').length;
    final readingCount = books.where((b) => b.status == 'reading').length;

    final filtered = filter == 'all' ? books : books.where((b) => b.status == filter).toList();

    final phases = bookPhaseNames.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        Text(
          '$doneCount done · $readingCount reading · ${books.length} total',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = _filters[index]['value']!;
              final selected = value == filter;
              return ChoiceChip(
                label: Text(_filters[index]['label']!),
                selected: selected,
                onSelected: (_) => ref.read(bookFilterProvider.notifier).state = value,
                selectedColor: AppColors.violet,
                backgroundColor: AppColors.surfaceGlass,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600),
                side: BorderSide(color: selected ? AppColors.violet : AppColors.borderGlass),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('No books here yet.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          for (final phase in phases) ...[
            _PhaseSection(
              phase: phase,
              allBooksInPhase: books.where((b) => b.phase == phase).toList(),
              filteredBooksInPhase: filtered.where((b) => b.phase == phase).toList(),
            ),
          ],
      ],
    );
  }
}

class _PhaseSection extends StatelessWidget {
  const _PhaseSection({
    required this.phase,
    required this.allBooksInPhase,
    required this.filteredBooksInPhase,
  });

  final int phase;
  final List<Book> allBooksInPhase;
  final List<Book> filteredBooksInPhase;

  @override
  Widget build(BuildContext context) {
    if (filteredBooksInPhase.isEmpty) return const SizedBox.shrink();

    final total = allBooksInPhase.length;
    final done = allBooksInPhase.where((b) => b.status == 'done').length;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: true,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Phase $phase · ${bookPhaseNames[phase]}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text('$done/$total', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceGlass,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
              ),
            ),
          ),
          children: [
            for (final book in filteredBooksInPhase) ...[
              _BookRow(book: book),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => BookDetailScreen(bookId: book.id)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(book.author, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(book.status).withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _statusColor(book.status).withOpacity(0.5)),
            ),
            child: Text(
              bookStatusLabel(book.status),
              style: TextStyle(color: _statusColor(book.status), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.vert;
      case 'reading':
        return AppColors.violet;
      case 'paused':
        return AppColors.orange;
      case 'abandoned':
        return AppColors.rouge;
      case 'to_read':
      default:
        return AppColors.gris;
    }
  }
}

class _AddBookSheet extends ConsumerStatefulWidget {
  const _AddBookSheet();

  @override
  ConsumerState<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<_AddBookSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  int _phase = 1;
  String _status = 'to_read';
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(booksApiProvider).createBook(
            title: _titleController.text.trim(),
            author: _authorController.text.trim(),
            phase: _phase,
            status: _status,
          );
      ref.invalidate(booksListProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not add this book.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add a book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 14),
            TextField(controller: _authorController, decoration: const InputDecoration(labelText: 'Author')),
            const SizedBox(height: 16),
            const Text('Phase', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final phase in bookPhaseNames.keys)
                  ChoiceChip(
                    label: Text('$phase'),
                    selected: _phase == phase,
                    onSelected: (_) => setState(() => _phase = phase),
                    selectedColor: AppColors.violet,
                    backgroundColor: AppColors.surfaceGlass,
                    labelStyle: TextStyle(color: _phase == phase ? Colors.white : AppColors.textSecondary),
                    side: BorderSide(color: _phase == phase ? AppColors.violet : AppColors.borderGlass),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in bookStatuses)
                  ChoiceChip(
                    label: Text(bookStatusLabel(status)),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                    selectedColor: AppColors.violet,
                    backgroundColor: AppColors.surfaceGlass,
                    labelStyle: TextStyle(color: _status == status ? Colors.white : AppColors.textSecondary),
                    side: BorderSide(color: _status == status ? AppColors.violet : AppColors.borderGlass),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.rouge, fontSize: 13)),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Add book'),
            ),
          ],
        ),
      ),
    );
  }
}
