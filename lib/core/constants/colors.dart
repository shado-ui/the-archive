import 'package:flutter/material.dart';

enum AppTheme {
  cosmicDark,
  midnightBlue,
  sunsetGlow,
  forestGreen,
  oceanDepth,
}

class AppColors {
  // Cosmic Dark Theme (Default)
  static const Color spaceDark = Color(0xFF0F0C20);
  static const Color nebulaViolet = Color(0xFF15102A);
  static const Color deepSpace = Color(0xFF090714);
  
  // Midnight Blue Theme
  static const Color midnightBg = Color(0xFF0A192F);
  static const Color midnightSurface = Color(0xFF112240);
  static const Color midnightAccent = Color(0xFF64FFDA);
  
  // Sunset Glow Theme
  static const Color sunsetBg = Color(0xFF2D1B2E);
  static const Color sunsetSurface = Color(0xFF3D2B3E);
  static const Color sunsetAccent = Color(0xFFFF6B6B);
  
  // Forest Green Theme
  static const Color forestBg = Color(0xFF1A2F1A);
  static const Color forestSurface = Color(0xFF2A4F2A);
  static const Color forestAccent = Color(0xFF4ADE80);
  
  // Ocean Depth Theme
  static const Color oceanBg = Color(0xFF0C2340);
  static const Color oceanSurface = Color(0xFF1A3A5C);
  static const Color oceanAccent = Color(0xFF38BDF8);
  
  // Glassmorphic Elements (High-End Translucency)
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color cardBg = Color(0x0DFFFFFF);
  
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlassBg = Color(0x80000000);
  static const Color lightGlassBorder = Color(0x40000000);
  
  // Neon Accents
  static const Color roseSpark = Color(0xFFFF4D80);     // Primary focus color for memories and love
  static const Color goldAccent = Color(0xFFFFD700);     // Alerts, countdowns
  static const Color auroraCyan = Color(0xFF00E5FF);     // Cycles, vault security
  static const Color violetAccent = Color(0xFF8A2BE2);   // Secondary elements
  
  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0AEC6);
  static const Color textMuted = Color(0xFF6B6A80);
  
  // Light Mode Typography
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF4A4A4A);
  static const Color lightTextMuted = Color(0xFF808080);
  
  // Status Colors
  static const Color errorRed = Color(0xFFFF5252);
  static const Color successGreen = Color(0xFF00E676);
  
  // Get theme colors based on selected theme and mode
  static Color getBackground(AppTheme theme, bool isDark) {
    if (!isDark) return lightBg;
    switch (theme) {
      case AppTheme.cosmicDark:
        return spaceDark;
      case AppTheme.midnightBlue:
        return midnightBg;
      case AppTheme.sunsetGlow:
        return sunsetBg;
      case AppTheme.forestGreen:
        return forestBg;
      case AppTheme.oceanDepth:
        return oceanBg;
    }
  }
  
  static Color getSurface(AppTheme theme, bool isDark) {
    if (!isDark) return lightSurface;
    switch (theme) {
      case AppTheme.cosmicDark:
        return nebulaViolet;
      case AppTheme.midnightBlue:
        return midnightSurface;
      case AppTheme.sunsetGlow:
        return sunsetSurface;
      case AppTheme.forestGreen:
        return forestSurface;
      case AppTheme.oceanDepth:
        return oceanSurface;
    }
  }
  
  static Color getAccent(AppTheme theme) {
    switch (theme) {
      case AppTheme.cosmicDark:
        return auroraCyan;
      case AppTheme.midnightBlue:
        return midnightAccent;
      case AppTheme.sunsetGlow:
        return sunsetAccent;
      case AppTheme.forestGreen:
        return forestAccent;
      case AppTheme.oceanDepth:
        return oceanAccent;
    }
  }
  
  static Color getGlassBg(bool isDark) {
    return isDark ? glassBg : lightGlassBg;
  }
  
  static Color getGlassBorder(bool isDark) {
    return isDark ? glassBorder : lightGlassBorder;
  }
  
  static Color getTextPrimary(bool isDark) {
    return isDark ? textPrimary : lightTextPrimary;
  }
  
  static Color getTextSecondary(bool isDark) {
    return isDark ? textSecondary : lightTextSecondary;
  }
  
  static Color getTextMuted(bool isDark) {
    return isDark ? textMuted : lightTextMuted;
  }
}
