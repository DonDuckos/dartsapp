import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/relative_time.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.item});

  final NewsItem item;

  Future<void> _openSource(BuildContext context) async {
    final uri = Uri.tryParse(item.sourceUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quelle konnte nicht geöffnet werden.')),
      );
    }
  }

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
          Text('${item.sourceName} · ${newsDate(item.publishedAt)}',
              style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 16),
          Text(item.summary, style: AppTypography.body(size: 14, color: AppColors.inkMuted).copyWith(height: 1.5)),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _openSource(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.sourceUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(size: 11, color: AppColors.accent)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new, size: 14, color: AppColors.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
