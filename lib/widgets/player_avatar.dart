import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rundes Spielerfoto mit Gold-Verlauf-Fallback — sowohl wenn kein Foto
/// hinterlegt ist, als auch wenn das Laden fehlschlägt (z.B. kurzzeitiger
/// Netzwerkfehler bei Wikimedia), statt Flutters Standard-Fehlersymbol.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.photoUrl, required this.size});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface2),
      child: photoUrl == null
          ? const _GradientFallback()
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : const _GradientFallback(),
              errorBuilder: (context, error, stackTrace) => const _GradientFallback(),
            ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.accent, Color(0xFF7A5A1E)]),
      ),
    );
  }
}
