import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/media_item.dart';
import '../../core/theme/app_text_styles.dart';
import 'stories_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/empty_state_widget.dart';

class StoriesView extends GetView<StoriesController> {
  const StoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      body: Obx(() {
        // Story viewer fullscreen overlay
        if (controller.isViewerOpen.value) {
          return _StoryViewer(controller: controller);
        }
        return _StoriesBody(controller: controller);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STORIES BODY
// ─────────────────────────────────────────────────────────────

class _StoriesBody extends StatelessWidget {
  final StoriesController controller;
  const _StoriesBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [_buildAppBar()],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerGrid(columnCount: 2);
        }
        if (controller.isEmpty) {
          return const EmptyStateWidget(
            icon:    Icons.auto_stories_outlined,
            message: 'No stories yet.\nTake more photos!',
          );
        }
        return _buildContent();
      }),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating:        true,
      snap:            true,
      backgroundColor: SamsungColors.darkAppBar,
      elevation:       0,
      title:           Text('Stories', style: AppTextStyles.appBarTitle()),
      actions: [
        IconButton(
          icon:      const Icon(Icons.refresh),
          onPressed: controller.loadStories,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color:     SamsungColors.primary,
      onRefresh: controller.loadStories,
      child: CustomScrollView(
        slivers: [

          // ─── On This Day ──────────────────────────────
          Obx(() => controller.hasOnThisDay
              ? SliverToBoxAdapter(
            child: _OnThisDayBanner(controller: controller),
          )
              : const SliverToBoxAdapter(child: SizedBox.shrink())),

          // ─── Section label ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.lg,
                AppDimensions.lg,
                AppDimensions.lg,
                AppDimensions.sm,
              ),
              child: Text(
                'MEMORIES',
                style: AppTextStyles.dateSectionHeader(),
              ),
            ),
          ),

          // ─── Stories Grid ─────────────────────────────
          Obx(() => SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
            ),
            sliver: SliverGrid(
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: AppDimensions.md,
                mainAxisSpacing:  AppDimensions.md,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                    (_, index) {
                  final story = controller.stories[index];
                  return _StoryCard(
                    story:   story,
                    typeLabel: controller.storyTypeLabel(story.type),
                    onTap:   () => controller.openStory(story),
                  );
                },
                childCount: controller.stories.length,
              ),
            ),
          )),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ON THIS DAY BANNER
// ─────────────────────────────────────────────────────────────

class _OnThisDayBanner extends StatelessWidget {
  final StoriesController controller;
  const _OnThisDayBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return GestureDetector(
      onTap: controller.openOnThisDay,
      child: Container(
        height:  180,
        margin:  const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          color:        SamsungColors.darkCard,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // Cover image
            Obx(() {
              final item = controller.onThisDayItems.first;
              return ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusLg,
                ),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUri,
                  fit:      BoxFit.cover,
                ),
              );
            }),

            // Gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusLg,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topCenter,
                    end:    Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Text overlay
            Positioned(
              bottom: AppDimensions.lg,
              left:   AppDimensions.lg,
              right:  AppDimensions.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical:   3,
                    ),
                    decoration: BoxDecoration(
                      color:        SamsungColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ON THIS DAY',
                      style: AppTextStyles.caption(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    '${_dayName(now.day)} ${_monthName(now.month)}',
                    style: AppTextStyles.displayMedium(),
                  ),
                  Obx(() => Text(
                    '${controller.onThisDayItems.length} memories',
                    style: AppTextStyles.bodySmall(
                      color: Colors.white70,
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayName(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:  return '${day}st';
      case 2:  return '${day}nd';
      case 3:  return '${day}rd';
      default: return '${day}th';
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────────
// STORY CARD
// ─────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final Story        story;
  final String       typeLabel;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.typeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // Cover image
            CachedNetworkImage(
              imageUrl:    story.coverUri,
              fit:         BoxFit.cover,
              placeholder: (_, __) => Container(
                color: SamsungColors.darkCard,
              ),
            ),

            // Gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

            // Type label badge
            Positioned(
              top:  AppDimensions.sm,
              left: AppDimensions.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.xs + 2,
                  vertical:   2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  typeLabel,
                  style: AppTextStyles.caption(
                    color: SamsungColors.primary,
                  ),
                ),
              ),
            ),

            // Bottom info
            Positioned(
              bottom: AppDimensions.sm,
              left:   AppDimensions.sm,
              right:  AppDimensions.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  Text(
                    story.title,
                    style:    AppTextStyles.headingSmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    story.subtitle,
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
            ),

            // Multi-photo indicator (top right)
            if (story.count > 1)
              Positioned(
                top:   AppDimensions.sm,
                right: AppDimensions.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical:   2,
                  ),
                  decoration: BoxDecoration(
                    color:        Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size:  10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${story.count}',
                        style: AppTextStyles.caption(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STORY VIEWER (fullscreen Instagram-style)
// ─────────────────────────────────────────────────────────────

class _StoryViewer extends StatelessWidget {
  final StoriesController controller;
  const _StoryViewer({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return WillPopScope(
      onWillPop: () async {
        controller.closeStory();
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        return false;
      },
      child: GestureDetector(
        onTapDown: (details) {
          final width = context.width;
          if (details.globalPosition.dx < width / 2) {
            controller.previousStoryItem();
          } else {
            controller.nextStoryItem();
          }
        },
        onLongPressStart: (_) => controller.isPaused.value = true,
        onLongPressEnd:   (_) => controller.isPaused.value = false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Obx(() {
            final story = controller.activeStory.value;
            final item  = controller.activeItem;
            if (story == null || item == null) {
              return const SizedBox.shrink();
            }

            return Stack(
              fit: StackFit.expand,
              children: [

                // ─── Full photo ─────────────────────────
                CachedNetworkImage(
                  imageUrl:    item.uri,
                  fit:         BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: SamsungColors.primary,
                    ),
                  ),
                ),

                // ─── Gradient top ───────────────────────
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topCenter,
                      end:    Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // ─── Progress bars ──────────────────────
                Positioned(
                  top:   MediaQuery.of(context).padding.top + 8,
                  left:  AppDimensions.sm,
                  right: AppDimensions.sm,
                  child: _ProgressBars(
                    story:   story,
                    current: controller.activeIndex.value,
                    progress: controller.viewerProgress.value,
                  ),
                ),

                // ─── Top bar ────────────────────────────
                Positioned(
                  top:   MediaQuery.of(context).padding.top + 24,
                  left:  AppDimensions.sm,
                  right: AppDimensions.sm,
                  child: _StoryTopBar(
                    story:      story,
                    controller: controller,
                  ),
                ),

                // ─── Bottom actions ─────────────────────
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom +
                      AppDimensions.lg,
                  left:   AppDimensions.lg,
                  right:  AppDimensions.lg,
                  child: _StoryBottomBar(
                    item:       item,
                    controller: controller,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROGRESS BARS
// ─────────────────────────────────────────────────────────────

class _ProgressBars extends StatelessWidget {
  final Story  story;
  final int    current;
  final double progress;

  const _ProgressBars({
    required this.story,
    required this.current,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(story.count, (index) {
        return Expanded(
          child: Container(
            height:  2.5,
            margin:  const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color:        Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: index < current
                  ? 1.0
                  : index == current
                  ? progress
                  : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STORY TOP BAR
// ─────────────────────────────────────────────────────────────

class _StoryTopBar extends StatelessWidget {
  final Story             story;
  final StoriesController controller;

  const _StoryTopBar({
    required this.story,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Story cover avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: CachedNetworkImage(
            imageUrl: story.coverUri,
            width:    36,
            height:   36,
            fit:      BoxFit.cover,
          ),
        ),

        const SizedBox(width: AppDimensions.sm),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                story.title,
                style: AppTextStyles.headingSmall(),
              ),
              Text(
                story.subtitle,
                style: AppTextStyles.caption(),
              ),
            ],
          ),
        ),

        // Pause / Play
        Obx(() => IconButton(
          icon: Icon(
            controller.isPaused.value
                ? Icons.play_arrow
                : Icons.pause,
            color: Colors.white,
          ),
          onPressed: controller.togglePause,
          padding:   EdgeInsets.zero,
        )),

        // Close
        IconButton(
          icon:      const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            controller.closeStory();
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: SystemUiOverlay.values,
            );
          },
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STORY BOTTOM BAR
// ─────────────────────────────────────────────────────────────

class _StoryBottomBar extends StatelessWidget {
  final MediaItem         item;
  final StoriesController controller;

  const _StoryBottomBar({
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filename + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                item.filename,
                style:    AppTextStyles.bodySmall(),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatDate(item.dateTime),
                style: AppTextStyles.caption(),
              ),
            ],
          ),
        ),

        // Open in viewer
        IconButton(
          icon:      const Icon(Icons.open_in_full, color: Colors.white),
          onPressed: () => controller.openPhotoViewer(
            controller.activeIndex.value,
          ),
        ),

        // Share
        IconButton(
          icon:      const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}