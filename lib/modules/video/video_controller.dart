import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';

enum VideoQuality { auto, p1080, p720, p480 }
enum VideoRepeat  { none, one, all }

class VideoController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── Video player ────────────────────────────────────────
  VideoPlayerController? playerController;

  // ─── State ───────────────────────────────────────────────
  final mediaList       = <MediaItem>[].obs;
  final currentIndex    = 0.obs;
  final isInitialized   = false.obs;
  final isPlaying       = false.obs;
  final isBuffering     = false.obs;
  final isUIVisible     = true.obs;
  final isFullscreen    = false.obs;
  final isMuted         = false.obs;
  final showInfoPanel   = false.obs;
  final hasError        = false.obs;
  final errorMessage    = ''.obs;

  // ─── Playback ────────────────────────────────────────────
  final position        = Duration.zero.obs;
  final duration        = Duration.zero.obs;
  final buffered        = 0.0.obs;
  final volume          = 1.0.obs;
  final playbackSpeed   = 1.0.obs;
  final repeat          = VideoRepeat.none.obs;
  final isFavorite      = false.obs;

  // ─── Timers ──────────────────────────────────────────────
  Timer? _uiTimer;
  Timer? _positionTimer;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Arguments: {'list': List<MediaItem>, 'index': int}
    final args  = Get.arguments as Map<String, dynamic>;
    final list  = List<MediaItem>.from(args['list'] as List);
    final index = args['index'] as int;

    mediaList.value    = list;
    currentIndex.value = index;

    _initPlayer();
    _enterFullscreen();
    _startAutoHideUI();
  }

  @override
  void onClose() {
    _disposePlayer();
    _uiTimer?.cancel();
    _positionTimer?.cancel();
    _exitFullscreen();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // PLAYER INIT
  // ─────────────────────────────────────────────────────────

  Future<void> _initPlayer() async {
    await _disposePlayer();
    hasError.value    = false;
    isInitialized.value = false;
    isBuffering.value   = true;

    final item = currentItem;
    if (item == null) return;

    try {
      playerController = VideoPlayerController.networkUrl(
        Uri.parse(item.uri),
      );

      await playerController!.initialize();

      // Apply settings
      await playerController!.setVolume(
        isMuted.value ? 0.0 : volume.value,
      );
      await playerController!.setPlaybackSpeed(playbackSpeed.value);

      // Listeners
      playerController!.addListener(_onPlayerUpdate);

      isInitialized.value  = true;
      isBuffering.value    = false;
      duration.value       = playerController!.value.duration;

      // Auto-play
      // SharedPreferences key: "auto_play_video"
      if (_prefs.autoPlayVideo.value) {
        await playerController!.play();
        isPlaying.value = true;
      }

      // Position timer
      _startPositionTimer();
      _updateFavoriteState();

    } catch (e) {
      hasError.value    = true;
      errorMessage.value = 'Failed to load video: $e';
      isBuffering.value = false;
    }
  }

  void _onPlayerUpdate() {
    if (playerController == null) return;
    final value = playerController!.value;

    isBuffering.value = value.isBuffering;
    isPlaying.value   = value.isPlaying;

    // Update buffered
    if (value.buffered.isNotEmpty) {
      final bufferedEnd = value.buffered.last.end;
      buffered.value = bufferedEnd.inMilliseconds /
          (duration.value.inMilliseconds == 0
              ? 1
              : duration.value.inMilliseconds);
    }

    // Video ended
    if (value.position >= value.duration &&
        value.duration > Duration.zero) {
      _onVideoEnd();
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
          (_) {
        if (playerController != null && isInitialized.value) {
          position.value = playerController!.value.position;
        }
      },
    );
  }

  Future<void> _disposePlayer() async {
    _positionTimer?.cancel();
    playerController?.removeListener(_onPlayerUpdate);
    await playerController?.dispose();
    playerController  = null;
    isInitialized.value = false;
    isPlaying.value     = false;
    position.value      = Duration.zero;
    duration.value      = Duration.zero;
    buffered.value      = 0.0;
  }

  // ─────────────────────────────────────────────────────────
  // VIDEO END HANDLER
  // ─────────────────────────────────────────────────────────

  Future<void> _onVideoEnd() async {
    switch (repeat.value) {
      case VideoRepeat.one:
        await playerController?.seekTo(Duration.zero);
        await playerController?.play();
        break;
      case VideoRepeat.all:
        await goToNext();
        break;
      case VideoRepeat.none:
        isPlaying.value = false;
        _showUITemporarily();
        break;
    }
  }

  // ─────────────────────────────────────────────────────────
  // PLAYBACK CONTROLS
  // ─────────────────────────────────────────────────────────

  Future<void> togglePlay() async {
    if (!isInitialized.value) return;
    if (isPlaying.value) {
      await playerController?.pause();
    } else {
      await playerController?.play();
    }
    _showUITemporarily();
  }

  Future<void> seekTo(Duration pos) async {
    if (!isInitialized.value) return;
    await playerController?.seekTo(pos);
    position.value = pos;
    _showUITemporarily();
  }

  Future<void> seekForward() async {
    final target = position.value + const Duration(seconds: 10);
    await seekTo(target > duration.value ? duration.value : target);
  }

  Future<void> seekBackward() async {
    final target = position.value - const Duration(seconds: 10);
    await seekTo(target < Duration.zero ? Duration.zero : target);
  }

  // ─────────────────────────────────────────────────────────
  // VOLUME
  // ─────────────────────────────────────────────────────────

  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    await playerController?.setVolume(isMuted.value ? 0.0 : volume.value);
    _showUITemporarily();
  }

  Future<void> setVolume(double v) async {
    volume.value = v;
    if (!isMuted.value) {
      await playerController?.setVolume(v);
    }
    _showUITemporarily();
  }

  // ─────────────────────────────────────────────────────────
  // SPEED
  // ─────────────────────────────────────────────────────────

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed.value = speed;
    await playerController?.setPlaybackSpeed(speed);
    Get.back(); // close speed sheet
    _showUITemporarily();
  }

  // ─────────────────────────────────────────────────────────
  // REPEAT
  // ─────────────────────────────────────────────────────────

  void cycleRepeat() {
    final values = VideoRepeat.values;
    final next   = (values.indexOf(repeat.value) + 1) % values.length;
    repeat.value = values[next];
    _showUITemporarily();
  }

  String get repeatLabel {
    switch (repeat.value) {
      case VideoRepeat.none: return 'No Repeat';
      case VideoRepeat.one:  return 'Repeat One';
      case VideoRepeat.all:  return 'Repeat All';
    }
  }

  // ─────────────────────────────────────────────────────────
  // NAVIGATION (prev/next video)
  // ─────────────────────────────────────────────────────────

  Future<void> goToPrevious() async {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      await _initPlayer();
      _updateFavoriteState();
    }
  }

  Future<void> goToNext() async {
    if (currentIndex.value < mediaList.length - 1) {
      currentIndex.value++;
      await _initPlayer();
      _updateFavoriteState();
    } else if (repeat.value == VideoRepeat.all) {
      currentIndex.value = 0;
      await _initPlayer();
    }
  }

  // ─────────────────────────────────────────────────────────
  // FULLSCREEN
  // ─────────────────────────────────────────────────────────

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
    if (isFullscreen.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _enterFullscreen();
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      _exitFullscreen();
    }
    _showUITemporarily();
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
    _uiTimer = Timer(const Duration(seconds: 4), () {
      if (isPlaying.value) isUIVisible.value = false;
    });
  }

  // ─────────────────────────────────────────────────────────
  // FAVORITE
  // UPDATE media_items SET is_favorite = ? WHERE id = ?
  // ─────────────────────────────────────────────────────────

  Future<void> toggleFavorite() async {
    final item = currentItem;
    if (item == null) return;

    await _db.toggleFavorite(item.id!);
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
  // INFO PANEL
  // ─────────────────────────────────────────────────────────

  void toggleInfoPanel() {
    showInfoPanel.value = !showInfoPanel.value;
    if (showInfoPanel.value) {
      isUIVisible.value = true;
      _uiTimer?.cancel();
    }
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  MediaItem? get currentItem =>
      mediaList.isNotEmpty ? mediaList[currentIndex.value] : null;

  String get counter =>
      '${currentIndex.value + 1} / ${mediaList.length}';

  bool get hasPrevious => currentIndex.value > 0;
  bool get hasNext     =>
      currentIndex.value < mediaList.length - 1;

  double get progressValue {
    if (duration.value.inMilliseconds == 0) return 0.0;
    return position.value.inMilliseconds /
        duration.value.inMilliseconds;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String get positionLabel  => _formatDuration(position.value);
  String get durationLabel  => _formatDuration(duration.value);
  String get speedLabel     => '${playbackSpeed.value}x';
}