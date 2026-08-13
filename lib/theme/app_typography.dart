import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Drei Rollen, wie im freigegebenen Mockup: eine kondensierte Display-Schrift
/// für Score-Zahlen, eine humanistische Grundschrift für Fließtext und eine
/// Monospace-Schrift für Daten (Stats, Zeitstempel, Tabellenwerte).
class AppTypography {
  const AppTypography._();

  static TextStyle display({double size = 34, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.oswald(fontSize: size, fontWeight: weight, color: AppColors.ink, height: 1.0);

  static TextStyle body({double size = 15, FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.workSans(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);

  static TextStyle mono({double size = 12, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.4,
        color: color ?? AppColors.inkFaint,
      );

  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.workSansTextTheme();
    return base.copyWith(
      headlineMedium: display(size: 26),
      titleLarge: body(size: 18, weight: FontWeight.w600),
      titleMedium: body(size: 15, weight: FontWeight.w600),
      bodyLarge: body(size: 15),
      bodyMedium: body(size: 13, color: AppColors.inkMuted),
      labelSmall: mono(size: 11),
    );
  }
}
