import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rohes users/{uid}-Dokument (Favoriten + Benachrichtigungseinstellungen,
/// siehe CLAUDE.md Datenmodell). Ein gemeinsamer Stream, aus dem
/// FavoritesNotifier und NotificationSettingsNotifier jeweils ihren Teil lesen.
final userDocProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((doc) => doc.data());
});
