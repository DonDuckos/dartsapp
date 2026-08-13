import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wiederkehrendes Favoriten-Symbol (Raute statt klassischem Stern) —
/// bewusst als eigenes Markenzeichen der App, siehe Mockup.
class FavoriteDiamond extends StatelessWidget {
  const FavoriteDiamond({super.key, required this.active, this.size = 9, this.onTap});

  final bool active;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final diamond = Transform.rotate(
      angle: 0.785398, // 45°
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          border: Border.all(color: active ? AppColors.accent : AppColors.inkFaint, width: 1),
          boxShadow: active
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 5)]
              : null,
        ),
      ),
    );

    if (onTap == null) return diamond;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: diamond,
      ),
    );
  }
}
