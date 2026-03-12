import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';

enum SlideshowTransition { fade, slide, zoom, flip }
enum SlideshowOrder      { sequential, shuffle }

class SlideshowController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
  final mediaList      = <MediaItem>[].obs;
  final currentIndex   = 0.obs;
  final isPlaying      = true.obs;
  final isUIVisible    = true.obs;
  final progress       = 0.0.obs;
  final transition     = SlideshowTransition.fade.obs;
  final order          = SlideshowOrder.sequential.obs;
  final isFavorite     = false.obs;

  // ─── Internal ────────────────────────────────────────────
  Timer?              _timer;
  Timer?              _uiTimer;
  PageController?     pageController;
  final _originalList = <MediaItem>[];

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Arguments: {'list': List<MediaItem>, 'index': int}
    final args = Get.arguments as Map<String, dynamic>;
    final list = List<MediaItem>.from(args['list'] as List);
    final index = args['index'] as int;

    _originalList.addAll(list);
    mediaList.value    = list;
    currentIndex.value = index;

    pageController = PageController(initialPage: index);

    _updateFavoriteState();
    _enterFullscreen();
    _startAutoHideUI();

    // Auto-start slideshow
    // SharedPreferences key: "slideshow_interval"
    if (isPlaying.value) _startTimer();
  }

  @override
  void onClose() {
    _stopTimer();
    _uiTimer?.cancel();
    pageController?.dispose();
    _exitFullscreen();
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
  // TIMER
  // SharedPreferences key: "slideshow_interval"
  // ─────────────────────────────────────────────────────────

  void _startTimer() {
    _stopTimer();
    progress.value = 0.0;

    // SharedPreferences key: "slideshow_interval"
    final intervalMs = _prefs.slideshowInterval.value;
    const tickMs     = 50;
    final totalTicks = intervalMs ~/ tickMs;
    int   tick       = 0;

    _timer = Timer.periodic(
      const Duration(milliseconds: tickMs),
          (_) {
        if (!isPlaying.value) return;
        tick++;
        progress.value = tick / totalTicks;
        if (tick >= totalTicks) {
          progress.value = 0.0;
          tick = 0;
          _advance();
        }
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ─────────────────────────────────────────────────────────
  // PLAYBACK CONTROLS
  // ─────────────────────────────────────────────────────────

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
    if (isPlaying.value) {
      _startTimer();
    } else {
      _stopTimer();
    }
    _showUITemporarily();
  }

  void _advance() {
    if (mediaList.isEmpty) return;

    if (order.value == SlideshowOrder.shuffle) {
      // Random next index (not same as current)
      int next;
      do {
        next = (DateTime.now().millisecondsSinceEpoch %
            mediaList.length)
            .toInt();
      } while (next == currentIndex.value && mediaList.length > 1);
      _goToIndex(next);
    } else {
      // Sequential — loop back
      final next = (currentIndex.value + 1) % mediaList.length;
      _goToIndex(next);
    }
  }

  void goToPrevious() {
    _stopTimer();
    progress.value = 0.0;
    final prev = currentIndex.value > 0
        ? currentIndex.value - 1
        : mediaList.length - 1;
    _goToIndex(prev);
    if (isPlaying.value) _startTimer();
    _showUITemporarily();
  }

  void goToNext() {
    _stopTimer();
    progress.value = 0.0;
    final next = (currentIndex.value + 1) % mediaList.length;
    _goToIndex(next);
    if (isPlaying.value) _startTimer();
    _showUITemporarily();
  }

  void _goToIndex(int index) {
    currentIndex.value = index;
    _updateFavoriteState();

    // Animate to page based on transition
    if (transition.value == SlideshowTransition.slide) {
      pageController?.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeInOut,
      );
    } else {
      pageController?.jumpToPage(index);
    }
  }

  // ─────────────────────────────────────────────────────────
  // UI VISIBILITY
  // ─────────────────────────────────────────────────────────

  void toggleUI() {
    isUIVisible.value = !isUIVisible.value;
    if (isUIVisible.value) _startAutoHideUI();
  }

  void _showUITemporarily() {
    isUIVisible.value = true;
    _startAutoHideUI();
  }

  void _startAutoHideUI() {
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(seconds: 3), () {
      if (isPlaying.value) {
        isUIVisible.value = false;
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // TRANSITION
  // ─────────────────────────────────────────────────────────

  void setTransition(SlideshowTransition t) {
    transition.value = t;
    _showUITemporarily();
  }

  void cycleTransition() {
    final values = SlideshowTransition.values;
    final next   = (values.indexOf(transition.value) + 1) %
        values.length;
    transition.value = values[next];
    _showUITemporarily();
  }

  String get transitionLabel {
    switch (transition.value) {
      case SlideshowTransition.fade:  return 'Fade';
      case SlideshowTransition.slide: return 'Slide';
      case SlideshowTransition.zoom:  return 'Zoom';
      case SlideshowTransition.flip:  return 'Flip';
    }
  }

  // ─────────────────────────────────────────────────────────
  // ORDER
  // ─────────────────────────────────────────────────────────

  void toggleOrder() {
    if (order.value == SlideshowOrder.sequential) {
      order.value = SlideshowOrder.shuffle;
      // Shuffle list
      mediaList.shuffle();
    } else {
      order.value    = SlideshowOrder.sequential;
      mediaList.value = List.from(_originalList);
    }
    _showUITemporarily();
  }

  // ─────────────────────────────────────────────────────────
  // FAVORITE
  // UPDATE media_items SET is_favorite = ? WHERE id = ?
  // ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite() async {
    final item = currentItem;
    if (item == null) return;

    await _db.toggleFavorite(item.id!);

    // Update local list
    final index = mediaList.indexWhere((m) => m.id == item.id);
    if (index != -1) {
      mediaList[index] = item.copyWith(
        isFavorite: !item.isFavorite,
      );
    }

    _updateFavoriteState();
    HapticFeedback.lightImpact();
    _showUITemporarily();
  }

  void _updateFavoriteState() {
    isFavorite.value = currentItem?.isFavorite ?? false;
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  MediaItem? get currentItem =>
      mediaList.isNotEmpty ? mediaList[currentIndex.value] : null;

  String get counter =>
      '${currentIndex.value + 1} / ${mediaList.length}';

  String get intervalLabel {
    final s = _prefs.slideshowInterval.value / 1000;
    return '${s.toStringAsFixed(0)}s';
  }

  bool get isEmpty => mediaList.isEmpty;
}