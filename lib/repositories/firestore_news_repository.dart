import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_item.dart';
import 'news_repository.dart';

class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<NewsItem>> watchNews() {
    return _db
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NewsItem.fromMap(doc.id, doc.data())).toList());
  }
}
