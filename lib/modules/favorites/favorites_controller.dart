import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';
import '../../models/media_group.dart';
import '../../app/routes/app_routes.dart';

class FavoritesController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
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
    loadFavorites();

    // Sort change → auto reload
    // SharedPreferences keys: "sort_by", "sort_order"
    ever(_prefs.sortBy,    (_) => loadFavorites());
    ever(_prefs.sortOrder, (_) => loadFavorites());

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
  // LOAD FAVORITES
  // SELECT * FROM media_items
  // WHERE is_favorite = 1 AND is_deleted = 0
  // ORDER BY date_added DESC
  // ─────────────────────────────────────────────────────────

  Future<void> loadFavorites() async {
    isLoading.value = true;
    try {
      final result = await _db.getFavorites();
      mediaList.value = result;
      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load favorites',
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
  // UNFAVORITE
  // UPDATE media_items SET is_favorite = 0 WHERE id = ?
  // ─────────────────────────────────────────────────────────

  Future<void> unfavorite(int id) async {
    await _db.toggleFavorite(id);

    // Remove from favorites list immediately
    mediaList.removeWhere((m) => m.id == id);
    _applyFilter();

    Get.snackbar(
      'Removed from Favorites',
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

  // UPDATE media_items SET is_favorite = 0 WHERE id IN (...)
  Future<void> unfavoriteSelected() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Remove from Favorites?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove $count photo${count > 1 ? 's' : ''} '
              'from favorites?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final id in ids) {
      await _db.toggleFavorite(id);
    }

    mediaList.removeWhere((m) => ids.contains(m.id));
    _applyFilter();
    exitSelectMode();

    Get.snackbar(
      'Removed from Favorites',
      '$count photo${count > 1 ? 's' : ''} removed',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

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
            child:     const Text('Cancel'),
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

    Get.snackbar(
      '🗑️ Moved to Trash',
      '$count photo${count > 1 ? 's' : ''} moved to trash',
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

  bool   get isEmpty     => mediaList.isEmpty && !isLoading.value;
  int    get columnCount => _prefs.gridColumnCount.value;
  String get subtitle    =>
      '${mediaList.length} photo${mediaList.length != 1 ? 's' : ''}';
}