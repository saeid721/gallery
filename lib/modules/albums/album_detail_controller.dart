import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/album.dart';
import '../../models/media_item.dart';
import '../../models/media_group.dart';
import '../../app/routes/app_routes.dart';

class AlbumDetailController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
  final album        = Rx<Album?>(null);
  final mediaList    = <MediaItem>[].obs;
  final groupedMedia = <MediaGroup>[].obs;
  final isLoading    = true.obs;
  final isSelectMode = false.obs;
  final selectedIds  = <int>{}.obs;
  final searchQuery  = ''.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Arguments: Album object (passed from AlbumsController)
    album.value = Get.arguments as Album;

    loadMedia();

    // Sort change → auto reload
    // SharedPreferences keys: "sort_by", "sort_order"
    ever(_prefs.sortBy,    (_) => loadMedia());
    ever(_prefs.sortOrder, (_) => loadMedia());

    // Search debounce
    debounce(
      searchQuery,
          (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    exitSelectMode();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD MEDIA
  // SELECT * FROM media_items
  // WHERE album_id = ? AND is_deleted = 0
  // ORDER BY {sortBy} {sortOrder}
  // ─────────────────────────────────────────────────────────

  Future<void> loadMedia() async {
    if (album.value == null) return;
    isLoading.value = true;

    try {
      final result = await _db.getMediaByAlbum(
        album.value!.id!,
        sortBy:    _prefs.sortBy.value,
        sortOrder: _prefs.sortOrder.value,
      );
      mediaList.value = result;
      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load photos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
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
  // FAVORITE
  // UPDATE media_items SET is_favorite = ? WHERE id = ?
  // ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite(int id) async {
    await _db.toggleFavorite(id);

    final index = mediaList.indexWhere((m) => m.id == id);
    if (index == -1) return;

    mediaList[index] = mediaList[index].copyWith(
      isFavorite: !mediaList[index].isFavorite,
    );
    _applyFilter();

    final isFav = mediaList[index].isFavorite;
    Get.snackbar(
      isFav ? '❤️ Added to Favorites' : 'Removed from Favorites',
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 1),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SELECT MODE
  // ─────────────────────────────────────────────────────────

  void enterSelectMode(int firstId) {
    isSelectMode.value = true;
    selectedIds.add(firstId);
  }

  void exitSelectMode() {
    isSelectMode.value = false;
    selectedIds.clear();
  }

  void toggleSelect(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) exitSelectMode();
    } else {
      selectedIds.add(id);
    }
  }

  void selectAll() {
    selectedIds.addAll(
      mediaList.map((m) => m.id!).toSet(),
    );
  }

  bool isSelected(int id) => selectedIds.contains(id);
  int  get selectedCount  => selectedIds.length;

  // ─────────────────────────────────────────────────────────
  // BULK ACTIONS
  // ─────────────────────────────────────────────────────────

  // UPDATE media_items SET is_deleted = 1 WHERE id IN (...)
  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Move to Trash?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Move $count photo${count > 1 ? 's' : ''} to trash?',
          style: const TextStyle(color: Colors.grey),
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

    await _db.moveToTrash(ids);
    mediaList.removeWhere((m) => ids.contains(m.id));
    _applyFilter();
    exitSelectMode();

    // Reload album to update cover + count
    final updatedAlbum = await _db.getAlbumById(album.value!.id!);
    if (updatedAlbum != null) album.value = updatedAlbum;

    Get.snackbar(
      '🗑️ Moved to Trash',
      '$count photo${count > 1 ? 's' : ''} moved to trash',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  // UPDATE media_items SET is_favorite = 1 WHERE id IN (...)
  Future<void> favoriteSelected() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    await _db.favoriteMultiple(ids);

    for (final id in ids) {
      final index = mediaList.indexWhere((m) => m.id == id);
      if (index != -1) {
        mediaList[index] = mediaList[index].copyWith(isFavorite: true);
      }
    }
    _applyFilter();
    exitSelectMode();

    Get.snackbar(
      '❤️ Added to Favorites',
      '$count photo${count > 1 ? 's' : ''} added',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

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

  void startSlideshow() {
    if (mediaList.isEmpty) return;
    Get.toNamed(
      Routes.slideshow,
      arguments: {
        'list':  mediaList.toList(),
        'index': 0,
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  String get albumTitle     => album.value?.name ?? '';
  String get albumSubtitle  => '${mediaList.length} photos';
  bool   get isEmpty        => mediaList.isEmpty && !isLoading.value;
  bool   get isGridView     => _prefs.viewMode.value == 'grid';
  int    get columnCount    => _prefs.gridColumnCount.value;
}