import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All preference keys centralized here
class PrefKeys {
  static const viewMode = 'view_mode';
  static const gridColumnCount = 'grid_column_count';
  static const sortBy = 'sort_by';
  static const sortOrder = 'sort_order';
  static const lastOpenedAlbum = 'last_opened_album';
  static const showHidden = 'show_hidden';
  static const slideshowInterval = 'slideshow_interval';
  static const themeMode = 'theme_mode';
  static const dbInitialized = 'db_initialized';
  static const firstLaunch = 'first_launch';
  static const autoPlayVideo = 'auto_play_video';
  static const showVideoDuration = 'show_video_duration';
  static const recycleBinDays = 'recycle_bin_days';
}

/// GetX-based reactive Preferences Service
class PreferencesService extends GetxService {
  late SharedPreferences _prefs;

  /// Observables
  final viewMode = 'grid'.obs;
  final gridColumnCount = 3.obs;
  final sortBy = 'date_added'.obs;
  final sortOrder = 'DESC'.obs;
  final lastOpenedAlbum = 0.obs;
  final showHidden = false.obs;
  final slideshowInterval = 3000.obs;
  final themeMode = 'dark'.obs;
  final autoPlayVideo = true.obs;
  final showVideoDuration = true.obs;
  final recycleBinDays = 30.obs;

  /// Initialize SharedPreferences and load all values
  Future<PreferencesService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
    _listenAll();
    return this;
  }

  /// Load values from SharedPreferences
  void _loadAll() {
    viewMode.value = _prefs.getString(PrefKeys.viewMode) ?? 'grid';
    gridColumnCount.value = _prefs.getInt(PrefKeys.gridColumnCount) ?? 3;
    sortBy.value = _prefs.getString(PrefKeys.sortBy) ?? 'date_added';
    sortOrder.value = _prefs.getString(PrefKeys.sortOrder) ?? 'DESC';
    lastOpenedAlbum.value = _prefs.getInt(PrefKeys.lastOpenedAlbum) ?? 0;
    showHidden.value = _prefs.getBool(PrefKeys.showHidden) ?? false;
    slideshowInterval.value = _prefs.getInt(PrefKeys.slideshowInterval) ?? 3000;
    themeMode.value = _prefs.getString(PrefKeys.themeMode) ?? 'dark';
    autoPlayVideo.value = _prefs.getBool(PrefKeys.autoPlayVideo) ?? true;
    showVideoDuration.value = _prefs.getBool(PrefKeys.showVideoDuration) ?? true;
    recycleBinDays.value = _prefs.getInt(PrefKeys.recycleBinDays) ?? 30;
  }

  /// Listen to observables and save changes automatically
  void _listenAll() {
    ever(viewMode, (v) => _prefs.setString(PrefKeys.viewMode, v));
    ever(gridColumnCount, (v) => _prefs.setInt(PrefKeys.gridColumnCount, v));
    ever(sortBy, (v) => _prefs.setString(PrefKeys.sortBy, v));
    ever(sortOrder, (v) => _prefs.setString(PrefKeys.sortOrder, v));
    ever(lastOpenedAlbum, (v) => _prefs.setInt(PrefKeys.lastOpenedAlbum, v));
    ever(showHidden, (v) => _prefs.setBool(PrefKeys.showHidden, v));
    ever(slideshowInterval, (v) => _prefs.setInt(PrefKeys.slideshowInterval, v));
    ever(themeMode, (v) => _prefs.setString(PrefKeys.themeMode, v));
    ever(autoPlayVideo, (v) => _prefs.setBool(PrefKeys.autoPlayVideo, v));
    ever(showVideoDuration, (v) => _prefs.setBool(PrefKeys.showVideoDuration, v));
    ever(recycleBinDays, (v) => _prefs.setInt(PrefKeys.recycleBinDays, v));
  }

  /// Toggle view mode between 'grid' and 'list'
  void toggleViewMode() {
    viewMode.value = viewMode.value == 'grid' ? 'list' : 'grid';
  }

  /// Toggle sort order
  void toggleSortOrder() {
    sortOrder.value = sortOrder.value == 'DESC' ? 'ASC' : 'DESC';
  }

  /// Cycle grid columns: 3 → 4 → 5 → 3
  void cycleGridColumns() {
    final current = gridColumnCount.value;
    gridColumnCount.value = current >= 5 ? 3 : current + 1;
  }

  /// Reset all preferences
  Future<void> resetAll() async {
    await _prefs.clear();
    _loadAll();
  }

  /// Database initialized flag
  bool get isDbInitialized => _prefs.getBool(PrefKeys.dbInitialized) ?? false;
  Future<void> setDbInitialized() async => _prefs.setBool(PrefKeys.dbInitialized, true);

  /// First launch flag
  bool get isFirstLaunch => _prefs.getBool(PrefKeys.firstLaunch) ?? true;
  Future<void> setFirstLaunchDone() async => _prefs.setBool(PrefKeys.firstLaunch, false);

  /// Debug: all current values
  Map<String, dynamic> get allValues => {
    PrefKeys.viewMode: viewMode.value,
    PrefKeys.gridColumnCount: gridColumnCount.value,
    PrefKeys.sortBy: sortBy.value,
    PrefKeys.sortOrder: sortOrder.value,
    PrefKeys.lastOpenedAlbum: lastOpenedAlbum.value,
    PrefKeys.showHidden: showHidden.value,
    PrefKeys.slideshowInterval: slideshowInterval.value,
    PrefKeys.themeMode: themeMode.value,
    PrefKeys.autoPlayVideo: autoPlayVideo.value,
    PrefKeys.showVideoDuration: showVideoDuration.value,
    PrefKeys.recycleBinDays: recycleBinDays.value,
    PrefKeys.dbInitialized: isDbInitialized,
    PrefKeys.firstLaunch: isFirstLaunch,
  };
}