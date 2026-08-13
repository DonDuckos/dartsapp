import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'auth_provider.dart';
import 'user_doc_provider.dart';

const _defaultSettings = NotificationSettings(favoriteMatchStart: true, dailyDigest: false);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return _defaultSettings;

    final data = ref.watch(userDocProvider(user.uid)).value?['notificationSettings'] as Map<String, dynamic>?;
    if (data == null) return _defaultSettings;
    return NotificationSettings(
      favoriteMatchStart: data['favoriteMatchStart'] as bool? ?? _defaultSettings.favoriteMatchStart,
      dailyDigest: data['dailyDigest'] as bool? ?? _defaultSettings.dailyDigest,
    );
  }

  Future<void> setFavoriteMatchStart(bool value) => _update(state.copyWith(favoriteMatchStart: value));

  Future<void> setDailyDigest(bool value) => _update(state.copyWith(dailyDigest: value));

  Future<void> _update(NotificationSettings next) async {
    state = next;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'notificationSettings': {
          'favoriteMatchStart': next.favoriteMatchStart,
          'dailyDigest': next.dailyDigest,
        },
      },
      SetOptions(merge: true),
    );
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
