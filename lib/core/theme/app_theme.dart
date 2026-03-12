import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ─── Dark Theme ───────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SamsungColors.darkBackground,

      // ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: SamsungColors.primary,
        secondary: SamsungColors.primary,
        surface: SamsungColors.darkSurface,
        background: SamsungColors.darkBackground,
        error: SamsungColors.deleteRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: SamsungColors.textPrimaryDark,
        onBackground: SamsungColors.textPrimaryDark,
        onError: Colors.white,
      ),

      // Typography
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: AppTextStyles.displayLarge(),
            displayMedium: AppTextStyles.displayMedium(),
            headlineLarge: AppTextStyles.headingLarge(),
            headlineMedium: AppTextStyles.headingMedium(),
            headlineSmall: AppTextStyles.headingSmall(),
            bodyLarge: AppTextStyles.bodyLarge(),
            bodyMedium: AppTextStyles.bodyMedium(),
            bodySmall: AppTextStyles.bodySmall(),
            labelSmall: AppTextStyles.caption(),
            labelMedium: AppTextStyles.label(),
          ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: SamsungColors.darkAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appBarTitle(),
        iconTheme: const IconThemeData(
          color: SamsungColors.textPrimaryDark,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: SamsungColors.textPrimaryDark,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: SamsungColors.darkBottomNav,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SamsungColors.darkBottomNav,
        selectedItemColor: SamsungColors.primary,
        unselectedItemColor: SamsungColors.textSecondaryDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: SamsungColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // IconButton
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: SamsungColors.textPrimaryDark),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: SamsungColors.darkDivider,
        thickness: 0.5,
        space: 0,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SamsungColors.darkSurface,
        modalBackgroundColor: SamsungColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        showDragHandle: true,
        dragHandleColor: SamsungColors.darkDivider,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: SamsungColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: AppTextStyles.headingMedium(),
        contentTextStyle: AppTextStyles.bodyMedium(),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SamsungColors.darkCard,
        contentTextStyle: AppTextStyles.bodyMedium(
          color: SamsungColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: SamsungColors.darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppTextStyles.bodyMedium(color: SamsungColors.textPrimaryDark),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return SamsungColors.primary;
          }
          return SamsungColors.textSecondaryDark;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return SamsungColors.primary.withOpacity(0.4);
          }
          return SamsungColors.darkDivider;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: SamsungColors.primary,
        inactiveTrackColor: SamsungColors.darkDivider,
        thumbColor: SamsungColors.primary,
        overlayColor: SamsungColors.primary.withOpacity(0.2),
        trackHeight: 3,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return SamsungColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.black),
        shape: const CircleBorder(),
        side: const BorderSide(color: SamsungColors.textSecondaryDark, width: 2),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: SamsungColors.primary,
        unselectedLabelColor: SamsungColors.textSecondaryDark,
        indicatorColor: SamsungColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.headingSmall(color: SamsungColors.primary),
        unselectedLabelStyle: AppTextStyles.headingSmall(
          color: SamsungColors.textSecondaryDark,
        ),
      ),
    );
  }

  // ─── Light Theme ──────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: SamsungColors.lightBackground,

      colorScheme: const ColorScheme.light(
        primary: SamsungColors.primaryDark,
        secondary: SamsungColors.primaryDark,
        surface: SamsungColors.lightSurface,
        background: SamsungColors.lightBackground,
        error: SamsungColors.deleteRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SamsungColors.textPrimaryLight,
        onBackground: SamsungColors.textPrimaryLight,
        onError: Colors.white,
      ),

      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: AppTextStyles.displayLarge(
              color: SamsungColors.textPrimaryLight,
            ),
            displayMedium: AppTextStyles.displayMedium(
              color: SamsungColors.textPrimaryLight,
            ),
            headlineLarge: AppTextStyles.headingLarge(
              color: SamsungColors.textPrimaryLight,
            ),
            headlineMedium: AppTextStyles.headingMedium(
              color: SamsungColors.textPrimaryLight,
            ),
            headlineSmall: AppTextStyles.headingSmall(
              color: SamsungColors.textPrimaryLight,
            ),
            bodyLarge: AppTextStyles.bodyLarge(
              color: SamsungColors.textPrimaryLight,
            ),
            bodyMedium: AppTextStyles.bodyMedium(
              color: SamsungColors.textSecondaryLight,
            ),
            bodySmall: AppTextStyles.bodySmall(
              color: SamsungColors.textSecondaryLight,
            ),
            labelSmall: AppTextStyles.caption(
              color: SamsungColors.textTertiaryLight,
            ),
            labelMedium: AppTextStyles.label(
              color: SamsungColors.textSecondaryLight,
            ),
          ),

      appBarTheme: AppBarTheme(
        backgroundColor: SamsungColors.lightAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appBarTitle(
          color: SamsungColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(
          color: SamsungColors.textPrimaryLight,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: SamsungColors.lightBottomNav,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SamsungColors.lightBottomNav,
        selectedItemColor: SamsungColors.primaryDark,
        unselectedItemColor: SamsungColors.textSecondaryLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      cardTheme: CardThemeData(
        color: SamsungColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: SamsungColors.lightDivider,
        thickness: 0.5,
        space: 0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SamsungColors.lightSurface,
        modalBackgroundColor: SamsungColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        showDragHandle: true,
        dragHandleColor: SamsungColors.lightDivider,
      ),
    );
  }
}
