import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/schedule_providers.dart';
import '../widgets/block_card.dart';

class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(todayScheduleProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(todayScheduleProvider.notifier).load(),
      child: scheduleAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            SizedBox(height: 200),
            Center(child: CircularProgressIndicator(color: AppColors.violet)),
          ],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              error is ApiException ? error.message : "Could not load today's schedule.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => ref.read(todayScheduleProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (schedule) => _TodayList(schedule: schedule),
      ),
    );
  }
}

class _TodayList extends ConsumerWidget {
  const _TodayList({required this.schedule});

  final ScheduleDayResponse schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = schedule.blocks.length;
    final done = schedule.blocks.where((b) => b.status == 'done').length;
    final progress = total == 0 ? 0.0 : done / total;

    if (schedule.blocks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.event_busy, size: 44, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No blocks defined yet. Add some from the Edit tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceGlass,
                  valueColor: const AlwaysStoppedAnimation(AppColors.violet),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$done/$total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 18),
        for (final block in schedule.blocks) ...[
          BlockCard(
            block: block,
            onSetStatus: (status) => ref.read(todayScheduleProvider.notifier).setStatus(block, status),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
