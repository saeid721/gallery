import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'photo_viewer_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/media_item.dart';

class PhotoViewerView extends GetView<PhotoViewerController> {
  const PhotoViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() => Stack(
        children: [

          // ─── Photo Gallery (PageView + PhotoView) ────────
          _PhotoGallery(controller: controller),

          // ─── Top AppBar ──────────────────────────────────
          AnimatedOpacity(
            opacity:  controller.showUI.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: _TopBar(controller: controller),
          ),

          // ─── Bottom Action Bar ───────────────────────────
          AnimatedOpacity(
            opacity:  controller.showUI.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: _BottomBar(controller: controller),
          ),

          // ─── Slide-up Info Panel ─────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve:    Curves.easeInOut,
            bottom:   controller.showInfoPanel.value ? 0 : -400,
            left:  0,
            right: 0,
            child: _InfoPanel(controller: controller),
          ),

          // ─── Photo Counter ───────────────────────────────
          if (controller.showUI.value)
            Positioned(
              top:   MediaQuery.of(context).padding.top + 56,
              right: AppDimensions.lg,
              child: _PhotoCounter(controller: controller),
            ),
        ],
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PHOTO GALLERY
// ─────────────────────────────────────────────────────────────

class _PhotoGallery extends StatelessWidget {
  final PhotoViewerController controller;
  const _PhotoGallery({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: controller.toggleUI,
      child: PhotoViewGallery.builder(
        pageController: controller.pageController,
        itemCount:      controller.mediaList.length,
        scrollPhysics:  controller.isZoomed.value
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        onPageChanged:  controller.onPageChanged,
        builder: (context, index) {
          final item = controller.mediaList[index];
          return PhotoViewGalleryPageOptions(
            // Hero animation — grid → viewer
            heroAttributes: PhotoViewHeroAttributes(
              tag: item.heroTag,
            ),
            imageProvider: CachedNetworkImageProvider(item.uri),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3.0,
            onTapUp: (_, __, ___) => controller.toggleUI(),
            gestureDetectorBehavior: HitTestBehavior.translucent,
          );
        },
        loadingBuilder: (_, event) => Center(
          child: CircularProgressIndicator(
            value: event?.expectedTotalBytes != null
                ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                : null,
            color: SamsungColors.primary,
            strokeWidth: 2,
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final PhotoViewerController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top:   0,
      left:  0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPadding),
        decoration: BoxDecoration(
          gradient: SamsungColors.gradientBlackTop,
        ),
        child: Obx(() => AppBar(
          backgroundColor:    Colors.transparent,
          elevation:          0,
          leading: IconButton(
            icon:      const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: Get.back,
          ),
          title: Text(
            controller.currentFilename,
            style: AppTextStyles.bodyMedium(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Favorite
            IconButton(
              icon: Icon(
                controller.currentItem.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: controller.currentItem.isFavorite
                    ? SamsungColors.favorite
                    : Colors.white,
              ),
              onPressed: controller.toggleFavorite,
            ),

            // Slideshow
            IconButton(
              icon:      const Icon(Icons.slideshow, color: Colors.white),
              onPressed: controller.startSlideshow,
            ),

            // More options
            PopupMenuButton<String>(
              icon:  const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF2C2C2E),
              onSelected: _onMenuSelected,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'info',
                  child: Row(children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Details', style: TextStyle(color: Colors.white)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        color: Color(0xFFFF3B30), size: 20),
                    SizedBox(width: 12),
                    Text('Delete',
                        style: TextStyle(color: Color(0xFFFF3B30))),
                  ]),
                ),
              ],
            ),
          ],
        )),
      ),
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'info':   controller.toggleInfoPanel(); break;
      case 'delete': controller.deleteCurrentPhoto(); break;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final PhotoViewerController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left:   0,
      right:  0,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          gradient: SamsungColors.gradientBlackBottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical:   AppDimensions.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon:    Icons.share_outlined,
                label:   'Share',
                onTap:   () {},
              ),
              _ActionButton(
                icon:    Icons.edit_outlined,
                label:   'Edit',
                onTap:   () {},
              ),
              _ActionButton(
                icon:    Icons.info_outline,
                label:   'Details',
                onTap:   controller.toggleInfoPanel,
              ),
              _ActionButton(
                icon:    Icons.delete_outline,
                label:   'Delete',
                color:   SamsungColors.deleteRed,
                onTap:   controller.deleteCurrentPhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption(color: c),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PHOTO COUNTER
// ─────────────────────────────────────────────────────────────

class _PhotoCounter extends StatelessWidget {
  final PhotoViewerController controller;
  const _PhotoCounter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical:   AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color:        Colors.black54,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        controller.photoCounter,
        style: AppTextStyles.caption(color: Colors.white),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// INFO PANEL (Slide-up EXIF details)
// ─────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final PhotoViewerController controller;
  const _InfoPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.currentItem;
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

            // Drag handle
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
                  Text(
                    'Details',
                    style: AppTextStyles.headingMedium(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:      const Icon(Icons.close, color: Colors.white),
                    onPressed: controller.toggleInfoPanel,
                    padding:   EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: SamsungColors.darkDivider),

            // Info rows
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                children: [
                  _InfoRow(
                    icon:  Icons.image_outlined,
                    label: 'Filename',
                    value: item.filename,
                  ),
                  _InfoRow(
                    icon:  Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(item.dateTime),
                  ),
                  _InfoRow(
                    icon:  Icons.photo_size_select_large_outlined,
                    label: 'Resolution',
                    value: item.resolution,
                  ),
                  _InfoRow(
                    icon:  Icons.storage_outlined,
                    label: 'File Size',
                    value: item.formattedSize,
                  ),
                  _InfoRow(
                    icon:  Icons.perm_media_outlined,
                    label: 'Type',
                    value: item.mediaType.toUpperCase(),
                  ),
                  if (item.hasLocation)
                    _InfoRow(
                      icon:  Icons.location_on_outlined,
                      label: 'Location',
                      value: '${item.latitude!.toStringAsFixed(4)}, '
                          '${item.longitude!.toStringAsFixed(4)}',
                      valueColor: SamsungColors.primary,
                    ),
                  if (item.isFavorite)
                    _InfoRow(
                      icon:       Icons.favorite,
                      label:      'Favorited',
                      value:      'Yes',
                      iconColor:  SamsungColors.favorite,
                      valueColor: SamsungColors.favorite,
                    ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
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
    return '${months[dt.month]} ${dt.day}, ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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
            child: Text(
              label,
              style: AppTextStyles.bodySmall(),
            ),
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