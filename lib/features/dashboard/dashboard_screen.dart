import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/dashboard_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../health/providers/health_providers.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardResponse>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  return api.getDashboard();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    // Re-schedule today's block reminders every time fresh dashboard data
    // comes in (app launch, pull-to-refresh, or after editing a block).
    ref.listen<AsyncValue<DashboardResponse>>(dashboardProvider, (previous, next) {
      next.whenData((dashboard) {
        ref.read(notificationServiceProvider).scheduleForBlocks(dashboard.blocks);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authServiceProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => const DashboardLoadingSkeleton(),
          error: (error, _) => _DashboardError(
            message: error is ApiException ? error.message : 'Could not load your dashboard.',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (dashboard) => _DashboardBody(dashboard: dashboard),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});

  final DashboardResponse dashboard;

  @override
  Widget build(BuildContext context) {
    final remaining = dashboard.blocksTotal - dashboard.blocksDone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        const SizedBox(height: 4),
        Text(
          dashboard.greeting.isNotEmpty ? dashboard.greeting : 'Hello.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '$remaining block${remaining == 1 ? '' : 's'} left · ${dashboard.blocksDone} completed',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),

        if (dashboard.vision.isNotEmpty) ...[
          GlassCard(
            child: Text(
              dashboard.vision,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],

        Row(
          children: [
            Expanded(child: _StatPill(icon: '🔥', label: 'Streak', value: '${dashboard.streak}')),
            const SizedBox(width: 10),
            Expanded(child: _StatPill(icon: '📁', label: 'Projects', value: '${dashboard.projectsCount}')),
            const SizedBox(width: 10),
            Expanded(child: _StatPill(icon: '📚', label: 'Books', value: '${dashboard.booksCount}')),
          ],
        ),
        const SizedBox(height: 22),

        if (dashboard.activeBlock != null) ...[
          _ActiveBlockCard(block: dashboard.activeBlock!),
          const SizedBox(height: 22),
        ],

        _SectionTitle('Today\'s blocks'),
        const SizedBox(height: 10),
        _BlocksTimeline(blocks: dashboard.blocks),
        const SizedBox(height: 22),

        if (dashboard.projects.isNotEmpty) ...[
          _SectionTitle('Projects'),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              children: [
                for (var i = 0; i < dashboard.projects.length; i++) ...[
                  if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.borderGlass)),
                  _ProjectRow(project: dashboard.projects[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        _SectionTitle('Health'),
        const SizedBox(height: 10),
        GlassCard(
          child: Row(
            children: [
              Expanded(child: _HealthChip(label: 'Sleep', field: 'sleep', ok: dashboard.health.sleepOk, icon: Icons.bedtime_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _HealthChip(label: 'Exercise', field: 'exercise', ok: dashboard.health.exerciseOk, icon: Icons.fitness_center)),
              const SizedBox(width: 10),
              Expanded(child: _HealthChip(label: 'Food', field: 'food', ok: dashboard.health.foodOk, icon: Icons.restaurant_outlined)),
            ],
          ),
        ),

        if (dashboard.quote != null && dashboard.quote!.text.isNotEmpty) ...[
          const SizedBox(height: 22),
          GlassCard(
            child: Column(
              children: [
                Text(
                  '"${dashboard.quote!.text}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${dashboard.quote!.source}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value});

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ActiveBlockCard extends StatelessWidget {
  const _ActiveBlockCard({required this.block});
  final ScheduleBlock block;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.violet.withOpacity(0.6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT', style: TextStyle(fontSize: 11, color: AppColors.violet, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(block.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  '${_trimSeconds(block.timeStart)} – ${_trimSeconds(block.timeEnd)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable row of small colored squares, one per block —
/// mirrors the web app's "today's blocks" strip. Tap a square to see the
/// block name, time range and status for that block.
class _BlocksTimeline extends StatelessWidget {
  const _BlocksTimeline({required this.blocks});
  final List<ScheduleBlock> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Text('No blocks scheduled for today.', style: TextStyle(color: AppColors.textMuted));
    }

    final sorted = [...blocks]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _BlockSquare(block: sorted[index]),
      ),
    );
  }
}

class _BlockSquare extends StatelessWidget {
  const _BlockSquare({required this.block});
  final ScheduleBlock block;

  @override
  Widget build(BuildContext context) {
    final isCurrent = block.isCurrent;
    final statusColor = AppColors.statusColor(block.status);
    final squareColor = isCurrent ? AppColors.violet : statusColor.withOpacity(block.status == 'pending' ? 0.14 : 0.22);
    final borderColor = isCurrent ? AppColors.violet : statusColor.withOpacity(0.4);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showBlockDetails(context, block),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: squareColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: isCurrent ? 0 : 1),
            ),
            alignment: Alignment.center,
            child: isCurrent
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            _trimSeconds(block.timeStart),
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? AppColors.violet : AppColors.textMuted,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDetails(BuildContext context, ScheduleBlock block) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(block.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  StatusBadge(status: block.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_trimSeconds(block.timeStart)} – ${_trimSeconds(block.timeEnd)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              if (block.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(block.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});
  final DashboardProject project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('${project.tasksDone}/${project.tasksTotal}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (project.progress.clamp(0, 100)) / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceGlass,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
      ],
    );
  }
}

class _HealthChip extends ConsumerStatefulWidget {
  const _HealthChip({required this.label, required this.field, required this.ok, required this.icon});

  final String label;
  final String field; // 'sleep' | 'exercise' | 'food'
  final bool ok;
  final IconData icon;

  @override
  ConsumerState<_HealthChip> createState() => _HealthChipState();
}

class _HealthChipState extends ConsumerState<_HealthChip> {
  bool _isUpdating = false;

  Future<void> _handleTap() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(healthProvider.notifier).toggle(field: widget.field, value: !widget.ok);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.ok ? AppColors.vert : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            _isUpdating
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: color))
                : Icon(widget.icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(widget.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

String _trimSeconds(String time) {
  final parts = time.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return time;
}
