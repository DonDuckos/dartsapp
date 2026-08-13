import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'user_doc_provider.dart';

/// Hält die favorisierten Spieler-IDs. Angemeldet: synchronisiert mit
/// users/{uid}.favoritePlayerIds in Firestore (geräteübergreifend). Ohne
/// Anmeldung: nur lokal für die aktuelle Session, damit die App auch als
/// Gast benutzbar bleibt.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const {};

    final ids = ref.watch(userDocProvider(user.uid)).value?['favoritePlayerIds'] as List<dynamic>?;
    return ids == null ? const {} : Set<String>.from(ids);
  }

  Future<void> toggle(String playerId) async {
    final next = {...state};
    if (!next.remove(playerId)) {
      next.add(playerId);
    }
    state = next;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'favoritePlayerIds': next.toList()},
      SetOptions(merge: true),
    );
  }

  bool isFavorite(String playerId) => state.contains(playerId);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
