import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.size = 6});

  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = reduceMotion ? 0.0 : _controller.value * 4;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.live,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.live.withValues(alpha: 0.55), blurRadius: 2 + glow, spreadRadius: glow * 0.3),
            ],
          ),
        );
      },
    );
  }
}

class LiveLabel extends StatelessWidget {
  const LiveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiveDot(),
        const SizedBox(width: 6),
        Text('LIVE', style: AppTypography.mono(size: 11, weight: FontWeight.w600, color: AppColors.live)),
      ],
    );
  }
}
