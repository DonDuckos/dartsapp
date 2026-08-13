import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/news_item.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/relative_time.dart';
import '../../widgets/favorite_diamond.dart';
import 'news_detail_screen.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  bool onlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final news = ref.watch(newsProvider).value;
    final favorites = ref.watch(favoritesProvider);

    if (news == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    final visible = onlyFavorites
        ? news.where((n) => n.relatedPlayerIds.any(favorites.contains)).toList()
        : news;

    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Nur Favoriten'),
                selected: onlyFavorites,
                onSelected: (v) => setState(() => onlyFavorites = v),
                labelStyle: AppTypography.mono(size: 11, color: onlyFavorites ? AppColors.bg : AppColors.inkMuted),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.accent,
                side: const BorderSide(color: AppColors.hairline),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(height: 20, color: AppColors.hairline),
              itemBuilder: (context, index) {
                final item = visible[index];
                final isFavoriteRelated = item.relatedPlayerIds.any(favorites.contains);
                return _NewsRow(item: item, highlighted: isFavoriteRelated);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.item, required this.highlighted});

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
                    Text('${item.sourceName} · ${relativeTime(item.publishedAt)}',
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
