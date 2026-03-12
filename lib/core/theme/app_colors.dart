import 'package:flutter/material.dart';

class SamsungColors {
  SamsungColors._();

  // ─── Dark Theme ───────────────────────────────────────────
  static const darkBackground = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);
  static const darkDivider = Color(0xFF3A3A3C);
  static const darkAppBar = Color(0xFF0A0A0A);
  static const darkBottomNav = Color(0xFF1C1C1E);

  // ─── Light Theme ──────────────────────────────────────────
  static const lightBackground = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE5E5EA);
  static const lightAppBar = Color(0xFFF2F2F7);
  static const lightBottomNav = Color(0xFFFFFFFF);

  // ─── Accent (Samsung Blue) ────────────────────────────────
  static const primary = Color(0xFF4FC3F7);
  static const primaryDark = Color(0xFF0288D1);
  static const primaryLight = Color(0xFF81D4FA);
  static const accent = Color(0xFF4FC3F7);

  // ─── Status Colors ────────────────────────────────────────
  static const favorite = Color(0xFFFF3B30);
  static const favoriteBg = Color(0x1AFF3B30);
  static const selected = Color(0xFF4FC3F7);
  static const selectedBg = Color(0x1A4FC3F7);
  static const selectedBorder = Color(0xFF4FC3F7);
  static const deleteRed = Color(0xFFFF3B30);
  static const shareGreen = Color(0xFF34C759);

  // ─── Text ─────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFF8E8E93);
  static const textTertiaryDark = Color(0xFF48484A);
  static const textPrimaryLight = Color(0xFF000000);
  static const textSecondaryLight = Color(0xFF6C6C70);
  static const textTertiaryLight = Color(0xFFAEAEB2);

  // ─── Overlay ──────────────────────────────────────────────
  static const overlayDark = Color(0x80000000);
  static const overlayLight = Color(0x40000000);
  static const shimmerBase = Color(0xFF2C2C2E);
  static const shimmerHighlight = Color(0xFF3A3A3C);
  static const shimmerBaseLight = Color(0xFFE5E5EA);
  static const shimmerHighlightL = Color(0xFFF2F2F7);



  // ── Backgrounds ─────────────────────────────────────────
  static const background   = Color(0xFF000000); // pure black canvas
  static const surface      = Color(0xFF1C1C1E); // card / sheet background
  static const surfaceAlt   = Color(0xFF2C2C2E); // slightly lighter surface
  static const navBar       = Color(0xFF141414); // bottom nav

  // ── Accent ──────────────────────────────────────────────
  static const accentLight  = Color(0xFF5BA3FF); // lighter variant

  // ── Text ────────────────────────────────────────────────
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary= Color(0xFFAAAAAA);
  static const textTertiary = Color(0xFF666666);

  // ── States ──────────────────────────────────────────────
  static const danger       = Color(0xFFFF453A); // delete / error red

  // ── Misc ────────────────────────────────────────────────
  static const divider      = Color(0xFF2C2C2E);
  static const shimmerHigh  = Color(0xFF2A2A2A);
  static const videoOverlay = Color(0x88000000);
  static const locationPin  = Color(0xFF3B8BFF);


  // ─── Gradient ─────────────────────────────────────────────
  static const gradientBlackTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC000000), Colors.transparent],
  );

  static const gradientBlackBottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xCC000000), Colors.transparent],
  );
}
