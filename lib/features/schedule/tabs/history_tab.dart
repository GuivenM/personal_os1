import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/schedule_providers.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scheduleHistoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(scheduleHistoryProvider.future),
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
        error: (error, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              error is ApiException ? error.message : 'Could not load your history.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => ref.invalidate(scheduleHistoryProvider),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (history) => _HistoryList(history: history),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final ScheduleHistoryResponse history;

  @override
  Widget build(BuildContext context) {
    final days = [...history.days]..sort((a, b) => b.logDate.compareTo(a.logDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        GlassCard(
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${history.streak}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const Text('day streak', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (days.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('No history yet.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          for (final day in days) ...[
            _HistoryRow(day: day),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.day});
  final HistoryDay day;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(_formatDate(day.logDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (day.done > 0) Expanded(flex: day.done, child: Container(color: AppColors.vert)),
                    if (day.partial > 0) Expanded(flex: day.partial, child: Container(color: AppColors.orange)),
                    if (day.skipped > 0) Expanded(flex: day.skipped, child: Container(color: AppColors.rouge)),
                    if (day.pending > 0) Expanded(flex: day.pending, child: Container(color: AppColors.gris)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${day.done}/${day.total}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  static String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }
}
