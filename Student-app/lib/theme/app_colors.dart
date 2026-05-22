import 'package:flutter/material.dart';

/// Premium color palette for the Library Student App
/// Light mode uses lemon yellow accent, dark mode uses golden yellow
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // LIGHT MODE COLORS
  // ============================================================================

  /// Pure white background
  static const Color lightBackground = Color(0xFFFFFFFF);

  /// Off-white surface with subtle gray undertones
  static const Color lightSurface = Color(0xFFF8F9FA);

  /// Lemon yellow accent - used sparingly for CTAs and highlights
  static const Color lightAccent = Color(0xFFFFE55C);

  /// Dark gray for primary text (easier on eyes than pure black)
  static const Color lightTextPrimary = Color(0xFF1E1E1E);

  /// Medium gray for secondary text
  static const Color lightTextSecondary = Color(0xFF6C757D);

  /// Very light gray for borders and outlines
  static const Color lightBorder = Color(0xFFE9ECEF);

  /// Off-white for search bar background
  static const Color lightSearchBackground = Color(0xFFF5F7FA);

  // ============================================================================
  // DARK MODE COLORS
  // ============================================================================

  /// Rich dark gray background (NOT pure black)
  static const Color darkBackground = Color(0xFF1A1E24);

  /// Slightly lighter gray for surfaces
  static const Color darkSurface = Color(0xFF2C3138);

  /// Golden yellow accent - warmer than light mode
  static const Color darkAccent = Color(0xFFFDB827);

  /// Off-white for primary text
  static const Color darkTextPrimary = Color(0xFFF8F9FA);

  /// Light gray for secondary text
  static const Color darkTextSecondary = Color(0xFFADB5BD);

  /// Subtle gray borders
  static const Color darkBorder = Color(0xFF3A4047);

  /// Surface gray for search bar
  static const Color darkSearchBackground = Color(0xFF2C3138);

  // ============================================================================
  // SEMANTIC COLORS (consistent across themes)
  // ============================================================================

  /// Success color (e.g., available books, completed status)
  static const Color success = Color(0xFF28A745);

  /// Warning color (e.g., due soon, pending status)
  static const Color warning = Color(0xFFFFC107);

  /// Error color (e.g., overdue, rejected status)
  static const Color error = Color(0xFFDC3545);

  /// Info color (e.g., notifications, info badges)
  static const Color info = Color(0xFF17A2B8);

  /// Heart/favorite color (consistent red)
  static const Color favorite = Color(0xFFE74C3C);

  // ============================================================================
  // CONNECTIVITY COLORS
  // ============================================================================

  /// Online status - WiFi icon color
  static const Color onlineGreen = Color(0xFF28A745);

  /// Offline status - Globe icon color (amber/yellow)
  static const Color offlineAmber = Color(0xFFFFC107);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get accent color based on brightness
  static Color getAccentColor(Brightness brightness) {
    return brightness == Brightness.light ? lightAccent : darkAccent;
  }

  /// Get primary text color based on brightness
  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.light ? lightTextPrimary : darkTextPrimary;
  }

  /// Get secondary text color based on brightness
  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.light
        ? lightTextSecondary
        : darkTextSecondary;
  }

  /// Get surface color based on brightness
  static Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light ? lightSurface : darkSurface;
  }

  /// Alias for getSurfaceColor to match usage
  static Color surface(Brightness brightness) {
    return getSurfaceColor(brightness);
  }

  /// Get background color based on context theme
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightBackground
        : darkBackground;
  }

  /// Get border color based on brightness
  static Color getBorderColor(Brightness brightness) {
    return brightness == Brightness.light ? lightBorder : darkBorder;
  }
}
