import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/music_model.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/music_providers.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(musicProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Music · Zixe')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => const _AddSessionSheet(),
        ),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(musicProvider.notifier).load(),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          error: (error, _) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                error is ApiException ? error.message : 'Could not load your music sessions.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Center(child: ElevatedButton(onPressed: () => ref.read(musicProvider.notifier).load(), child: const Text('Retry'))),
            ],
          ),
          data: (sessions) => _MusicBody(sessions: sessions),
        ),
      ),
    );
  }
}

class _MusicBody extends ConsumerWidget {
  const _MusicBody({required this.sessions});
  final List<MusicSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(musicTypeFilterProvider);
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMin);

    final byType = <String, int>{};
    for (final s in sessions) {
      byType[s.sessionType] = (byType[s.sessionType] ?? 0) + 1;
    }

    final recentProjects = <String>[];
    for (final s in [...sessions]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate))) {
      final name = s.projectName;
      if (name != null && name.isNotEmpty && !recentProjects.contains(name)) {
        recentProjects.add(name);
        if (recentProjects.length >= 5) break;
      }
    }

    final filtered = filter == null ? sessions : sessions.where((s) => s.sessionType == filter).toList();
    final sorted = [...filtered]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        Text(
          '${_formatHours(totalMinutes)} total · ${sessions.length} session${sessions.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (byType.isNotEmpty || recentProjects.isNotEmpty) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (byType.isNotEmpty) ...[
                  const Text('By type', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in byType.entries)
                        Chip(
                          label: Text('${musicSessionTypeLabel(entry.key)} · ${entry.value}'),
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.borderGlass),
                          labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ],
                if (recentProjects.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Recent projects', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final project in recentProjects)
                        Chip(
                          label: Text(project),
                          backgroundColor: AppColors.violet.withOpacity(0.1),
                          side: BorderSide(color: AppColors.violet.withOpacity(0.3)),
                          labelStyle: const TextStyle(fontSize: 12, color: AppColors.violet, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: musicSessionTypes.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = index == 0 ? null : musicSessionTypes[index - 1];
              final label = index == 0 ? 'All' : musicSessionTypeLabel(value!);
              final selected = value == filter;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => ref.read(musicTypeFilterProvider.notifier).state = value,
                selectedColor: AppColors.violet,
                backgroundColor: AppColors.surfaceGlass,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600),
                side: BorderSide(color: selected ? AppColors.violet : AppColors.borderGlass),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('No sessions logged yet.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          for (final session in sorted) ...[
            _SessionCard(session: session),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});
  final MusicSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: AppColors.rouge.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: AppColors.rouge),
      ),
      onDismissed: (_) => ref.read(musicProvider.notifier).deleteSession(session.id),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.14), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.music_note, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.projectName?.isNotEmpty == true ? session.projectName! : musicSessionTypeLabel(session.sessionType),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(_formatHours(session.durationMin), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${musicSessionTypeLabel(session.sessionType)} · ${session.sessionDate}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(session.notes!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSessionSheet extends ConsumerStatefulWidget {
  const _AddSessionSheet();

  @override
  ConsumerState<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends ConsumerState<_AddSessionSheet> {
  String _type = musicSessionTypes.first;
  final _projectController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _projectController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration <= 0) {
      setState(() => _error = 'Enter a valid duration in minutes.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(musicProvider.notifier).addSession(
            sessionType: _type,
            durationMin: duration,
            notes: _notesController.text.trim(),
            projectName: _projectController.text.trim(),
            sessionDate: _formatApiDate(_date),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not add this session: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
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
            const Text('Log a session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: [
                for (final type in musicSessionTypes)
                  _TypeTile(
                    label: musicSessionTypeLabel(type),
                    selected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _projectController, decoration: const InputDecoration(labelText: 'Project (optional)')),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(_formatApiDate(_date)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.rouge, fontSize: 13)),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Save session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.violet.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.violet : AppColors.borderGlass),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.violet : AppColors.textSecondary),
        ),
      ),
    );
  }
}

String _formatHours(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

String _formatApiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
