import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/recap_model.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/recap_providers.dart';

const _frenchMonths = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

String _monthLabel(String yyyyMm) {
  final parts = yyyyMm.split('-');
  if (parts.length != 2) return yyyyMm;
  final monthIndex = int.tryParse(parts[1]);
  if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return yyyyMm;
  return '${_frenchMonths[monthIndex - 1]} ${parts[0]}';
}

String _shiftMonth(String yyyyMm, int delta) {
  final parts = yyyyMm.split('-');
  var year = int.parse(parts[0]);
  var month = int.parse(parts[1]) + delta;
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  return '$year-${month.toString().padLeft(2, '0')}';
}

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedRecapMonthProvider);
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final isCurrentMonth = selectedMonth == currentMonth;

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly AI recap')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(selectedRecapMonthProvider.notifier).state = _shiftMonth(selectedMonth, -1),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    _monthLabel(selectedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isCurrentMonth ? null : () => ref.read(selectedRecapMonthProvider.notifier).state = _shiftMonth(selectedMonth, 1),
                ),
              ],
            ),
          ),
          const Expanded(child: _RecapBody()),
        ],
      ),
    );
  }
}

class _RecapBody extends ConsumerWidget {
  const _RecapBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recapProvider);

    return async.when(
      loading: () => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: const [
          SizedBox(height: 100),
          Center(child: CircularProgressIndicator(color: AppColors.violet)),
          SizedBox(height: 20),
          Text(
            "Génération du résumé en cours — le modèle relit tout ton mois, ça peut prendre quelques secondes.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      error: (error, _) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            error is ApiException ? error.message : 'Impossible de générer le résumé du mois.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Center(child: ElevatedButton(onPressed: () => ref.invalidate(recapProvider), child: const Text('Réessayer'))),
        ],
      ),
      data: (recap) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          GlassCard(
            child: Text(
              recap.recapText.trim(),
              style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 24),
          const Text('En chiffres', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _StatsSection(data: recap.data),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.data});

  final RecapData data;

  @override
  Widget build(BuildContext context) {
    final blocks = data.blocks;
    final health = data.health;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_outline,
                label: 'Blocs complétés',
                value: blocks.total > 0 ? '${blocks.done}/${blocks.total} (${blocks.donePercent!.round()}%)' : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(icon: Icons.local_fire_department_outlined, label: 'Streak max', value: '${data.maxStreak}j'),
            ),
          ],
        ),
        if (health.daysLogged > 0) ...[
          const SizedBox(height: 12),
          _StatTile(
            icon: Icons.favorite_outline,
            label: 'Santé — ${health.daysLogged} jours loggés',
            value: 'sommeil ${health.sleepOk}j · sport ${health.exerciseOk}j · alim. ${health.foodOk}j',
          ),
        ],
        if (data.booksFinished.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ListTile(
            icon: Icons.menu_book_outlined,
            label: 'Livres terminés',
            items: data.booksFinished.map((b) => '${b.title} — ${b.author}').toList(),
          ),
        ],
        if (data.booksReading.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ListTile(
            icon: Icons.auto_stories_outlined,
            label: 'En cours de lecture',
            items: data.booksReading.map((b) => b.title).toList(),
          ),
        ],
        if (data.learning.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ListTile(
            icon: Icons.school_outlined,
            label: 'Apprentissage',
            items: data.learning.map((l) => '${l.domain} — ${l.totalMin}min (${l.sessions} sessions)').toList(),
          ),
        ],
        if (data.music.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ListTile(
            icon: Icons.music_note_outlined,
            label: 'Musique',
            items: data.music.map((m) => '${m.sessionType} — ${m.totalMin}min').toList(),
          ),
        ],
        if (data.spiritual.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ListTile(
            icon: Icons.self_improvement_outlined,
            label: 'Pratiques spirituelles',
            items: data.spiritual.map((s) => '${s.name} — ${s.daysDone}j').toList(),
          ),
        ],
        if (data.projects.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ListTile(
            icon: Icons.rocket_launch_outlined,
            label: 'Projets',
            items: data.projects.map((p) => '${p.name} (${p.status})').toList(),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.violet, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.icon, required this.label, required this.items});

  final IconData icon;
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.violet, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
