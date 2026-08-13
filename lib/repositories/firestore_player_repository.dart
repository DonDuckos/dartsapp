import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import 'player_repository.dart';

class FirestorePlayerRepository implements PlayerRepository {
  FirestorePlayerRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<Player>> watchRankedPlayers() {
    return _db.collection('players').orderBy('rankingPosition').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Player.fromMap(doc.id, doc.data())).toList(),
        );
  }
}
