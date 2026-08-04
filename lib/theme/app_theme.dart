import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TchakaTheme {
  TchakaTheme._();

  static const Color background = Color(0xFF080808);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  static const Color primary = Color(0xFFFFC107);
  static const Color primaryBright = Color(0xFFFFD54F);

  static const Color textPrimary = Color(0xFFF8F8F8);
  static const Color textSecondary = Color(0xFFB8B8B8);

  static ThemeData dark() {
    final base = ThemeData.dark(
      useMaterial3: true,
    );

    final colorScheme = ColorScheme.dark(
      surface: surface,
      primary: primary,
      secondary: primaryBright,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      error: const Color(0xFFFF5252),
      onError: Colors.white,
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      brightness: Brightness.dark,

      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF262626),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,

        hintStyle: const TextStyle(
          color: textSecondary,
        ),

        prefixIconColor: textSecondary,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: primary,
          side: const BorderSide(
            color: primary,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceElevated,
        selectedColor: primary,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide.none,
      ),

      iconTheme: const IconThemeData(
        color: textPrimary,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(
          alpha: 0.18,
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
