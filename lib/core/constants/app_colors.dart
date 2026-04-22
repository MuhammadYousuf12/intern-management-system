import 'package:flutter/material.dart';

// Defines the color palette for the app.
// Build around brand colors - green as primary, amber as accent.
// Use these constants throuhout the app instead of hardcoding hex values.
class AppColors {
  // --- Primary Brand Colors ---
  // Main green used for buttons, active states and highlights
  static const Color primary = Color(0xFF22C55E);
  static const Color primaryDark = Color(0xFF16A34A);

  // --- Accent ---
  // Used for badges, warnings and secondary highlights
  static const Color accent = Color(0xFFF59E0B);

  // --- Light Theme ---
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FC);
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // --- Dark Theme ---
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
}
