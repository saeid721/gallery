import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Force portrait + landscape but lock status bar to dark icons ──────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Boot PreferencesService BEFORE runApp so it is ready for all bindings ─
  // SharedPreferences keys used here: see PreferencesService for full list.
  await Get.putAsync(() => PreferencesService().init());

  runApp(const SamsungGalleryApp());
}

class SamsungGalleryApp extends StatelessWidget {
  const SamsungGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gallery',
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────────────────────────
      themeMode: ThemeMode.dark,
      darkTheme: _buildDarkTheme(),
      theme: _buildDarkTheme(), // fallback

      // ── Routing ───────────────────────────────────────────────────────────
      initialRoute: Routes.home,
      getPages: AppPages.routes,

      // ── Global dependency injection (DatabaseHelper, etc.) ────────────────
      initialBinding: InitialBinding(),

      // ── Transitions ───────────────────────────────────────────────────────
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // ── GetX logging (disable in production) ─────────────────────────────
      enableLog: true,
      logWriterCallback: (text, {isError = false}) {
        // ignore routine logs in release mode
        assert(() {
          debugPrint('[GetX] $text');
          return true;
        }());
      },
    );
  }

  // ── Samsung Gallery Dark Theme ─────────────────────────────────────────────
  ThemeData _buildDarkTheme() {
    const Color background = Color(0xFF0A0A0A);
    const Color surface = Color(0xFF1C1C1E);
    const Color primary = Color(0xFF4FC3F7);
    const Color onPrimary = Color(0xFF000000);
    const Color onBackground = Color(0xFFFFFFFF);
    const Color onSurface = Color(0xFFE5E5E7);
    const Color divider = Color(0xFF2C2C2E);

    final base = ThemeData.dark();

    return base.copyWith(
      useMaterial3: true,

      // ── Color Scheme ──────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: Color(0xFF64D2FF),
        onSecondary: Color(0xFF000000),
        surface: surface,
        onSurface: onSurface,
        error: Color(0xFFFF453A),
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: divider,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: onBackground, size: 24),
        actionsIconTheme: const IconThemeData(color: onBackground, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111111),
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // ── Text ──────────────────────────────────────────────────────────────
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.notoSans(color: onBackground, fontSize: 16),
        bodyMedium: GoogleFonts.notoSans(color: onSurface, fontSize: 14),
        bodySmall: GoogleFonts.notoSans(color: const Color(0xFF8E8E93), fontSize: 12),
        titleLarge: GoogleFonts.notoSans(
          color: onBackground,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.notoSans(
          color: onBackground,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.notoSans(color: const Color(0xFF8E8E93), fontSize: 11),
      ),

      // ── Icon ──────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: onBackground, size: 24),

      // ── Popup / Dialogs ───────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: SamsungColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: AppTextStyles.headingMedium(),
        contentTextStyle: AppTextStyles.bodyMedium(),
      ),
      // ── SnackBar (used by Get.snackbar) ───────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2E),
        contentTextStyle: GoogleFonts.notoSans(color: onBackground, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Slider (for grid column count in Settings) ────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Color(0xFF3A3A3C),
        thumbColor: primary,
        overlayColor: Color(0x334FC3F7),
        valueIndicatorColor: primary,
      ),

      // ── Switch (for showHidden in Settings) ──────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primary : const Color(0xFF8E8E93)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? const Color(0x554FC3F7)
            : const Color(0xFF3A3A3C)),
      ),

      // ── Ink Ripple ────────────────────────────────────────────────────────
      splashColor: const Color(0x224FC3F7),
      highlightColor: Colors.transparent,
    );
  }
}