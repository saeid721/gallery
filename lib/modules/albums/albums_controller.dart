import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/album.dart';
import '../../app/routes/app_routes.dart';

class AlbumsController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
  final albumList    = <Album>[].obs;
  final isLoading    = true.obs;
  final isSelectMode = false.obs;
  final selectedIds  = <int>{}.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadAlbums();

    // SharedPreferences key: "show_hidden"
    // hidden toggle হলে auto reload
    ever(_prefs.showHidden, (_) => loadAlbums());
  }

  @override
  void onClose() {
    exitSelectMode();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD ALBUMS
  // SELECT * FROM albums ORDER BY date_modified DESC
  // ─────────────────────────────────────────────────────────

  Future<void> loadAlbums() async {
    isLoading.value = true;
    try {
      final result = await _db.getAllAlbums(
        // SharedPreferences key: "show_hidden"
        includeHidden: _prefs.showHidden.value,
      );
      albumList.value = result;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load albums',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // NAVIGATION
  // SharedPreferences key: "last_opened_album"
  // ─────────────────────────────────────────────────────────

  void openAlbum(Album album) {
    // Save last opened album to SharedPreferences
    _prefs.lastOpenedAlbum.value = album.id!;

    Get.toNamed(
      Routes.albumDetail,
      arguments: album,
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
      albumList.map((a) => a.id!).toSet(),
    );
  }

  bool isSelected(int id) => selectedIds.contains(id);
  int get selectedCount   => selectedIds.length;

  // ─────────────────────────────────────────────────────────
  // ALBUM ACTIONS
  // ─────────────────────────────────────────────────────────

  // UPDATE albums SET name = ? WHERE id = ?
  Future<void> renameAlbum(Album album) async {
    final controller = TextEditingController(text: album.name);

    final newName = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Rename Album',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller:  controller,
          autofocus:   true,
          style:       const TextStyle(color: Colors.white),
          decoration:  const InputDecoration(
            hintText:  'Album name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4FC3F7)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4FC3F7)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text(
              'Rename',
              style: TextStyle(color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    await _db.renameAlbum(album.id!, newName);
    await loadAlbums();

    Get.snackbar(
      'Album Renamed',
      '"$newName"',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  // UPDATE albums SET is_hidden = ? WHERE id = ?
  Future<void> toggleAlbumVisibility(Album album) async {
    await _db.toggleAlbumVisibility(album.id!);
    await loadAlbums();

    Get.snackbar(
      album.isHidden ? 'Album Unhidden' : 'Album Hidden',
      '"${album.name}"',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  // DELETE FROM albums WHERE id = ?
  Future<void> deleteSelectedAlbums() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Delete Albums?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete $count album${count > 1 ? 's' : ''}? '
              'Photos inside will not be deleted.',
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
              'Delete',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final id in ids) {
      await _db.deleteAlbum(id);
    }

    await loadAlbums();
    exitSelectMode();

    Get.snackbar(
      '🗑️ Albums Deleted',
      '$count album${count > 1 ? 's' : ''} deleted',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  bool get isEmpty => albumList.isEmpty && !isLoading.value;
}