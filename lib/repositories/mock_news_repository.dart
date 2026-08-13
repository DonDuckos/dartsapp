import '../data/fixtures.dart';
import '../models/news_item.dart';
import 'news_repository.dart';

class MockNewsRepository implements NewsRepository {
  @override
  Stream<List<NewsItem>> watchNews() {
    final items = List<NewsItem>.from(Fixtures.newsItems)
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return Stream.value(items);
  }
}
