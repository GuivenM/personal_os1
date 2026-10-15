import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/book_model.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/books_providers.dart';

const _confettiColors = [AppColors.violet, AppColors.teal, AppColors.orange, AppColors.vert];

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('Book')),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
            error: (error, _) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 100),
                const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  error is ApiException ? error.message : 'Could not load this book.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => ref.read(bookDetailProvider(widget.bookId).notifier).load(),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
            data: (book) => _BookDetailBody(
              book: book,
              bookId: widget.bookId,
              onBecameDone: () => _confettiController.play(),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 12,
            minBlastForce: 6,
            emissionFrequency: 0.08,
            numberOfParticles: 24,
            gravity: 0.25,
            colors: _confettiColors,
          ),
        ],
      ),
    );
  }
}

class _BookDetailBody extends ConsumerStatefulWidget {
  const _BookDetailBody({required this.book, required this.bookId, required this.onBecameDone});

  final BookDetail book;
  final int bookId;
  final VoidCallback onBecameDone;

  @override
  ConsumerState<_BookDetailBody> createState() => _BookDetailBodyState();
}

class _BookDetailBodyState extends ConsumerState<_BookDetailBody> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _setStatus(String status) async {
    try {
      final becameDone = await ref.read(bookDetailProvider(widget.bookId).notifier).setStatus(status);
      if (becameDone) widget.onBecameDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(book.author, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text(
                'Phase ${book.phase} · ${bookPhaseNames[book.phase] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Status'), Tab(text: 'Quotes')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _StatusTab(book: book, onSetStatus: _setStatus),
              _QuotesTab(book: book, bookId: widget.bookId),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({required this.book, required this.onSetStatus});

  final BookDetail book;
  final Future<void> Function(String status) onSetStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        for (final status in bookStatuses) ...[
          _StatusOption(
            status: status,
            selected: book.status == status,
            onTap: () => onSetStatus(status),
          ),
          const SizedBox(height: 10),
        ],
        if (book.summary != null && book.summary!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Summary', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(child: Text(book.summary!, style: const TextStyle(color: AppColors.textSecondary, height: 1.4))),
        ],
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({required this.status, required this.selected, required this.onTap});

  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected ? AppColors.violet.withOpacity(0.6) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.violet : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            bookStatusLabel(status),
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotesTab extends ConsumerStatefulWidget {
  const _QuotesTab({required this.book, required this.bookId});

  final BookDetail book;
  final int bookId;

  @override
  ConsumerState<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends ConsumerState<_QuotesTab> {
  final _contentController = TextEditingController();
  final _sourceController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _contentController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _addQuote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await ref.read(bookDetailProvider(widget.bookId).notifier).addQuote(
            content,
            _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
          );
      _contentController.clear();
      _sourceController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add this quote: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteQuote(int quoteId) async {
    try {
      await ref.read(bookDetailProvider(widget.bookId).notifier).deleteQuote(quoteId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete this quote: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = widget.book.quotes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'New quote'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Source (optional)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isAdding ? null : _addQuote,
                child: _isAdding
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Text('Add quote'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (quotes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('No quotes yet.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          for (final quote in quotes) ...[
            GlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('"${quote.content}"', style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
                        if (quote.source != null && quote.source!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('— ${quote.source}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                    onPressed: () => _deleteQuote(quote.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
