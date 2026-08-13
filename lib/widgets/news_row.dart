import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../screens/news/news_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/relative_time.dart';
import 'favorite_diamond.dart';

class NewsRow extends StatelessWidget {
  const NewsRow({super.key, required this.item, required this.highlighted});

  final NewsItem item;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [
                  (item.isFlash ? AppColors.flash : AppColors.accent).withValues(alpha: 0.4),
                  AppColors.surface2,
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isFlash)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('EILMELDUNG',
                        style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: AppColors.flash)),
                  ),
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(size: 13, weight: item.isFlash ? FontWeight.w600 : FontWeight.w400)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (highlighted) ...[const FavoriteDiamond(active: true, size: 5), const SizedBox(width: 5)],
                    Text('${item.sourceName} · ${newsDate(item.publishedAt)}',
                        style: AppTypography.mono(size: 10, color: AppColors.inkFaint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
