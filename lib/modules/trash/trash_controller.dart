import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';
import '../../app/routes/app_routes.dart';

class TrashController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
  final mediaList    = <MediaItem>[].obs;
  final isLoading    = true.obs;
  final isSelectMode = false.obs;
  final selectedIds  = <int>{}.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadTrash();
  }

  @override
  void onClose() {
    exitSelectMode();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD TRASH
  // SELECT * FROM media_items
  // WHERE is_deleted = 1
  // ORDER BY deleted_at DESC
  // ─────────────────────────────────────────────────────────

  Future<void> loadTrash() async {
    isLoading.value = true;
    try {
      final result = await _db.getTrash();
      mediaList.value = result;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load trash',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
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
  // RESTORE
  // UPDATE media_items SET is_deleted = 0, deleted_at = NULL
  // WHERE id IN (...)
  // ─────────────────────────────────────────────────────────

  Future<void> restoreSelected() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    await _db.restoreFromTrash(ids);
    mediaList.removeWhere((m) => ids.contains(m.id));
    exitSelectMode();

    Get.snackbar(
      '✅ Restored',
      '$count photo${count > 1 ? 's' : ''} restored',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  Future<void> restoreSingle(int id) async {
    await _db.restoreFromTrash([id]);
    mediaList.removeWhere((m) => m.id == id);

    Get.snackbar(
      '✅ Restored',
      'Photo restored successfully',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 1),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PERMANENT DELETE
  // DELETE FROM media_items WHERE id IN (...)
  // ─────────────────────────────────────────────────────────

  Future<void> deleteSelectedPermanently() async {
    if (selectedIds.isEmpty) return;

    final ids   = selectedIds.toList();
    final count = ids.length;

    final confirmed = await _showDeleteConfirmDialog(count);
    if (confirmed != true) return;

    await _db.deletePermanently(ids);
    mediaList.removeWhere((m) => ids.contains(m.id));
    exitSelectMode();

    Get.snackbar(
      '🗑️ Permanently Deleted',
      '$count photo${count > 1 ? 's' : ''} permanently deleted',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 2),
    );
  }

  Future<void> deleteSinglePermanently(int id) async {
    final confirmed = await _showDeleteConfirmDialog(1);
    if (confirmed != true) return;

    await _db.deletePermanently([id]);
    mediaList.removeWhere((m) => m.id == id);

    Get.snackbar(
      '🗑️ Permanently Deleted',
      'Photo permanently deleted',
      snackPosition: SnackPosition.BOTTOM,
      duration:      const Duration(seconds: 1),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY TRASH
  // DELETE FROM media_items WHERE is_deleted = 1
  // ─────────────────────────────────────────────────────────

  Future<void> emptyTrash() async {
    if (mediaList.isEmpty) return;

    final count     = mediaList.length;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Empty Trash?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Permanently delete all $count photo'
              '${count > 1 ? 's' : ''}? '
              'This cannot be undone.',
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
              'Empty Trash',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _db.emptyTrash();
    mediaList.clear();

    Get.snackbar(
      '🗑️ Trash Emptied',
      'All $count photo${count > 1 ? 's' : ''} permanently deleted',
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

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  Future<bool?> _showDeleteConfirmDialog(int count) {
    return Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Permanently Delete?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete $count photo${count > 1 ? 's' : ''} permanently? '
              'This cannot be undone.',
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
              'Delete',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  bool   get isEmpty     => mediaList.isEmpty && !isLoading.value;
  int    get columnCount => _prefs.gridColumnCount.value;
  String get subtitle    =>
      '${mediaList.length} photo${mediaList.length != 1 ? 's' : ''}';

  // Days remaining before auto-delete
  // SharedPreferences key: "recycle_bin_days"
  String daysRemaining(MediaItem item) {
    if (item.deletedAt == null) return '';
    final deletedAt  = DateTime.fromMillisecondsSinceEpoch(item.deletedAt!);
    final autoDelete = deletedAt.add(
      Duration(days: _prefs.recycleBinDays.value),
    );
    final remaining  = autoDelete.difference(DateTime.now()).inDays;
    if (remaining <= 0) return 'Deletes today';
    return 'Deletes in $remaining day${remaining > 1 ? 's' : ''}';
  }
}