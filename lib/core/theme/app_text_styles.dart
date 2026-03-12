import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {

  // Heading
  static TextStyle headingLarge({Color? color}) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  static TextStyle headingMedium({Color? color}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  static TextStyle headingSmall({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  // Body
  static TextStyle bodyLarge({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  static TextStyle bodyMedium({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  static TextStyle bodySmall({Color? color}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? SamsungColors.textSecondaryDark,
    );
  }

  // Label
  static TextStyle label({Color? color}) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: color ?? SamsungColors.textSecondaryDark,
    );
  }

  // Caption
  static TextStyle caption({Color? color}) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: color ?? SamsungColors.textSecondaryDark,
    );
  }

  // Button
  static TextStyle button({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
    );
  }

  static TextStyle appBarTitle({Color? color}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  static TextStyle dateSectionHeader({Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? SamsungColors.textSecondaryDark,
    );
  }

  static TextStyle displayMedium({Color? color}) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }

  static TextStyle displayLarge({Color? color}) {
    return TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: color ?? SamsungColors.textPrimaryDark,
    );
  }
}