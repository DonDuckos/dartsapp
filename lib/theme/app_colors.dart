import 'package:flutter/material.dart';

/// Farbtokens gemäß CLAUDE.md — dunkles, warmes Anthrazit als Basis,
/// Messing-Gold als einziger Marken-Akzent, Grün/Rot rein semantisch
/// (Live-Status / Eilmeldung), nie als Marken-Akzent verwendet.
class AppColors {
  const AppColors._();

  static const bg = Color(0xFF15130E);
  static const surface = Color(0xFF1F1C15);
  static const surface2 = Color(0xFF262218);
  static const hairline = Color(0x29C9A24A); // accent bei 16% Deckkraft

  static const accent = Color(0xFFC9A24A);
  static const live = Color(0xFF5FAE82);
  static const flash = Color(0xFFCD7457);

  static const ink = Color(0xFFF3EDE0);
  static const inkMuted = Color(0xFFB3A78E);
  static const inkFaint = Color(0xFF7D745F);
}
