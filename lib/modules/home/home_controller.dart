import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/services/media_service.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';
import '../../models/media_group.dart';
import '../../app/routes/app_routes.dart';

class HomeController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _media = Get.find<MediaService>();
  final _prefs = Get.find<PreferencesService>();

  // ─── Media state ─────────────────────────────────────────
  final mediaList    = <MediaItem>[].obs;
  final groupedMedia = <MediaGroup>[].obs;
  final albums       = <DeviceAlbum>[].obs;

  // ─── Loading state ───────────────────────────────────────
  final isLoading     = true.obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;
  int   _currentPage  = 0;

  // ─── Permission state ────────────────────────────────────
  final permissionDenied  = false.obs;
  final permissionLimited = false.obs;

  // ─── UI state ────────────────────────────────────────────
  final isSelectMode = false.obs;
  final selectedIds  = <String>{}.obs;
  final searchQuery  = ''.obs;
  final showSearch   = false.obs;
  final columnCount  = 3.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // FIX 1: .gridColumnCount is RxInt → use .value to get int
    columnCount.value = _prefs.gridColumnCount.value;

    debounce(
      searchQuery,
          (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );

    _initMedia();
  }

  @override
  void onClose() {
    exitSelectMode();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // INIT MEDIA
  // ─────────────────────────────────────────────────────────

  Future<void> _initMedia() async {
    isLoading.value = true;

    final granted = await _media.requestPermission();

    if (!granted) {
      isLoading.value        = false;
      permissionDenied.value = true;
      return;
    }

    permissionLimited.value = _media.permissionState.value.isAuth == false;

    await Future.wait([
      loadMedia(reset: true),
      loadAlbums(),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // LOAD MEDIA
  // ─────────────────────────────────────────────────────────

  Future<void> loadMedia({bool reset = false}) async {
    if (reset) {
      _currentPage  = 0;
      hasMore.value = true;
      mediaList.clear();
    }

    if (!hasMore.value || isLoadingMore.value) return;

    if (_currentPage == 0) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final page = await _media.loadPage(
        page:      _currentPage,
        sortBy:    _prefs.sortBy.value,
        sortOrder: _prefs.sortOrder.value,
      );

      if (page.isEmpty) {
        hasMore.value = false;
      } else {
        mediaList.addAll(page);
        _currentPage++;
        if (page.length < 80) hasMore.value = false;
      }

      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load photos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOAD NEXT PAGE
  // ─────────────────────────────────────────────────────────

  Future<void> loadNextPage() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    await loadMedia();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD ALBUMS
  // ─────────────────────────────────────────────────────────

  Future<void> loadAlbums() async {
    albums.value = await _media.loadAlbums();
  }

  // ─────────────────────────────────────────────────────────
  // FILTER & GROUP
  // ─────────────────────────────────────────────────────────

  void _applyFilter() {
    List<MediaItem> filtered = mediaList;

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      filtered = mediaList
          .where((m) => m.filename.toLowerCase().contains(q))
          .toList();
    }

    groupedMedia.value = MediaGroup.groupByDate(filtered);
  }

  // ─────────────────────────────────────────────────────────
  // GRID SIZE
  // ─────────────────────────────────────────────────────────

  void setColumnCount(int n) {
    columnCount.value = n;
    // FIX 2: PreferencesService has no setGridColumnCount() method.
    // gridColumnCount is already an RxInt with an ever() listener
    // that auto-saves to SharedPreferences — just set the value directly.
    _prefs.gridColumnCount.value = n;
  }

  // ─────────────────────────────────────────────────────────
  // THUMBNAIL
  // ─────────────────────────────────────────────────────────

  Future<dynamic> getThumbnail(String assetId) =>
      _media.getThumbnail(assetId);

  // ─────────────────────────────────────────────────────────
  // FAVORITE
  // ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String assetId) async {
    final index = mediaList.indexWhere((m) => m.assetId == assetId);
    if (index == -1) return;

    final newValue = !mediaList[index].isFavorite;
    mediaList[index] = mediaList[index].copyWith(isFavorite: newValue);
    _applyFilter();

    Get.snackbar(
      newValue ? '❤️ Added to Favorites' : 'Removed from Favorites',
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 1),
      isDismissible: true,
    );
  }

  // ─────────────────────────────────────────────────────────
  // SELECT MODE
  // ─────────────────────────────────────────────────────────

  void enterSelectMode(String assetId) {
    isSelectMode.value = true;
    selectedIds.add(assetId);
  }

  void exitSelectMode() {
    isSelectMode.value = false;
    selectedIds.clear();
  }

  void toggleSelect(String assetId) {
    if (selectedIds.contains(assetId)) {
      selectedIds.remove(assetId);
      if (selectedIds.isEmpty) exitSelectMode();
    } else {
      selectedIds.add(assetId);
    }
  }

  void selectAll() {
    selectedIds.addAll(
      mediaList.map((m) => m.assetId!).where((id) => id.isNotEmpty),
    );
  }

  bool isSelected(String assetId) => selectedIds.contains(assetId);
  int  get selectedCount           => selectedIds.length;

  // ─────────────────────────────────────────────────────────
  // BULK ACTIONS
  // ─────────────────────────────────────────────────────────

  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    mediaList.removeWhere((m) => ids.contains(m.assetId));
    _applyFilter();
    exitSelectMode();

    Get.snackbar(
      '🗑️ Moved to Trash',
      '$count item${count > 1 ? 's' : ''} moved to trash',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  Future<void> favoriteSelected() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    for (final assetId in ids) {
      final i = mediaList.indexWhere((m) => m.assetId == assetId);
      if (i != -1) {
        mediaList[i] = mediaList[i].copyWith(isFavorite: true);
      }
    }
    _applyFilter();
    exitSelectMode();

    Get.snackbar(
      '❤️ Added to Favorites',
      '$count item${count > 1 ? 's' : ''} added to favorites',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PERMISSION RETRY
  // ─────────────────────────────────────────────────────────

  Future<void> retryPermission() async {
    permissionDenied.value = false;
    await _initMedia();
  }

  void openSystemSettings() => _media.openSettings();

  // ─────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────

  void openPhoto(int index) {
    Get.toNamed(
      Routes.photoViewer,
      arguments: {
        'list':  mediaList.toList(),
        'index': index,
      },
    );
  }

  void openSettings()  => Get.toNamed(Routes.settings);
  void openTrash()     => Get.toNamed(Routes.trash);
  void openFavorites() => Get.toNamed(Routes.favorites);

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  bool get isEmpty    => mediaList.isEmpty && !isLoading.value;
  bool get isGridView => _prefs.viewMode.value == 'grid';
}