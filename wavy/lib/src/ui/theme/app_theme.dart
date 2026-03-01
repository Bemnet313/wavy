import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WavyTheme {
  // ─── Design Tokens ────────────────────────────────────────
  // Primary palette (Ultra-Dark Minimal Aesthetic)
  static const Color primary = Color(0xFFFFFFFF);       // White for primary actions
  static const Color primaryLight = Color(0xFFFAFAFA);  // Near white
  static const Color primaryDark = Color(0xFF111111);   // Deep surface
  
  // Minimal Accents (Subtle Glows)
  static const Color accentGlow = Color(0xFF007FFF);    // Very soft blue glow
  static const Color accentBorder = Color(0xFF262626);  // Subtle divider
  
  // Surfaces
  static const Color backgroundDark = Color(0xFF000000); // True Black
  static const Color backgroundLight = Color(0xFFFAFAFA); // For Light Theme
  static const Color surfaceDark = Color(0xFF0A0A0A);    // Secondary Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);   // For Light Theme
  static const Color surfaceElevated = Color(0xFF111111); // Tertiary Surface
  
  // Text
  static const Color textDarkPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textDarkSecondary = Color(0xFFA1A1AA); // Soft Gray
  static const Color textPrimary = Color(0xFF111111);     // For Light Theme
  static const Color textSecondary = Color(0xFF71717A);   // For Light Theme
  static const Color textOnPrimary = Color(0xFF000000);   // For Light Theme
  
  // Utility Colors
  static const Color error = Color(0xFFEF4444);
  static const Color ultraDark = Color(0xFF000000);
  
  // Legacy Tokens (Keep as placeholders for stability)
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color neonCyan = Color(0xFF00FFFF);

  // Effects & Glass
  static const Color glassWhite = Color(0x10FFFFFF);
  static const Color glassDark = Color(0x40000000);
  static const Color minimalGlow = Color(0x20007FFF);

  // ─── Spacing ───────────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  // ─── Border Radius ─────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ─── Light Theme ──────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: neonMagenta,
        surface: surfaceLight,
        error: error,
        onPrimary: textOnPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: _textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 12,
        shadowColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accentBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accentBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.spaceGrotesk(color: textDarkSecondary).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accentGlow,
        surface: surfaceDark,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textDarkPrimary,
      ),
      textTheme: _textTheme(textDarkPrimary, textDarkSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: textDarkPrimary,
          letterSpacing: 1.5,
        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        iconTheme: const IconThemeData(color: textDarkPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundDark,
        indicatorColor: Colors.white.withValues(alpha: 0.05),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.spaceGrotesk(
            fontSize: 10, 
            fontWeight: FontWeight.w800,
            color: textDarkSecondary,
            letterSpacing: 1,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // More angular
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: accentBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accentBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accentBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.spaceGrotesk(color: textDarkSecondary).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
      ),
    );
  }

  // ─── Typography ─────────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary) {
    const fallback = ['Noto Sans Ethiopic'];
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -1.0,
      ).copyWith(fontFamilyFallback: fallback),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
      ).copyWith(fontFamilyFallback: fallback),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: primary,
      ).copyWith(fontFamilyFallback: fallback),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ).copyWith(fontFamilyFallback: fallback),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ).copyWith(fontFamilyFallback: fallback),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ).copyWith(fontFamilyFallback: fallback),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ).copyWith(fontFamilyFallback: fallback),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ).copyWith(fontFamilyFallback: fallback),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: 0.5,
      ).copyWith(fontFamilyFallback: fallback),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.5,
      ).copyWith(fontFamilyFallback: fallback),
    );
  }
}

// ─── Glassy Container Decoration ──────────────────────────
class GlassDecoration {
  static BoxDecoration light({double opacity = 0.6}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(WavyTheme.radiusLg),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: WavyTheme.primary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration dark({double opacity = 0.05}) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(WavyTheme.radiusSm),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.05),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.02),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
