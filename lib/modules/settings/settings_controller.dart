import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/theme_controller.dart';

class SettingsController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db         = Get.find<DatabaseHelper>();
  final _prefs      = Get.find<PreferencesService>();
  final _themeCtrl  = Get.find<ThemeController>();

  // ─── State ───────────────────────────────────────────────
  final dbStats     = <String, int>{}.obs;
  final isLoadingStats = true.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadDbStats();
  }

  // ─────────────────────────────────────────────────────────
  // DB STATS
  // SELECT COUNT(*) from multiple tables
  // ─────────────────────────────────────────────────────────

  Future<void> loadDbStats() async {
    isLoadingStats.value = true;
    try {
      final stats    = await _db.getStats();
      dbStats.value  = stats;
    } finally {
      isLoadingStats.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // VIEW PREFERENCES
  // SharedPreferences keys: "view_mode", "grid_column_count"
  // ─────────────────────────────────────────────────────────

  String get viewMode         => _prefs.viewMode.value;
  int    get gridColumnCount  => _prefs.gridColumnCount.value;

  void setViewMode(String mode) {
    // SharedPreferences key: "view_mode"
    _prefs.viewMode.value = mode;
  }

  void setGridColumnCount(int count) {
    // SharedPreferences key: "grid_column_count"
    _prefs.gridColumnCount.value = count;
  }

  // ─────────────────────────────────────────────────────────
  // SORT PREFERENCES
  // SharedPreferences keys: "sort_by", "sort_order"
  // ─────────────────────────────────────────────────────────

  String get sortBy     => _prefs.sortBy.value;
  String get sortOrder  => _prefs.sortOrder.value;

  void setSortBy(String value) {
    // SharedPreferences key: "sort_by"
    _prefs.sortBy.value = value;
  }

  void setSortOrder(String value) {
    // SharedPreferences key: "sort_order"
    _prefs.sortOrder.value = value;
  }

  // ─────────────────────────────────────────────────────────
  // THEME
  // SharedPreferences key: "theme_mode"
  // ─────────────────────────────────────────────────────────

  bool get isDark => _themeCtrl.isDark;

  void toggleTheme() => _themeCtrl.toggle();

  void setThemeMode(String mode) {
    // SharedPreferences key: "theme_mode"
    _prefs.themeMode.value = mode;
  }

  // ─────────────────────────────────────────────────────────
  // MEDIA PREFERENCES
  // ─────────────────────────────────────────────────────────

  bool get autoPlayVideo      => _prefs.autoPlayVideo.value;
  bool get showVideoDuration  => _prefs.showVideoDuration.value;
  bool get showHidden         => _prefs.showHidden.value;
  int  get slideshowInterval  => _prefs.slideshowInterval.value;
  int  get recycleBinDays     => _prefs.recycleBinDays.value;

  void toggleAutoPlayVideo() {
    // SharedPreferences key: "auto_play_video"
    _prefs.autoPlayVideo.value = !_prefs.autoPlayVideo.value;
  }

  void toggleShowVideoDuration() {
    // SharedPreferences key: "show_video_duration"
    _prefs.showVideoDuration.value = !_prefs.showVideoDuration.value;
  }

  void toggleShowHidden() {
    // SharedPreferences key: "show_hidden"
    _prefs.showHidden.value = !_prefs.showHidden.value;
  }

  void setSlideshowInterval(int ms) {
    // SharedPreferences key: "slideshow_interval"
    _prefs.slideshowInterval.value = ms;
  }

  void setRecycleBinDays(int days) {
    // SharedPreferences key: "recycle_bin_days"
    _prefs.recycleBinDays.value = days;
  }

  // ─────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────

  Future<void> resetAllPreferences() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Reset Settings?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'All settings will be reset to default values.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _prefs.resetAll();
    await loadDbStats();

    Get.snackbar(
      '✅ Settings Reset',
      'All settings restored to default',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  // Slideshow interval label
  String get slideshowIntervalLabel {
    final ms = _prefs.slideshowInterval.value;
    return '${(ms / 1000).toStringAsFixed(0)}s';
  }

  // Recycle bin days label
  String get recycleBinDaysLabel =>
      '${_prefs.recycleBinDays.value} days';

  // Sort by label
  String get sortByLabel {
    switch (_prefs.sortBy.value) {
      case 'date_added':  return 'Date Added';
      case 'name':        return 'Name';
      case 'file_size':   return 'File Size';
      default:            return 'Date Added';
    }
  }

  // Sort order label
  String get sortOrderLabel =>
      _prefs.sortOrder.value == 'DESC' ? 'Newest First' : 'Oldest First';

  // DB total stats
  int get totalPhotos    => dbStats['total_media']     ?? 0;
  int get totalFavorites => dbStats['total_favorites'] ?? 0;
  int get totalTrash     => dbStats['total_trash']     ?? 0;
  int get totalAlbums    => dbStats['total_albums']    ?? 0;
}