import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';
import '../../models/album.dart';
import '../../app/routes/app_routes.dart';

// ─── Search Result Model ──────────────────────────────────────
class SearchResult {
  final SearchResultType type;
  final MediaItem?       media;
  final Album?           album;

  const SearchResult.media(this.media)
      : type  = SearchResultType.media,
        album = null;

  const SearchResult.album(this.album)
      : type  = SearchResultType.album,
        media = null;
}

enum SearchResultType { media, album }

// ─── Recent Search Model ──────────────────────────────────────
class RecentSearch {
  final String    query;
  final DateTime  timestamp;
  const RecentSearch({required this.query, required this.timestamp});
}

class SearchController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── Text Controller ─────────────────────────────────────
  final textController = TextEditingController();
  final focusNode      = FocusNode();

  // ─── State ───────────────────────────────────────────────
  final query          = ''.obs;
  final results        = <SearchResult>[].obs;
  final mediaResults   = <MediaItem>[].obs;
  final albumResults   = <Album>[].obs;
  final recentSearches = <RecentSearch>[].obs;
  final isSearching    = false.obs;
  final isLoading      = false.obs;
  final activeFilter   = SearchFilter.all.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Debounce search
    debounce(
      query,
          (_) => _performSearch(),
      time: const Duration(milliseconds: 400),
    );

    // Auto focus keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // SEARCH
  // SELECT * FROM media_items WHERE filename LIKE ?
  // SELECT * FROM albums WHERE name LIKE ?
  // ─────────────────────────────────────────────────────────

  Future<void> _performSearch() async {
    final q = query.value.trim();

    if (q.isEmpty) {
      mediaResults.clear();
      albumResults.clear();
      results.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    isLoading.value   = true;

    try {
      // Search media
      // SELECT * FROM media_items WHERE filename LIKE ? AND is_deleted = 0
      final media = await _db.searchMedia(q);
      mediaResults.value = media;

      // Search albums
      // SELECT * FROM albums WHERE name LIKE ?
      final albums = await _db.getAllAlbums();
      albumResults.value = albums
          .where((a) => a.name.toLowerCase().contains(q.toLowerCase()))
          .toList();

      // Combine results based on active filter
      _applyFilter();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Search failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // FILTER
  // ─────────────────────────────────────────────────────────

  void setFilter(SearchFilter filter) {
    activeFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    switch (activeFilter.value) {
      case SearchFilter.all:
        results.value = [
          ...albumResults.map((a) => SearchResult.album(a)),
          ...mediaResults.map((m) => SearchResult.media(m)),
        ];
        break;
      case SearchFilter.photos:
        results.value = mediaResults
            .where((m) => m.mediaType == 'image')
            .map((m) => SearchResult.media(m))
            .toList();
        break;
      case SearchFilter.videos:
        results.value = mediaResults
            .where((m) => m.mediaType == 'video')
            .map((m) => SearchResult.media(m))
            .toList();
        break;
      case SearchFilter.albums:
        results.value = albumResults
            .map((a) => SearchResult.album(a))
            .toList();
        break;
      case SearchFilter.favorites:
        results.value = mediaResults
            .where((m) => m.isFavorite)
            .map((m) => SearchResult.media(m))
            .toList();
        break;
    }
  }

  // ─────────────────────────────────────────────────────────
  // QUERY MANAGEMENT
  // ─────────────────────────────────────────────────────────

  void onQueryChanged(String value) {
    query.value = value;
  }

  void clearQuery() {
    textController.clear();
    query.value       = '';
    isSearching.value = false;
    results.clear();
    mediaResults.clear();
    albumResults.clear();
    focusNode.requestFocus();
  }

  void submitSearch(String q) {
    if (q.trim().isEmpty) return;
    _saveRecentSearch(q.trim());
    _performSearch();
  }

  // ─────────────────────────────────────────────────────────
  // RECENT SEARCHES (in-memory)
  // ─────────────────────────────────────────────────────────

  void _saveRecentSearch(String q) {
    // Remove duplicate
    recentSearches.removeWhere((r) => r.query == q);

    // Add to front
    recentSearches.insert(0,
      RecentSearch(query: q, timestamp: DateTime.now()),
    );

    // Keep max 10
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
  }

  void removeRecentSearch(String q) {
    recentSearches.removeWhere((r) => r.query == q);
  }

  void clearRecentSearches() {
    recentSearches.clear();
  }

  void searchFromRecent(String q) {
    textController.text = q;
    query.value         = q;
    focusNode.unfocus();
  }

  // ─────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────

  void openPhoto(MediaItem item) {
    _saveRecentSearch(query.value.trim());

    // Find index in mediaResults
    final index = mediaResults.indexOf(item);
    Get.toNamed(
      Routes.photoViewer,
      arguments: {
        'list':  mediaResults.toList(),
        'index': index,
      },
    );
  }

  void openAlbum(Album album) {
    _saveRecentSearch(query.value.trim());
    _prefs.lastOpenedAlbum.value = album.id!;

    Get.toNamed(
      Routes.albumDetail,
      arguments: album,
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  bool get isEmpty =>
      isSearching.value && results.isEmpty && !isLoading.value;

  String get resultCountLabel {
    final count = results.length;
    return '$count result${count != 1 ? 's' : ''}';
  }

  int get mediaCount   => mediaResults.length;
  int get albumCount   => albumResults.length;
  int get favoriteCount =>
      mediaResults.where((m) => m.isFavorite).length;
}

enum SearchFilter { all, photos, videos, albums, favorites }