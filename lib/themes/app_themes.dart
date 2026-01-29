import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF1976D2);
  static const Color lightSecondary = Color(0xFF03DAC6);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static final Color lightScaffold = Colors.blueGrey[100]!;
  static const Color lightAppBar = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF212121);
  static const Color lightSubText = Color(0xFF757575);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF1976D2);
  static const Color darkSecondary = Color(0xFF03DAC6);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkScaffold = Color(0xFF0E1116);
  static const Color darkAppBar = Color(0xFF1B1F2A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSubText = Color(0xFFB0B0B0);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkDivider = Color(0xFF424242);

  // Chart Colors - Light Theme
  static const Color lightChartLine = Color(0xFF1976D2);
  static const Color lightChartGridLine = Color(0xFFE0E0E0);
  static const Color lightChartBackground = Color(0xFFFAFAFA);

  // Chart Colors - Dark Theme
  static const Color darkChartLine = Color(0xFF64B5F6);
  static const Color darkChartGridLine = Color(0xFF424242);
  static const Color darkChartBackground = Color(0xFF0E1116);

  // Light Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightAppBar,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: lightText),
    ),
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightCardBackground,
      error: Color(0xFFB00020),
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      color: lightCardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightText),
      bodyMedium: TextStyle(color: lightText),
      bodySmall: TextStyle(color: lightSubText),
      headlineSmall: TextStyle(color: lightText, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: lightText),
    ),
    dividerColor: lightDivider,
    iconTheme: const IconThemeData(color: lightText),
    primaryTextTheme: TextTheme(
      bodySmall: TextStyle(color: lightText, fontSize: 12),
      bodyMedium: TextStyle(color: lightText, fontSize: 20),
      bodyLarge: TextStyle(color: lightText, fontSize: 36),
    ),
  );

  // Dark Theme Data
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkAppBar,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: darkText),
    ),
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkCardBackground,
      error: Color(0xFFCF6679),
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      color: darkCardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkText),
      bodyMedium: TextStyle(color: darkText),
      bodySmall: TextStyle(color: darkSubText),
      headlineSmall: TextStyle(color: darkText, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: darkText),
    ),
    dividerColor: darkDivider,
    iconTheme: const IconThemeData(color: darkText),
    primaryTextTheme: TextTheme(
      bodySmall: TextStyle(color: darkText, fontSize: 12),
      bodyMedium: TextStyle(color: darkText, fontSize: 20),
      bodyLarge: TextStyle(color: darkText, fontSize: 36),
    ),
  );
}
