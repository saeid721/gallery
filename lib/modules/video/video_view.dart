import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_text_styles.dart';
import 'video_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class VideoView extends GetView<VideoController> {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.isFullscreen.value) {
          controller.toggleFullscreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap:          controller.toggleUI,
          onDoubleTapDown: (details) {
            // Double tap left → rewind, right → forward
            final width = context.width;
            if (details.globalPosition.dx < width / 2) {
              controller.seekBackward();
            } else {
              controller.seekForward();
            }
          },
          child: Obx(() => Stack(
            fit: StackFit.expand,
            children: [

              // ─── Video player ────────────────────────
              _VideoDisplay(controller: controller),

              // ─── Buffering indicator ─────────────────
              if (controller.isBuffering.value)
                const Center(
                  child: CircularProgressIndicator(
                    color:       SamsungColors.primary,
                    strokeWidth: 2,
                  ),
                ),

              // ─── Error state ─────────────────────────
              if (controller.hasError.value)
                _ErrorState(controller: controller),

              // ─── Top bar ─────────────────────────────
              AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _TopBar(controller: controller),
              ),

              // ─── Center controls ─────────────────────
              AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _CenterControls(controller: controller),
              ),

              // ─── Bottom controls ─────────────────────
              AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _BottomControls(controller: controller),
              ),

              // ─── Info panel ──────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve:    Curves.easeInOut,
                bottom:   controller.showInfoPanel.value ? 0 : -500,
                left:  0,
                right: 0,
                child: _InfoPanel(controller: controller),
              ),

              // ─── Counter badge ────────────────────────
              AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _CounterBadge(controller: controller),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VIDEO DISPLAY
// ─────────────────────────────────────────────────────────────

class _VideoDisplay extends StatelessWidget {
  final VideoController controller;
  const _VideoDisplay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isInitialized.value ||
          controller.playerController == null) {
        return Container(color: Colors.black);
      }

      return Center(
        child: AspectRatio(
          aspectRatio: controller
              .playerController!.value.aspectRatio,
          child: VideoPlayer(controller.playerController!),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VideoController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top:   0,
      left:  0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPad),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Obx(() => AppBar(
          backgroundColor: Colors.transparent,
          elevation:       0,
          leading: IconButton(
            icon:      const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: Get.back,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                controller.currentItem?.filename ?? '',
                style:    AppTextStyles.bodyMedium(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                controller.durationLabel,
                style: AppTextStyles.caption(color: Colors.white60),
              ),
            ],
          ),
          actions: [
            // Favorite
            IconButton(
              icon: Icon(
                controller.isFavorite.value
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: controller.isFavorite.value
                    ? SamsungColors.favorite
                    : Colors.white,
              ),
              onPressed: controller.toggleFavorite,
            ),

            // Speed
            GestureDetector(
              onTap: () => _showSpeedSheet(),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical:   4,
                ),
                decoration: BoxDecoration(
                  color:        Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Obx(() => Text(
                  controller.speedLabel,
                  style: AppTextStyles.caption(color: Colors.white),
                )),
              ),
            ),

            // More
            PopupMenuButton<String>(
              icon:        const Icon(Icons.more_vert, color: Colors.white),
              color:       const Color(0xFF2C2C2E),
              onSelected:  (v) {
                if (v == 'info') controller.toggleInfoPanel();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'info',
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Details',
                        style: TextStyle(color: Colors.white)),
                  ]),
                ),
              ],
            ),
          ],
        )),
      ),
    );
  }

  void _showSpeedSheet() {
    Get.bottomSheet(
      _SpeedSheet(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CENTER CONTROLS
// ─────────────────────────────────────────────────────────────

class _CenterControls extends StatelessWidget {
  final VideoController controller;
  const _CenterControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Previous
          if (controller.hasPrevious)
            _ControlButton(
              icon:    Icons.skip_previous,
              size:    36,
              onTap:   controller.goToPrevious,
            ),

          const SizedBox(width: AppDimensions.xl),

          // Rewind 10s
          _ControlButton(
            icon:    Icons.replay_10,
            size:    36,
            onTap:   controller.seekBackward,
          ),

          const SizedBox(width: AppDimensions.xl),

          // Play / Pause
          GestureDetector(
            onTap: controller.togglePlay,
            child: Container(
              width:      68,
              height:     68,
              decoration: BoxDecoration(
                color:  Colors.white24,
                shape:  BoxShape.circle,
                border: Border.all(
                  color: Colors.white30,
                  width: 1.5,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: controller.isBuffering.value
                    ? const SizedBox(
                  width:  28,
                  height: 28,
                  child:  CircularProgressIndicator(
                    color:       Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  key: ValueKey(controller.isPlaying.value),
                  controller.isPlaying.value
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size:  36,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.xl),

          // Forward 10s
          _ControlButton(
            icon:  Icons.forward_10,
            size:  36,
            onTap: controller.seekForward,
          ),

          const SizedBox(width: AppDimensions.xl),

          // Next
          if (controller.hasNext)
            _ControlButton(
              icon:  Icons.skip_next,
              size:  36,
              onTap: controller.goToNext,
            ),
        ],
      )),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData     icon;
  final double       size;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:      size + 12,
        height:     size + 12,
        decoration: const BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM CONTROLS
// ─────────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final VideoController controller;
  const _BottomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left:   0,
      right:  0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: botPad + AppDimensions.md,
          left:   AppDimensions.lg,
          right:  AppDimensions.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.bottomCenter,
            end:    Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ─── Seek bar ──────────────────────────────
            Obx(() => _SeekBar(controller: controller)),

            const SizedBox(height: AppDimensions.sm),

            // ─── Bottom row ────────────────────────────
            Obx(() => Row(
              children: [

                // Mute
                _SmallButton(
                  icon: controller.isMuted.value
                      ? Icons.volume_off
                      : Icons.volume_up,
                  onTap: controller.toggleMute,
                ),

                const SizedBox(width: AppDimensions.sm),

                // Volume slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   Colors.white,
                      inactiveTrackColor: Colors.white30,
                      thumbColor:         Colors.white,
                      overlayColor:       Colors.white24,
                      trackHeight:        2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value:    controller.isMuted.value
                          ? 0.0
                          : controller.volume.value,
                      min:      0.0,
                      max:      1.0,
                      onChanged: controller.setVolume,
                    ),
                  ),
                ),

                const SizedBox(width: AppDimensions.sm),

                // Repeat
                _SmallButton(
                  icon:  _repeatIcon(controller.repeat.value),
                  color: controller.repeat.value != VideoRepeat.none
                      ? SamsungColors.primary
                      : Colors.white,
                  onTap: controller.cycleRepeat,
                ),

                const SizedBox(width: AppDimensions.sm),

                // Fullscreen
                _SmallButton(
                  icon: controller.isFullscreen.value
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  onTap: controller.toggleFullscreen,
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  IconData _repeatIcon(VideoRepeat r) {
    switch (r) {
      case VideoRepeat.none: return Icons.repeat;
      case VideoRepeat.one:  return Icons.repeat_one;
      case VideoRepeat.all:  return Icons.repeat_on;
    }
  }
}

class _SmallButton extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEEK BAR
// ─────────────────────────────────────────────────────────────

class _SeekBar extends StatelessWidget {
  final VideoController controller;
  const _SeekBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // Position + Duration
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.positionLabel,
              style: AppTextStyles.caption(color: Colors.white),
            ),
            Text(
              controller.durationLabel,
              style: AppTextStyles.caption(color: Colors.white60),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Seek slider with buffered track
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Buffered track
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:            controller.buffered.value,
                backgroundColor:  Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.white30,
                ),
                minHeight: 3,
              ),
            ),

            // Seek slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor:   SamsungColors.primary,
                inactiveTrackColor: Colors.transparent,
                thumbColor:         Colors.white,
                overlayColor:       SamsungColors.primary.withOpacity(0.2),
                trackHeight:        3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14,
                ),
              ),
              child: Slider(
                value:    controller.progressValue
                    .clamp(0.0, 1.0),
                min:      0.0,
                max:      1.0,
                onChanged: (v) {
                  final target = Duration(
                    milliseconds: (v *
                        controller.duration.value.inMilliseconds)
                        .toInt(),
                  );
                  controller.seekTo(target);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COUNTER BADGE
// ─────────────────────────────────────────────────────────────

class _CounterBadge extends StatelessWidget {
  final VideoController controller;
  const _CounterBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top:   topPad + 58,
      right: AppDimensions.lg,
      child: Obx(() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical:   AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color:        Colors.black54,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusFull,
          ),
        ),
        child: Text(
          controller.counter,
          style: AppTextStyles.caption(color: Colors.white),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INFO PANEL
// ─────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final VideoController controller;
  const _InfoPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.currentItem;
      if (item == null) return const SizedBox.shrink();

      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppDimensions.md),
                width:  40,
                height: 4,
                decoration: BoxDecoration(
                  color:        SamsungColors.darkDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(
                children: [
                  Text('Details',
                      style: AppTextStyles.headingMedium()),
                  const Spacer(),
                  IconButton(
                    icon:      const Icon(Icons.close,
                        color: Colors.white),
                    onPressed: controller.toggleInfoPanel,
                    padding:   EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: SamsungColors.darkDivider),

            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                children: [
                  _InfoRow(
                    icon:  Icons.movie_outlined,
                    label: 'Filename',
                    value: item.filename,
                  ),
                  _InfoRow(
                    icon:  Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(item.dateTime),
                  ),
                  _InfoRow(
                    icon:  Icons.timer_outlined,
                    label: 'Duration',
                    value: controller.durationLabel,
                  ),
                  _InfoRow(
                    icon:  Icons.photo_size_select_large_outlined,
                    label: 'Resolution',
                    value: '${item.width} × ${item.height}',
                  ),
                  _InfoRow(
                    icon:  Icons.storage_outlined,
                    label: 'File Size',
                    value: item.formattedSize,
                  ),
                  if (item.hasLocation)
                    _InfoRow(
                      icon:       Icons.location_on_outlined,
                      label:      'Location',
                      value: '${item.latitude!.toStringAsFixed(4)}, '
                          '${item.longitude!.toStringAsFixed(4)}',
                      valueColor: SamsungColors.primary,
                    ),
                ],
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      );
    });
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   iconColor;
  final Color?   valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? SamsungColors.textSecondaryDark,
            size:  AppDimensions.iconSm,
          ),
          const SizedBox(width: AppDimensions.md),
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTextStyles.bodySmall()),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium(
                color: valueColor ?? SamsungColors.textPrimaryDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPEED SHEET
// ─────────────────────────────────────────────────────────────

class _SpeedSheet extends StatelessWidget {
  final VideoController controller;
  const _SpeedSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return Container(
      decoration: const BoxDecoration(
        color: SamsungColors.darkSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppDimensions.md),
              width:  40,
              height: 4,
              decoration: BoxDecoration(
                color:        SamsungColors.darkDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Text(
              'Playback Speed',
              style: AppTextStyles.headingMedium(),
            ),
          ),

          const Divider(height: 1, color: SamsungColors.darkDivider),

          // Speed options
          Obx(() => Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Wrap(
              spacing:    AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: speeds.map((s) {
                final isActive =
                    controller.playbackSpeed.value == s;
                return GestureDetector(
                  onTap: () => controller.setPlaybackSpeed(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:  const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical:   AppDimensions.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? SamsungColors.primary
                          : SamsungColors.darkCard,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Text(
                      '${s}x',
                      style: AppTextStyles.bodyMedium(
                        color: isActive
                            ? Colors.black
                            : SamsungColors.textPrimaryDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                AppDimensions.lg,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VideoController controller;
  const _ErrorState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: SamsungColors.deleteRed,
            size:  64,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Failed to load video',
            style: AppTextStyles.headingMedium(),
          ),
          const SizedBox(height: AppDimensions.sm),
          Obx(() => Text(
            controller.errorMessage.value,
            style:     AppTextStyles.caption(),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: AppDimensions.xl),
          TextButton(
            onPressed: controller.onInit,
            child: Text(
              'Retry',
              style: AppTextStyles.button(),
            ),
          ),
        ],
      ),
    );
  }
}