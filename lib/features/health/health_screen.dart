import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/health_model.dart';
import '../../core/theme/app_theme.dart';
import 'providers/health_providers.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Health')),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
        error: (error, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              error is ApiException ? error.message : "Could not load today's health log.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => ref.read(healthProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (health) => _HealthBody(health: health),
      ),
    );
  }
}

class _HealthBody extends ConsumerWidget {
  const _HealthBody({required this.health});

  final HealthLog health;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okCount = [health.sleepOk, health.exerciseOk, health.foodOk].where((v) => v).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          '$okCount/3 today',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _HealthToggleButton(
          label: 'Sleep',
          description: 'Did you get a good night\'s sleep?',
          icon: Icons.bedtime_outlined,
          value: health.sleepOk,
          onTap: () => ref.read(healthProvider.notifier).toggle(field: 'sleep', value: !health.sleepOk),
        ),
        const SizedBox(height: 16),
        _HealthToggleButton(
          label: 'Exercise',
          description: 'Did you move your body today?',
          icon: Icons.fitness_center,
          value: health.exerciseOk,
          onTap: () => ref.read(healthProvider.notifier).toggle(field: 'exercise', value: !health.exerciseOk),
        ),
        const SizedBox(height: 16),
        _HealthToggleButton(
          label: 'Food',
          description: 'Did you eat well today?',
          icon: Icons.restaurant_outlined,
          value: health.foodOk,
          onTap: () => ref.read(healthProvider.notifier).toggle(field: 'food', value: !health.foodOk),
        ),
      ],
    );
  }
}

class _HealthToggleButton extends StatefulWidget {
  const _HealthToggleButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final Future<void> Function() onTap;

  @override
  State<_HealthToggleButton> createState() => _HealthToggleButtonState();
}

class _HealthToggleButtonState extends State<_HealthToggleButton> {
  bool _isUpdating = false;

  Future<void> _handleTap() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.onTap();
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
    final color = widget.value ? AppColors.vert : AppColors.textMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.value ? AppColors.vert.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.value ? AppColors.vert.withOpacity(0.5) : AppColors.borderGlass, width: 1.4),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1C1C24).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(widget.icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            _isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.violet),
                  )
                : Icon(
                    widget.value ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: color,
                    size: 26,
                  ),
          ],
        ),
      ),
    );
  }
}
