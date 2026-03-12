import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'slideshow_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/media_item.dart';

class SlideshowView extends GetView<SlideshowController> {
  const SlideshowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isEmpty) {
          return const Center(
            child: Text(
              'No photos',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return GestureDetector(
          onTap:      controller.toggleUI,
          child: Stack(
            fit: StackFit.expand,
            children: [

              // ─── Photo display ──────────────────────────
              _SlideshowPageView(controller: controller),

              // ─── Progress bar (top) ─────────────────────
              _ProgressBar(controller: controller),

              // ─── Top bar ────────────────────────────────
              Obx(() => AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _TopBar(controller: controller),
              )),

              // ─── Center controls ────────────────────────
              Obx(() => AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _CenterControls(controller: controller),
              )),

              // ─── Bottom bar ─────────────────────────────
              Obx(() => AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _BottomBar(controller: controller),
              )),

              // ─── Counter badge ──────────────────────────
              Obx(() => AnimatedOpacity(
                opacity:  controller.isUIVisible.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _CounterBadge(controller: controller),
              )),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIDESHOW PAGE VIEW
// ─────────────────────────────────────────────────────────────

class _SlideshowPageView extends StatelessWidget {
  final SlideshowController controller;
  const _SlideshowPageView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = controller.transition.value;

      return PageView.builder(
        controller:   controller.pageController,
        physics:      const NeverScrollableScrollPhysics(),
        itemCount:    controller.mediaList.length,
        onPageChanged: (i) => controller.currentIndex.value = i,
        itemBuilder:  (_, index) {
          final item = controller.mediaList[index];
          return _buildPage(item, t);
        },
      );
    });
  }

  Widget _buildPage(MediaItem item, SlideshowTransition t) {
    switch (t) {
      case SlideshowTransition.fade:
        return _FadePage(item: item);
      case SlideshowTransition.slide:
        return _SlidePage(item: item);
      case SlideshowTransition.zoom:
        return _ZoomPage(item: item);
      case SlideshowTransition.flip:
        return _FlipPage(item: item);
    }
  }
}

// ─── Fade page ───────────────────────────────────────────────
class _FadePage extends StatefulWidget {
  final MediaItem item;
  const _FadePage({required this.item});

  @override
  State<_FadePage> createState() => _FadePageState();
}

class _FadePageState extends State<_FadePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child:   _PhotoBackground(item: widget.item),
    );
  }
}

// ─── Slide page ──────────────────────────────────────────────
class _SlidePage extends StatefulWidget {
  final MediaItem item;
  const _SlidePage({required this.item});

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset>   _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    );
    _offset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child:    _PhotoBackground(item: widget.item),
    );
  }
}

// ─── Zoom page ───────────────────────────────────────────────
class _ZoomPage extends StatefulWidget {
  final MediaItem item;
  const _ZoomPage({required this.item});

  @override
  State<_ZoomPage> createState() => _ZoomPageState();
}

class _ZoomPageState extends State<_ZoomPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: _PhotoBackground(item: widget.item),
      ),
    );
  }
}

// ─── Flip page ───────────────────────────────────────────────
class _FlipPage extends StatefulWidget {
  final MediaItem item;
  const _FlipPage({required this.item});

  @override
  State<_FlipPage> createState() => _FlipPageState();
}

class _FlipPageState extends State<_FlipPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _rotation;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    );
    _rotation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder:   (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_rotation.value),
          child: child,
        ),
      ),
      child: _PhotoBackground(item: widget.item),
    );
  }
}

// ─── Photo background ────────────────────────────────────────
class _PhotoBackground extends StatelessWidget {
  final MediaItem item;
  const _PhotoBackground({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        CachedNetworkImage(
          imageUrl:       item.uri,
          fit:            BoxFit.cover,
          color:          Colors.black54,
          colorBlendMode: BlendMode.darken,
        ),

        // Main image (contain)
        CachedNetworkImage(
          imageUrl:    item.uri,
          fit:         BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(
              color:       SamsungColors.primary,
              strokeWidth: 2,
            ),
          ),
          errorWidget: (_, __, ___) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white30,
              size:  64,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final SlideshowController controller;
  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:   0,
      left:  0,
      right: 0,
      child: Obx(() => LinearProgressIndicator(
        value:            controller.progress.value,
        backgroundColor:  Colors.white24,
        valueColor:       const AlwaysStoppedAnimation<Color>(
          SamsungColors.primary,
        ),
        minHeight: 2.5,
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final SlideshowController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top:   0,
      left:  0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPad + 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Obx(() => AppBar(
          backgroundColor: Colors.transparent,
          elevation:       0,
          leading: IconButton(
            icon:      const Icon(Icons.close, color: Colors.white),
            onPressed: Get.back,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                controller.currentItem?.filename ?? '',
                style:    AppTextStyles.bodySmall(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatDate(
                  controller.currentItem?.dateTime ?? DateTime.now(),
                ),
                style: AppTextStyles.caption(
                  color: Colors.white60,
                ),
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

            // Transition cycle
            IconButton(
              tooltip:   controller.transitionLabel,
              icon: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
              onPressed: controller.cycleTransition,
            ),

            // Shuffle toggle
            IconButton(
              icon: Icon(
                controller.order.value == SlideshowOrder.shuffle
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,
                color: controller.order.value == SlideshowOrder.shuffle
                    ? SamsungColors.primary
                    : Colors.white,
              ),
              onPressed: controller.toggleOrder,
            ),
          ],
        )),
      ),
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

// ─────────────────────────────────────────────────────────────
// CENTER CONTROLS
// ─────────────────────────────────────────────────────────────

class _CenterControls extends StatelessWidget {
  final SlideshowController controller;
  const _CenterControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // Previous
          GestureDetector(
            onTap: controller.goToPrevious,
            child: Container(
              width:  80,
              height: double.infinity,
              color:  Colors.transparent,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: AppDimensions.lg),
                  child: _NavButton(icon: Icons.chevron_left),
                ),
              ),
            ),
          ),

          // Play / Pause (center tap)
          GestureDetector(
            onTap: controller.togglePlay,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: controller.isPlaying.value
                  ? const SizedBox.shrink()
                  : Container(
                key:         const ValueKey('pause_icon'),
                width:       64,
                height:      64,
                decoration:  BoxDecoration(
                  color:        Colors.black54,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusFull,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size:  36,
                ),
              ),
            ),
          ),

          // Next
          GestureDetector(
            onTap: controller.goToNext,
            child: Container(
              width:  80,
              height: double.infinity,
              color:  Colors.transparent,
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: AppDimensions.lg),
                  child: _NavButton(icon: Icons.chevron_right),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  const _NavButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:      40,
      height:     40,
      decoration: BoxDecoration(
        color:        Colors.black38,
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusFull,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final SlideshowController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left:   0,
      right:  0,
      child: Container(
        padding: EdgeInsets.only(bottom: botPad + AppDimensions.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.bottomCenter,
            end:    Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ─── Play/Pause + interval ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play / Pause button
                Obx(() => _CircleButton(
                  icon: controller.isPlaying.value
                      ? Icons.pause
                      : Icons.play_arrow,
                  onTap: controller.togglePlay,
                  size: 52,
                )),

                const SizedBox(width: AppDimensions.xl),

                // Interval indicator
                // SharedPreferences key: "slideshow_interval"
                Obx(() => _IntervalBadge(
                  label: controller.intervalLabel,
                )),
              ],
            ),

            const SizedBox(height: AppDimensions.md),

            // ─── Transition selector ────────────────────
            Obx(() => _TransitionSelector(
              current:   controller.transition.value,
              onSelect:  controller.setTransition,
            )),

            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COUNTER BADGE
// ─────────────────────────────────────────────────────────────

class _CounterBadge extends StatelessWidget {
  final SlideshowController controller;
  const _CounterBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Positioned(
      top:   topPad + 60,
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
// TRANSITION SELECTOR
// ─────────────────────────────────────────────────────────────

class _TransitionSelector extends StatelessWidget {
  final SlideshowTransition          current;
  final Function(SlideshowTransition) onSelect;

  const _TransitionSelector({
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SlideshowTransition.values.map((t) {
        final isActive = current == t;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical:   AppDimensions.xs,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? SamsungColors.primary
                  : Colors.white24,
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusFull,
              ),
            ),
            child: Text(
              _label(t),
              style: AppTextStyles.caption(
                color: isActive ? Colors.black : Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(SlideshowTransition t) {
    switch (t) {
      case SlideshowTransition.fade:  return 'Fade';
      case SlideshowTransition.slide: return 'Slide';
      case SlideshowTransition.zoom:  return 'Zoom';
      case SlideshowTransition.flip:  return 'Flip';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// INTERVAL BADGE
// ─────────────────────────────────────────────────────────────

class _IntervalBadge extends StatelessWidget {
  final String label;
  const _IntervalBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical:   AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color:        Colors.white24,
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusFull,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: Colors.white,
            size:  14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CIRCLE BUTTON
// ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final double       size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:      size,
        height:     size,
        decoration: BoxDecoration(
          color:        Colors.white24,
          shape:        BoxShape.circle,
          border: Border.all(
            color: Colors.white30,
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}