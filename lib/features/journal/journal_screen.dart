import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/journal_providers.dart';

const _prompts = [
  'What happened today?',
  'What did you notice or learn?',
  'What do you want for tomorrow?',
];

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Journal'),
          bottom: const TabBar(tabs: [Tab(text: 'Write'), Tab(text: 'Entries')]),
        ),
        body: const TabBarView(
          children: [_WriteTab(), _EntriesTab()],
        ),
      ),
    );
  }
}

class _WriteTab extends ConsumerStatefulWidget {
  const _WriteTab();

  @override
  ConsumerState<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends ConsumerState<_WriteTab> {
  late TextEditingController _controller;
  DateTime? _controllerDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalProvider);

    // Keep the text field's controller in sync when the selected date
    // changes (new content loaded), without fighting the user's cursor
    // while they're actively typing on the same date.
    if (_controllerDate != state.date && !state.isLoading) {
      _controller.text = state.content;
      _controllerDate = state.date;
    }

    final isToday = _isSameDay(state.date, DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(journalProvider.notifier).goToDate(
                      state.date.subtract(const Duration(days: 1)),
                    ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDate(state.date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (!isToday)
                      GestureDetector(
                        onTap: () => ref.read(journalProvider.notifier).goToToday(),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('Back to today', style: TextStyle(fontSize: 11, color: AppColors.violet)),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isToday
                    ? null
                    : () => ref.read(journalProvider.notifier).goToDate(
                          state.date.add(const Duration(days: 1)),
                        ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.violet))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final prompt in _prompts) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  ', style: TextStyle(color: AppColors.textMuted)),
                                Expanded(
                                  child: Text(prompt, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                ),
                              ],
                            ),
                            if (prompt != _prompts.last) const SizedBox(height: 4),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      maxLines: 14,
                      minLines: 10,
                      onChanged: (value) => ref.read(journalProvider.notifier).updateContent(value),
                      decoration: const InputDecoration(
                        hintText: 'Write freely...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${state.content.length} characters', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        _SaveIndicator(status: state.saveStatus),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status});
  final JournalSaveStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case JournalSaveStatus.saving:
        return const Text('●  Saving...', style: TextStyle(color: AppColors.orange, fontSize: 12));
      case JournalSaveStatus.saved:
        return const Text('✓  Saved', style: TextStyle(color: AppColors.vert, fontSize: 12));
      case JournalSaveStatus.error:
        return const Text('Could not save', style: TextStyle(color: AppColors.rouge, fontSize: 12));
      case JournalSaveStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

class _EntriesTab extends ConsumerWidget {
  const _EntriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(journalHistoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(journalHistoryProvider.future),
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
        error: (error, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Could not load your journal entries.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Center(child: ElevatedButton(onPressed: () => ref.invalidate(journalHistoryProvider), child: const Text('Retry'))),
          ],
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No entries yet.', style: TextStyle(color: AppColors.textMuted)));
          }
          final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: sorted.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = sorted[index];
              return GlassCard(
                onTap: () {
                  final date = DateTime.tryParse(entry.date);
                  if (date != null) {
                    ref.read(journalProvider.notifier).goToDate(date);
                    DefaultTabController.of(context).animateTo(0);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.date, style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text('${entry.charCount} chars', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    if (entry.preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
