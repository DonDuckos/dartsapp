import '../models/news_item.dart';

abstract class NewsRepository {
  Stream<List<NewsItem>> watchNews();
}
