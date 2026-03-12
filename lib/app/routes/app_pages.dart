import 'package:get/get.dart';
import 'package:samsung_gallery/modules/video/video_view.dart';
import '../../modules/albums/album_detail_binding.dart';
import '../../modules/albums/album_detail_view.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/home/home_view.dart';
import '../../modules/albums/albums_binding.dart';
import '../../modules/albums/albums_view.dart';
import '../../modules/photo_viewer/photo_viewer_binding.dart';
import '../../modules/photo_viewer/photo_viewer_view.dart';
import '../../modules/favorites/favorites_binding.dart';
import '../../modules/favorites/favorites_view.dart';
import '../../modules/search/search_binding.dart';
import '../../modules/search/search_view.dart';
import '../../modules/settings/settings_binding.dart';
import '../../modules/settings/settings_view.dart';
import '../../modules/stories/stories_binding.dart';
import '../../modules/stories/stories_view.dart';
import '../../modules/trash/trash_binding.dart';
import '../../modules/trash/trash_view.dart';
import '../../modules/slideshow/slideshow_binding.dart';
import '../../modules/slideshow/slideshow_view.dart';
import '../../modules/video/video_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    // ─── Home ─────────────────────────────────────────────
    GetPage(
      name:        Routes.home,
      page:        () => const HomeView(),
      binding:     HomeBinding(),
      transition:  Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ─── Albums ───────────────────────────────────────────
    GetPage(
      name:        Routes.albums,
      page:        () => const AlbumsView(),
      binding:     AlbumsBinding(),
      transition:  Transition.fadeIn,
    ),

    // ─── Album Detail ─────────────────────────────────────
    GetPage(
      name:        Routes.albumDetail,
      page:        () => const AlbumDetailView(),
      binding:     AlbumDetailBinding(),
      transition:  Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // ─── Photo Viewer ─────────────────────────────────────
    GetPage(
      name:        Routes.photoViewer,
      page:        () => const PhotoViewerView(),
      binding:     PhotoViewerBinding(),
      transition:  Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      fullscreenDialog: true,
    ),

    // ─── Favorites ────────────────────────────────────────
    GetPage(
      name:        Routes.favorites,
      page:        () => const FavoritesView(),
      binding:     FavoritesBinding(),
      transition:  Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // ─── Search ───────────────────────────────────────────
    GetPage(
      name:        Routes.search,
      page:        () => const SearchView(),
      binding:     SearchBinding(),
      transition:  Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      fullscreenDialog: true,
    ),

    // ─── Settings ─────────────────────────────────────────
    GetPage(
      name:        Routes.settings,
      page:        () => const SettingsView(),
      binding:     SettingsBinding(),
      transition:  Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // ─── Stories ──────────────────────────────────────────
    GetPage(
      name:        Routes.stories,
      page:        () => const StoriesView(),
      binding:     StoriesBinding(),
      transition:  Transition.fadeIn,
    ),

    // ─── Explore ──────────────────────────────────────────
    GetPage(
      name:        Routes.video,
      page:        () => const VideoView(),
      binding:     VideoBinding(),
      transition:  Transition.fadeIn,
    ),

    // ─── Trash ────────────────────────────────────────────
    GetPage(
      name:        Routes.trash,
      page:        () => const TrashView(),
      binding:     TrashBinding(),
      transition:  Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    // ─── Slideshow ────────────────────────────────────────
    GetPage(
      name:        Routes.slideshow,
      page:        () => const SlideshowView(),
      binding:     SlideshowBinding(),
      transition:  Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      fullscreenDialog: true,
    ),
  ];
}