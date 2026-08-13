import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/player.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, _) => Center(
          child: Text('Fehler beim Laden: $error', style: AppTypography.body(size: 13, color: AppColors.inkMuted)),
        ),
        data: (user) => user == null ? const _SignedOutView() : const _SignedInView(),
      ),
    );
  }
}

class _SignedOutView extends StatefulWidget {
  const _SignedOutView();

  @override
  State<_SignedOutView> createState() => _SignedOutViewState();
}

class _SignedOutViewState extends State<_SignedOutView> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anmeldung fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Noch nicht angemeldet', style: AppTypography.body(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Melde dich mit Google an, um Lieblingsspieler und Benachrichtigungen geräteübergreifend zu speichern.',
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _loading ? null : _signIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg),
                          )
                        : Text('Mit Google anmelden',
                            style: AppTypography.body(size: 14, weight: FontWeight.w600, color: AppColors.bg)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedInView extends ConsumerWidget {
  const _SignedInView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value!;
    final players = ref.watch(rankedPlayersProvider).value ?? const [];
    final favorites = ref.watch(favoritesProvider);
    final settings = ref.watch(notificationSettingsProvider);
    final playerById = {for (final p in players) p.id: p};
    final favoritePlayers = favorites.map((id) => playerById[id]).whereType<Player>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surface2,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? Text((user.displayName ?? user.email ?? '?').substring(0, 1).toUpperCase(),
                      style: AppTypography.body(size: 16, weight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? 'Ohne Namen', style: AppTypography.body(size: 15, weight: FontWeight.w600)),
                  Text(user.email ?? '', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => AuthService.instance.signOut(),
              child: Text('Abmelden', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('FAVORITEN', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
        if (favoritePlayers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Noch keine Favoriten — in der Rangliste markieren.',
                style: AppTypography.body(size: 12, color: AppColors.inkFaint)),
          )
        else
          for (final p in favoritePlayers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name, style: AppTypography.body(size: 14)),
              trailing: TextButton(
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(p.id),
                child: Text('entfernen', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
              ),
            ),
        const SizedBox(height: 20),
        Text('BENACHRICHTIGUNGEN', style: AppTypography.mono(size: 11, color: AppColors.inkFaint)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Bei Spielstart eines Favoriten', style: AppTypography.body(size: 13)),
          value: settings.favoriteMatchStart,
          activeThumbColor: AppColors.accent,
          onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setFavoriteMatchStart(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Täglicher News-Digest', style: AppTypography.body(size: 13)),
          value: settings.dailyDigest,
          activeThumbColor: AppColors.accent,
          onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setDailyDigest(v),
        ),
      ],
    );
  }
}
