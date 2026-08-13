import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// App ist bewusst dark-first (siehe CLAUDE.md) — es gibt aktuell kein
/// separates Hell-Theme, da die gesamte Bildsprache (Glow, Kontraste) auf
/// dem dunklen Grund aufbaut.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      error: AppColors.flash,
      onSurface: AppColors.ink,
      onPrimary: AppColors.bg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(Brightness.dark),
      dividerColor: AppColors.hairline,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.body(size: 16, weight: FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bg,
        indicatorColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return AppTypography.mono(
            size: 10.5,
            color: active ? AppColors.ink : AppColors.inkFaint,
          );
        }),
      ),
    );
  }
}
