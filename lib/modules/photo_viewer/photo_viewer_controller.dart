import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';
import '../../app/routes/app_routes.dart';

class PhotoViewerController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
  final mediaList      = <MediaItem>[].obs;
  final currentIndex   = 0.obs;
  final showUI         = true.obs;       // AppBar + BottomBar visibility
  final showInfoPanel  = false.obs;      // Slide-up EXIF info panel
  final isDeleting     = false.obs;
  final isZoomed       = false.obs;      // pinch zoom active হলে swipe disable

  // PageController
  late final PageController pageController;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Arguments: {'list': List<MediaItem>, 'index': int}
    final args  = Get.arguments as Map<String, dynamic>;
    mediaList.value  = List<MediaItem>.from(args['list'] as List);
    currentIndex.value = args['index'] as int;

    pageController = PageController(
      initialPage: currentIndex.value,
    );

    // Fullscreen mode
    _enterFullscreen();
  }

  @override
  void onClose() {
    _exitFullscreen();
    pageController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // FULLSCREEN
  // ─────────────────────────────────────────────────────────

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  // ─────────────────────────────────────────────────────────
  // CURRENT ITEM
  // ─────────────────────────────────────────────────────────

  MediaItem get currentItem => mediaList[currentIndex.value];

  bool get hasPrevious => currentIndex.value > 0;
  bool get hasNext     => currentIndex.value < mediaList.length - 1;

  // ─────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────

  void onPageChanged(int index) {
    currentIndex.value = index;
    // Info panel বন্ধ করো page change এ
    showInfoPanel.value = false;
  }

  void goToPrevious() {
    if (!hasPrevious) return;
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve:    Curves.easeInOut,
    );
  }

  void goToNext() {
    if (!hasNext) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve:    Curves.easeInOut,
    );
  }

  // ─────────────────────────────────────────────────────────
  // UI TOGGLE
  // ─────────────────────────────────────────────────────────

  void toggleUI() {
    showUI.value = !showUI.value;
    if (showUI.value) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void toggleInfoPanel() {
    showInfoPanel.value = !showInfoPanel.value;
    // Info panel খুললে UI দেখাও
    if (showInfoPanel.value) showUI.value = true;
  }

  // ─────────────────────────────────────────────────────────
  // FAVORITE
  // UPDATE media_items SET is_favorite = ? WHERE id = ?
  // ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite() async {
    final item  = currentItem;
    await _db.toggleFavorite(item.id!);

    // Local update
    mediaList[currentIndex.value] = item.copyWith(
      isFavorite: !item.isFavorite,
    );

    HapticFeedback.lightImpact();

    Get.snackbar(
      !item.isFavorite ? '❤️ Added to Favorites' : 'Removed from Favorites',
      '',
      snackPosition: SnackPosition.TOP,
      duration:      const Duration(seconds: 1),
      backgroundColor: Colors.black54,
      colorText:       Colors.white,
      margin:          const EdgeInsets.all(12),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DELETE
  // UPDATE media_items SET is_deleted = 1 WHERE id IN (...)
  // ─────────────────────────────────────────────────────────

  Future<void> deleteCurrentPhoto() async {
    final item = currentItem;

    // Confirm dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Move to Trash?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This photo will be moved to trash.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Move to Trash',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isDeleting.value = true;

    await _db.moveToTrash([item.id!]);
    mediaList.removeAt(currentIndex.value);

    if (mediaList.isEmpty) {
      // সব photo deleted → go back
      Get.back(result: true);
      return;
    }

    // Adjust index
    if (currentIndex.value >= mediaList.length) {
      currentIndex.value = mediaList.length - 1;
      pageController.jumpToPage(currentIndex.value);
    }

    isDeleting.value = false;

    Get.snackbar(
      '🗑️ Moved to Trash',
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 1),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SLIDESHOW
  // SharedPreferences key: "slideshow_interval"
  // ─────────────────────────────────────────────────────────

  void startSlideshow() {
    Get.toNamed(
      Routes.slideshow,
      arguments: {
        'list':  mediaList.toList(),
        'index': currentIndex.value,
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // ZOOM STATE
  // ─────────────────────────────────────────────────────────

  void onZoomStart()  => isZoomed.value = true;
  void onZoomEnd()    => isZoomed.value = false;

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  String get photoCounter =>
      '${currentIndex.value + 1} / ${mediaList.length}';

  String get currentFilename => currentItem.filename;
}