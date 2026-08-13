import 'package:flutter/material.dart';

import '../../models/news_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/relative_time.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.sourceName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [
                  (item.isFlash ? AppColors.flash : AppColors.accent).withValues(alpha: 0.45),
                  AppColors.surface2,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (item.isFlash)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('EILMELDUNG', style: AppTypography.mono(size: 11, weight: FontWeight.w600, color: AppColors.flash)),
            ),
          Text(item.title, style: AppTypography.body(size: 20, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${item.sourceName} · ${relativeTime(item.publishedAt)}',
              style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 16),
          Text(item.summary, style: AppTypography.body(size: 14, color: AppColors.inkMuted).copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
