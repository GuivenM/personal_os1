import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A soft, elevated white card used across the app for dashboard sections,
/// list items, etc. (Kept the "GlassCard" name for backward compatibility
/// with existing call sites — visually it's now a plain elevated card, not
/// a translucent/glass one.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.4) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C24).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: card),
      ),
    );
  }
}
