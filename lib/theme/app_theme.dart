import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF6c1d45);
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryRed = Color(0xFFFF3B30);
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color primaryOrange = Color(0xFFFF9500);
  static const Color primaryPurple = Color(0xFF9B30FF);
  
  // Background colors
  static const Color backgroundColor = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Color(0xFFF2F2F7);
  
  // Text colors
  static const Color primaryTextColor = Color(0xFF000000);
  static const Color secondaryTextColor = Color(0xFF6D6D80);
  static const Color placeholderTextColor = Color(0xFF999999);
  
  // Border colors
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color focusedBorderColor = primaryColor;
  
  // Income/Expense colors
  static const Color incomeColor = primaryGreen;
  static const Color expenseColor = primaryRed;
  
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkPrimaryTextColor = Color(0xFFFFFFFF);
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
  static const Color darkBorderColor = Color(0xFF2E2E2E);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: focusedBorderColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryTextColor,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: primaryTextColor),
      bodyMedium: TextStyle(color: secondaryTextColor),
      titleLarge: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: darkSurfaceColor,
      contentTextStyle: TextStyle(color: darkPrimaryTextColor),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryBlue,
      surface: darkSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkPrimaryTextColor,
    ).copyWith(surface: darkSurfaceColor),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: darkSurfaceColor,
      contentTextStyle: TextStyle(color: darkPrimaryTextColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: focusedBorderColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkPrimaryTextColor),
      bodyMedium: TextStyle(color: darkSecondaryTextColor),
      titleLarge: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold),
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      barBackgroundColor: darkSurfaceColor,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(color: darkPrimaryTextColor),
      ),
    ),
  );

  // Cupertino TextField Decoration
  static BoxDecoration get cupertinoTextFieldDecoration {
    return BoxDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor, width: 1.5),
    );
  }

  static BoxDecoration get focusedCupertinoTextFieldDecoration {
    return BoxDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.primaryColor, width: 2.0),
    );
  }
} 