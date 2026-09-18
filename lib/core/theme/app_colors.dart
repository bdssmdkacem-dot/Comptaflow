import 'package:flutter/material.dart';

/// ComptaFlow design tokens. Keep visual decisions centralized.
abstract final class AppColors {
  static const primary = Color(0xFF0B6B5B);
  static const primaryDark = Color(0xFF075447);
  static const accent = Color(0xFF14B8A6);
  static const deep = Color(0xFF0E2A2A);

  static const background = Color(0xFF071B1B);
  static const surface = Color(0xFF102A29);
  static const surfaceElevated = Color(0xFF163634);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFA7B8B5);
  static const border = Color(0x1FFFFFFF);

  static const success = Color(0xFF36B37E);
  static const warning = Color(0xFFE2A93B);
  static const error = Color(0xFFE05A5A);

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double contentMaxWidth = 1180;
}
