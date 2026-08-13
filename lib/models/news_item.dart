import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceUrl,
    required this.sourceName,
    required this.publishedAt,
    required this.relatedPlayerIds,
    required this.isFlash,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String summary;
  final String sourceUrl;
  final String sourceName;
  final DateTime publishedAt;
  final List<String> relatedPlayerIds;
  final bool isFlash;
  final String? imageUrl;

  factory NewsItem.fromMap(String id, Map<String, dynamic> map) {
    return NewsItem(
      id: id,
      title: map['title'] as String,
      summary: map['summary'] as String,
      sourceUrl: map['sourceUrl'] as String,
      sourceName: map['sourceName'] as String,
      publishedAt: (map['publishedAt'] as Timestamp).toDate(),
      relatedPlayerIds: List<String>.from(map['relatedPlayerIds'] as List? ?? const []),
      isFlash: map['isFlash'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
