import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Simple shimmer-less loading placeholder block.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Full-page skeleton used while the dashboard is loading.
class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        LoadingSkeleton(height: 14, width: 100),
        SizedBox(height: 10),
        LoadingSkeleton(height: 28, width: 220),
        SizedBox(height: 24),
        LoadingSkeleton(height: 70),
        SizedBox(height: 16),
        LoadingSkeleton(height: 60),
        SizedBox(height: 16),
        LoadingSkeleton(height: 120),
        SizedBox(height: 16),
        LoadingSkeleton(height: 160),
      ],
    );
  }
}
