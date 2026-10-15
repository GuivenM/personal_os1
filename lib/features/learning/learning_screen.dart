import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/learning_model.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/learning_providers.dart';

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(learningProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(learningProvider.notifier).load(),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          error: (error, _) => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                error is ApiException ? error.message : 'Could not load your learning sessions.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Center(child: ElevatedButton(onPressed: () => ref.read(learningProvider.notifier).load(), child: const Text('Retry'))),
            ],
          ),
          data: (sessions) => _LearningBody(sessions: sessions),
        ),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _AddSessionSheet(),
    );
  }
}

class _LearningBody extends ConsumerWidget {
  const _LearningBody({required this.sessions});
  final List<LearningSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(learningDomainFilterProvider);
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMin);

    final byDomain = <String, int>{};
    for (final s in sessions) {
      byDomain[s.domain] = (byDomain[s.domain] ?? 0) + s.durationMin;
    }
    final dominantDomain = byDomain.entries.isEmpty
        ? null
        : byDomain.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final filtered = filter == null ? sessions : sessions.where((s) => s.domain == filter).toList();
    final sorted = [...filtered]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        Text(
          '${_formatHours(totalMinutes)} total'
          '${dominantDomain != null ? ' · mostly ${learningDomainLabel(dominantDomain)}' : ''}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (byDomain.isNotEmpty) ...[
          GlassCard(
            child: Column(
              children: [
                for (var i = 0; i < learningDomains.length; i++) ...[
                  if (byDomain[learningDomains[i]] != null) ...[
                    if (i > 0 && byDomain.keys.toList().indexOf(learningDomains[i]) > 0)
                      const SizedBox(height: 10),
                    _DomainProgressRow(
                      domain: learningDomains[i],
                      minutes: byDomain[learningDomains[i]] ?? 0,
                      totalMinutes: totalMinutes,
                    ),
                    if (learningDomains[i] != learningDomains.last) const SizedBox(height: 10),
                  ],
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
            itemCount: learningDomains.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = index == 0 ? null : learningDomains[index - 1];
              final label = index == 0 ? 'All' : learningDomainLabel(value!);
              final selected = value == filter;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => ref.read(learningDomainFilterProvider.notifier).state = value,
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

class _DomainProgressRow extends StatelessWidget {
  const _DomainProgressRow({required this.domain, required this.minutes, required this.totalMinutes});
  final String domain;
  final int minutes;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final ratio = totalMinutes == 0 ? 0.0 : minutes / totalMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(learningDomainLabel(domain), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Text(_formatHours(minutes), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});
  final LearningSession session;

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
      onDismissed: (_) => ref.read(learningProvider.notifier).deleteSession(session.id),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(learningLevelEmoji(session.level), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.subdomain?.isNotEmpty == true ? session.subdomain! : learningDomainLabel(session.domain),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(_formatHours(session.durationMin), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${learningDomainLabel(session.domain)} · ${session.sessionDate} · ${learningLevelLabel(session.level)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (session.content != null && session.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(session.content!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
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
  String _domain = learningDomains.first;
  final _subdomainController = TextEditingController();
  final _durationController = TextEditingController();
  final _contentController = TextEditingController();
  final _resourceController = TextEditingController();
  int _level = 3;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _subdomainController.dispose();
    _durationController.dispose();
    _contentController.dispose();
    _resourceController.dispose();
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
      await ref.read(learningProvider.notifier).addSession(
            domain: _domain,
            subdomain: _subdomainController.text.trim(),
            durationMin: duration,
            content: _contentController.text.trim(),
            resource: _resourceController.text.trim(),
            level: _level,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final domain in learningDomains)
                  ChoiceChip(
                    label: Text(learningDomainLabel(domain)),
                    selected: _domain == domain,
                    onSelected: (_) => setState(() => _domain = domain),
                    selectedColor: AppColors.violet,
                    labelStyle: TextStyle(color: _domain == domain ? Colors.white : AppColors.textSecondary),
                    side: BorderSide(color: _domain == domain ? AppColors.violet : AppColors.borderGlass),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(controller: _subdomainController, decoration: const InputDecoration(labelText: 'Sub-topic (optional)')),
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
            TextField(controller: _contentController, maxLines: 3, decoration: const InputDecoration(labelText: 'What did you work on? (optional)')),
            const SizedBox(height: 14),
            TextField(controller: _resourceController, decoration: const InputDecoration(labelText: 'Resource (optional)')),
            const SizedBox(height: 16),
            const Text('Level', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in learningLevels)
                  ChoiceChip(
                    label: Text('${learningLevelEmoji(level)} ${learningLevelLabel(level)}'),
                    selected: _level == level,
                    onSelected: (_) => setState(() => _level = level),
                    selectedColor: AppColors.violet,
                    labelStyle: TextStyle(color: _level == level ? Colors.white : AppColors.textSecondary),
                    side: BorderSide(color: _level == level ? AppColors.violet : AppColors.borderGlass),
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
                  : const Text('Save session'),
            ),
          ],
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
