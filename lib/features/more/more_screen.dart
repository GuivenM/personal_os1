import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/lock_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../auth/pin_setup_screen.dart';
import '../health/health_screen.dart';
import '../journal/journal_screen.dart';
import '../learning/learning_screen.dart';
import '../music/music_screen.dart';
import '../recap/recap_screen.dart';
import '../spiritual/spiritual_screen.dart';
import '../vision/vision_screen.dart';

class _MoreItem {
  const _MoreItem({required this.label, required this.icon, this.builder, this.onTap});
  final String label;
  final IconData icon;
  final WidgetBuilder? builder;
  final VoidCallback? onTap;
}

final _items = <_MoreItem>[
  _MoreItem(label: 'Journal', icon: Icons.edit_note_outlined, builder: (context) => const JournalScreen()),
  _MoreItem(label: 'Vision & Goals', icon: Icons.flag_outlined, builder: (context) => const VisionScreen()),
  _MoreItem(label: 'Learning', icon: Icons.school_outlined, builder: (context) => const LearningScreen()),
  _MoreItem(label: 'Music · Zixe', icon: Icons.music_note_outlined, builder: (context) => const MusicScreen()),
  _MoreItem(label: 'Health', icon: Icons.favorite_outline, builder: (context) => const HealthScreen()),
  _MoreItem(label: 'Spiritual', icon: Icons.self_improvement_outlined, builder: (context) => const SpiritualScreen()),
  const _MoreItem(label: 'Network', icon: Icons.people_outline),
  _MoreItem(label: 'Monthly AI recap', icon: Icons.auto_awesome_outlined, builder: (context) => const RecapScreen()),
  _MoreItem(
    label: 'Send test notification',
    icon: Icons.notifications_active_outlined,
    onTap: () => NotificationService.instance.showTestNotification(),
  ),
];

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: _items.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _items.length) return const _SecuritySection();
          final item = _items[index];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (item.onTap != null) {
                  item.onTap!();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} sent.')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: item.builder ?? (context) => ComingSoon(title: item.label, icon: item.icon),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGlass),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppColors.violet, size: 22),
                    const SizedBox(width: 14),
                    Expanded(child: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// PIN / fingerprint settings.
class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(lockServiceProvider);
    final lockNotifier = ref.read(lockServiceProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 10, left: 4),
          child: Text(
            'SECURITY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
        ),
        _SecurityTile(
          icon: Icons.pin_outlined,
          label: lock.hasPin ? 'Change PIN' : 'Set a PIN',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PinSetupScreen()),
          ),
        ),
        if (lock.hasPin) ...[
          if (lock.biometricAvailable) ...[
            const SizedBox(height: 10),
            _SecurityTile(
              icon: Icons.fingerprint,
              label: 'Fingerprint unlock',
              trailing: Switch(
                value: lock.biometricEnabled,
                activeColor: AppColors.violet,
                onChanged: (value) async {
                  final ok = await lockNotifier.setBiometricEnabled(value);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fingerprint could not be changed.')),
                    );
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          _SecurityTile(
            icon: Icons.lock_outline,
            label: 'Lock now',
            onTap: () => ref.read(authServiceProvider.notifier).lock(),
          ),
          const SizedBox(height: 10),
          _SecurityTile(
            icon: Icons.no_encryption_gmailerrorred_outlined,
            label: 'Remove PIN',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove PIN?'),
                  content: const Text('The app will open without asking for a PIN or fingerprint.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
                  ],
                ),
              );
              if (confirmed == true) await lockNotifier.removePin();
            },
          ),
        ],
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({required this.icon, required this.label, this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: trailing != null ? 8 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.violet, size: 22),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
