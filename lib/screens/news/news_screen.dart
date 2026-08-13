import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/news_row.dart';

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
            child: visible.isEmpty
                ? Center(
                    child: Text('Noch keine News.', style: AppTypography.body(size: 13, color: AppColors.inkFaint)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 20, color: AppColors.hairline),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final isFavoriteRelated = item.relatedPlayerIds.any(favorites.contains);
                      return NewsRow(item: item, highlighted: isFavoriteRelated);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
