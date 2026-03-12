import 'package:get/get.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preferences_service.dart';
import '../../models/media_item.dart';
import '../../app/routes/app_routes.dart';

// ─── Story Model ─────────────────────────────────────────────
class Story {
  final String        title;
  final String        subtitle;
  final String        coverUri;
  final List<MediaItem> items;
  final StoryType     type;

  const Story({
    required this.title,
    required this.subtitle,
    required this.coverUri,
    required this.items,
    required this.type,
  });

  int get count => items.length;
}

enum StoryType {
  thisDay,      // On This Day
  thisWeek,     // This Week
  thisMonth,    // This Month
  lastMonth,    // Last Month
  highlight,    // Auto-generated highlight
}

class StoriesController extends GetxController {

  // ─── Dependencies ────────────────────────────────────────
  final _db    = Get.find<DatabaseHelper>();
  final _prefs = Get.find<PreferencesService>();

  // ─── State ───────────────────────────────────────────────
  final allMedia        = <MediaItem>[].obs;
  final stories         = <Story>[].obs;
  final onThisDayItems  = <MediaItem>[].obs;
  final isLoading       = true.obs;
  final activeStory     = Rx<Story?>(null);
  final activeIndex     = 0.obs;

  // Story viewer state
  final isViewerOpen    = false.obs;
  final viewerProgress  = 0.0.obs;
  final isPaused        = false.obs;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  @override
  void onClose() {
    _stopProgress();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD STORIES
  // SELECT * FROM media_items WHERE is_deleted = 0
  // ─────────────────────────────────────────────────────────

  Future<void> loadStories() async {
    isLoading.value = true;
    try {
      // Load all media
      final result = await _db.getAllMedia(
        sortBy:    'date_added',
        sortOrder: 'DESC',
      );
      allMedia.value = result;

      // Generate stories from media
      _generateStories(result);
      _generateOnThisDay(result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load stories',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // GENERATE STORIES
  // Groups media by time period into story cards
  // ─────────────────────────────────────────────────────────

  void _generateStories(List<MediaItem> media) {
    if (media.isEmpty) {
      stories.value = [];
      return;
    }

    final now       = DateTime.now();
    final generated = <Story>[];

    // ─── This Week ──────────────────────────────────────
    final thisWeek = media.where((m) {
      final diff = now.difference(m.dateTime).inDays;
      return diff <= 7;
    }).toList();

    if (thisWeek.isNotEmpty) {
      generated.add(Story(
        title:    'This Week',
        subtitle: '${thisWeek.length} photos',
        coverUri: thisWeek.first.thumbnailUri,
        items:    thisWeek,
        type:     StoryType.thisWeek,
      ));
    }

    // ─── This Month ─────────────────────────────────────
    final thisMonth = media.where((m) {
      return m.dateTime.month == now.month &&
          m.dateTime.year  == now.year;
    }).toList();

    if (thisMonth.isNotEmpty) {
      generated.add(Story(
        title:    _monthName(now.month),
        subtitle: '${thisMonth.length} photos',
        coverUri: thisMonth.first.thumbnailUri,
        items:    thisMonth,
        type:     StoryType.thisMonth,
      ));
    }

    // ─── Last Month ──────────────────────────────────────
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthItems = media.where((m) {
      return m.dateTime.month == lastMonth.month &&
          m.dateTime.year  == lastMonth.year;
    }).toList();

    if (lastMonthItems.isNotEmpty) {
      generated.add(Story(
        title:    _monthName(lastMonth.month),
        subtitle: '${lastMonthItems.length} photos',
        coverUri: lastMonthItems.first.thumbnailUri,
        items:    lastMonthItems,
        type:     StoryType.lastMonth,
      ));
    }

    // ─── Auto Highlights (by album) ──────────────────────
    // Group media by albumId → create highlight per album
    final Map<int, List<MediaItem>> byAlbum = {};
    for (final m in media) {
      if (m.albumId != null) {
        byAlbum.putIfAbsent(m.albumId!, () => []).add(m);
      }
    }

    for (final entry in byAlbum.entries) {
      if (entry.value.length >= 3) {
        generated.add(Story(
          title:    'Album ${entry.key}',
          subtitle: '${entry.value.length} photos',
          coverUri: entry.value.first.thumbnailUri,
          items:    entry.value,
          type:     StoryType.highlight,
        ));
      }
    }

    stories.value = generated;
  }

  // ─── On This Day ─────────────────────────────────────────
  // Same month + day, any year
  void _generateOnThisDay(List<MediaItem> media) {
    final now = DateTime.now();
    onThisDayItems.value = media.where((m) {
      return m.dateTime.month == now.month &&
          m.dateTime.day   == now.day   &&
          m.dateTime.year  != now.year;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────
  // STORY VIEWER
  // ─────────────────────────────────────────────────────────

  void openStory(Story story) {
    activeStory.value = story;
    activeIndex.value = 0;
    isViewerOpen.value = true;
    _startProgress();
  }

  void closeStory() {
    _stopProgress();
    isViewerOpen.value  = false;
    activeStory.value   = null;
    activeIndex.value   = 0;
    viewerProgress.value = 0.0;
    isPaused.value      = false;
  }

  void nextStoryItem() {
    final story = activeStory.value;
    if (story == null) return;

    if (activeIndex.value < story.items.length - 1) {
      activeIndex.value++;
      viewerProgress.value = 0.0;
      _startProgress();
    } else {
      closeStory();
    }
  }

  void previousStoryItem() {
    if (activeIndex.value > 0) {
      activeIndex.value--;
      viewerProgress.value = 0.0;
      _startProgress();
    }
  }

  void togglePause() {
    isPaused.value = !isPaused.value;
  }

  // ─────────────────────────────────────────────────────────
  // PROGRESS TIMER
  // SharedPreferences key: "slideshow_interval"
  // ─────────────────────────────────────────────────────────

  Worker? _progressWorker;

  void _startProgress() {
    _stopProgress();
    viewerProgress.value = 0.0;

    // Duration per story item
    // SharedPreferences key: "slideshow_interval"
    final duration = _prefs.slideshowInterval.value;
    const steps    = 100;
    final interval = duration ~/ steps;

    int tick = 0;
    _progressWorker = ever(
      RxInt(0)..value = 0,
          (_) {},
    );

    // Use periodic timer simulation via GetX
    _runTimer(tick, steps, interval);
  }

  void _runTimer(int tick, int steps, int interval) async {
    while (tick < steps && isViewerOpen.value) {
      await Future.delayed(Duration(milliseconds: interval));
      if (!isViewerOpen.value) break;
      if (isPaused.value)      continue;
      tick++;
      viewerProgress.value = tick / steps;
      if (tick >= steps)       nextStoryItem();
    }
  }

  void _stopProgress() {
    _progressWorker?.dispose();
    _progressWorker = null;
  }

  // ─────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────

  void openPhotoViewer(int index) {
    final story = activeStory.value;
    if (story == null) return;

    Get.toNamed(
      Routes.photoViewer,
      arguments: {
        'list':  story.items,
        'index': index,
      },
    );
  }

  void openOnThisDay() {
    if (onThisDayItems.isEmpty) return;
    Get.toNamed(
      Routes.photoViewer,
      arguments: {
        'list':  onThisDayItems.toList(),
        'index': 0,
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August', 'September',
      'October', 'November', 'December',
    ];
    return months[month];
  }

  String storyTypeLabel(StoryType type) {
    switch (type) {
      case StoryType.thisDay:   return 'ON THIS DAY';
      case StoryType.thisWeek:  return 'THIS WEEK';
      case StoryType.thisMonth: return 'THIS MONTH';
      case StoryType.lastMonth: return 'LAST MONTH';
      case StoryType.highlight: return 'HIGHLIGHT';
    }
  }

  // ─────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────

  bool get isEmpty           => stories.isEmpty && !isLoading.value;
  bool get hasOnThisDay      => onThisDayItems.isNotEmpty;
  MediaItem? get activeItem  =>
      activeStory.value?.items[activeIndex.value];
}