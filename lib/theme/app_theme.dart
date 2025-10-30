import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const cherryRed = Color(0xFFB5121B);
  static const deepBlue = Color(0xFF202A44);
  static const neonYellow = Color(0xFFDFFF00);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: deepBlue,
    primary: deepBlue,
    secondary: cherryRed,
    tertiary: neonYellow,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: deepBlue,
    primary: deepBlue,
    secondary: cherryRed,
    tertiary: neonYellow,
    brightness: Brightness.dark,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        textTheme: GoogleFonts.robotoTextTheme(),
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

  static Color statusColor(int risk) {
    if (risk >= 70) return cherryRed;
    if (risk >= 40) return Colors.amber.shade700;
    return Colors.green.shade700;
  }

  static String statusText(int risk) {
    if (risk >= 70) return 'DANGER';
    if (risk >= 40) return 'CAUTION';
    return 'SAFE';
  }
}
