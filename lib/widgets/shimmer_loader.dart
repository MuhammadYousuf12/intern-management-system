import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

// Shimmer loading effect for list items and cards.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double borderRadius;
  const ShimmerCard({super.key, this.height = 80, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      highlightColor: isDark
          ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
          : AppColors.lightTextSecondary.withValues(alpha: 0.2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Shimmer list — shows multiple shimmer cards while data loads.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  const ShimmerList({super.key, this.itemCount = 4, this.itemHeight = 80});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => ShimmerCard(height: itemHeight),
    );
  }
}
