import 'package:get/get.dart';

// Core
import '../../core/database/database_helper.dart';
import '../../core/services/media_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/theme_controller.dart';

// Modules
import '../../modules/albums/album_detail_controller.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/albums/albums_controller.dart';
import '../../modules/photo_viewer/photo_viewer_controller.dart';
import '../../modules/favorites/favorites_controller.dart';
import '../../modules/search/search_controller.dart';
import '../../modules/settings/settings_controller.dart';
import '../../modules/stories/stories_controller.dart';
import '../../modules/trash/trash_controller.dart';
import '../../modules/slideshow/slideshow_controller.dart';
import '../../modules/video/video_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {

    // ─────────────────────────────────────────────────────────
    // CORE SERVICES (সবার আগে register হবে)
    // ─────────────────────────────────────────────────────────

    // SQLite Database
    // সব controller এই service use করে
    Get.lazyPut<DatabaseHelper>(
          () => DatabaseHelper(),
      fenix: true,
    );

    // SharedPreferences Service
    // Already initialized in main.dart via Get.putAsync()
    // কিন্তু এখানে reference রাখা হলো clarity এর জন্য
    // Get.find<PreferencesService>() সব জায়গায় কাজ করবে
    if (!Get.isRegistered<PreferencesService>()) {
      Get.lazyPut<PreferencesService>(
            () => PreferencesService(),
        fenix: true,
      );
    }

    // Theme Controller
    // SharedPreferences key: "theme_mode"
    Get.lazyPut<ThemeController>(
          () => ThemeController(),
      fenix: true,
    );

    // ─────────────────────────────────────────────────────────
    // MODULE CONTROLLERS
    // fenix: true  → tab-based controllers (persist across tabs)
    // fenix: false → screen-based controllers (dispose on pop)
    // ─────────────────────────────────────────────────────────


    // Home — persistent (bottom nav tab)
    // SharedPreferences keys: "sort_by", "sort_order", "view_mode", "grid_column_count"
    // SQLite table: media_items
    Get.lazyPut<HomeController>(
          () => HomeController(),
      fenix: true,
    );

    // Albums — persistent (bottom nav tab)
    // SQLite table: albums
    Get.lazyPut<AlbumsController>(
          () => AlbumsController(),
      fenix: true,
    );

    // Album Detail — disposable (screen push/pop)
    // Arguments: Album object
    // SQLite table: media_items WHERE album_id = ?
    Get.lazyPut<AlbumDetailController>(
          () => AlbumDetailController(),
      fenix: false,
    );

    // Photo Viewer — disposable (fullscreen dialog)
    // Arguments: {'list': List<MediaItem>, 'index': int}
    // SQLite table: media_items (toggle favorite, delete)
    Get.lazyPut<PhotoViewerController>(
          () => PhotoViewerController(),
      fenix: false,
    );

    // Favorites — persistent (accessible from menu)
    // SQLite query: SELECT * FROM media_items WHERE is_favorite = 1
    Get.lazyPut<FavoritesController>(
          () => FavoritesController(),
      fenix: true,
    );

    // Search — disposable (fullscreen dialog)
    // SQLite query: SELECT * FROM media_items WHERE filename LIKE ?
    Get.lazyPut<SearchController>(
          () => SearchController(),
      fenix: false,
    );

    // Settings — disposable (screen push/pop)
    // SharedPreferences keys: ALL keys (read + write)
    Get.lazyPut<SettingsController>(
          () => SettingsController(),
      fenix: false,
    );

    // Stories — persistent (bottom nav tab)
    // SQLite table: media_items (grouped by date)
    Get.lazyPut<StoriesController>(
          () => StoriesController(),
      fenix: true,
    );

    // Explore — persistent (bottom nav tab)
    // SQLite table: media_items (grouped by location/date)
    Get.lazyPut<VideoController>(
          () => VideoController(),
      fenix: true,
    );

    // Trash — disposable (screen push/pop)
    // SQLite table: media_items WHERE is_deleted = 1
    Get.lazyPut<TrashController>(
          () => TrashController(),
      fenix: false,
    );

    // Slideshow — disposable (fullscreen dialog)
    // Arguments: {'list': List<MediaItem>, 'index': int}
    // SharedPreferences key: "slideshow_interval"
    Get.lazyPut<SlideshowController>(
          () => SlideshowController(),
      fenix: false,
    );


    Get.lazyPut<MediaService>(
          () => MediaService(),
      fenix: false,
    );
  }
}