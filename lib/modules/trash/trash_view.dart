import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_text_styles.dart';
import 'trash_controller.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/media_item.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/selection_app_bar.dart';

class TrashView extends GetView<TrashController> {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isSelectMode.value
        ? _SelectModeScaffold(controller: controller)
        : _NormalScaffold(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NORMAL SCAFFOLD
// ─────────────────────────────────────────────────────────────

class _NormalScaffold extends StatelessWidget {
  final TrashController controller;
  const _NormalScaffold({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Obx(() {
          if (controller.isLoading.value) {
            return ShimmerGrid(columnCount: controller.columnCount);
          }
          if (controller.isEmpty) {
            return const _EmptyTrash();
          }
          return _buildBody();
        }),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      floating:        true,
      snap:            true,
      backgroundColor: SamsungColors.darkAppBar,
      elevation:       0,
      leading: IconButton(
        icon:      const Icon(Icons.arrow_back),
        onPressed: Get.back,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          Text('Trash', style: AppTextStyles.appBarTitle()),
          Obx(() => Text(
            controller.subtitle,
            style: AppTextStyles.caption(),
          )),
        ],
      ),
      actions: [
        // Grid column toggle
        Obx(() {
          final prefs = Get.find<PreferencesService>();
          return IconButton(
            icon: Text(
              '${prefs.gridColumnCount.value}',
              style: AppTextStyles.headingSmall(
                color: SamsungColors.primary,
              ),
            ),
            onPressed: prefs.cycleGridColumns,
          );
        }),

        // Empty trash button
        Obx(() => controller.mediaList.isNotEmpty
            ? TextButton(
          onPressed: controller.emptyTrash,
          child: const Text(
            'Empty',
            style: TextStyle(
              color:      Color(0xFFFF3B30),
              fontWeight: FontWeight.w600,
            ),
          ),
        )
            : const SizedBox.shrink()),
      ],
    );
  }

  // ─── Body ────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      children: [
        // Auto-delete info banner
        // SharedPreferences key: "recycle_bin_days"
        Obx(() {
          final days = Get.find<PreferencesService>().recycleBinDays.value;
          return _InfoBanner(
            message: 'Photos are automatically deleted '
                'after $days days',
          );
        }),

        // Grid
        Expanded(
          child: Obx(() {
            final prefs = Get.find<PreferencesService>();
            return GridView.builder(
              padding: const EdgeInsets.all(AppDimensions.xs),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   prefs.gridColumnCount.value,
                crossAxisSpacing: AppDimensions.xs,
                mainAxisSpacing:  AppDimensions.xs,
              ),
              itemCount:   controller.mediaList.length,
              itemBuilder: (_, index) {
                final item = controller.mediaList[index];
                return _TrashItemCard(
                  item:        item,
                  isSelected:  controller.isSelected(item.id!),
                  daysLabel:   controller.daysRemaining(item),
                  onTap: () => controller.openPhoto(index),
                  onLongPress: () =>
                      controller.enterSelectMode(item.id!),
                  onRestore: () =>
                      controller.restoreSingle(item.id!),
                  onDelete: () =>
                      controller.deleteSinglePermanently(item.id!),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECT MODE SCAFFOLD
// ─────────────────────────────────────────────────────────────

class _SelectModeScaffold extends StatelessWidget {
  final TrashController controller;
  const _SelectModeScaffold({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      appBar: SelectionAppBar(
        selectedCount: controller.selectedCount,
        onClose:       controller.exitSelectMode,
        onSelectAll:   controller.selectAll,
      ),
      body: Obx(() {
        final prefs = Get.find<PreferencesService>();
        return GridView.builder(
          padding: const EdgeInsets.all(AppDimensions.xs),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   prefs.gridColumnCount.value,
            crossAxisSpacing: AppDimensions.xs,
            mainAxisSpacing:  AppDimensions.xs,
          ),
          itemCount:   controller.mediaList.length,
          itemBuilder: (_, index) {
            final item = controller.mediaList[index];
            return _TrashItemCard(
              item:        item,
              isSelected:  controller.isSelected(item.id!),
              daysLabel:   controller.daysRemaining(item),
              onTap:       () => controller.toggleSelect(item.id!),
              onLongPress: () {},
              onRestore:   () {},
              onDelete:    () {},
            );
          },
        );
      }),
      bottomNavigationBar: _SelectionBottomBar(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRASH ITEM CARD
// ─────────────────────────────────────────────────────────────

class _TrashItemCard extends StatelessWidget {
  final MediaItem    item;
  final bool         isSelected;
  final String       daysLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItemCard({
    required this.item,
    required this.isSelected,
    required this.daysLabel,
    required this.onTap,
    required this.onLongPress,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:       onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [

          // ─── Thumbnail ──────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusSm,
            ),
            child: CachedNetworkImage(
              imageUrl:    item.thumbnailUri,
              fit:         BoxFit.cover,
              color:       isSelected
                  ? Colors.black.withOpacity(0.3)
                  : null,
              colorBlendMode: BlendMode.darken,
              placeholder: (_, __) => Container(
                color: SamsungColors.darkCard,
              ),
            ),
          ),

          // ─── Selected border ────────────────────────────
          if (isSelected)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusSm,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: SamsungColors.selectedBorder,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSm,
                    ),
                  ),
                ),
              ),
            ),

          // ─── Checkmark ──────────────────────────────────
          if (isSelected)
            const Positioned(
              top:   8,
              right: 8,
              child: _CheckMark(),
            ),

          // ─── Days remaining label ────────────────────────
          if (daysLabel.isNotEmpty && !isSelected)
            Positioned(
              bottom: 0,
              left:   0,
              right:  0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusSm),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xs,
                    vertical:   3,
                  ),
                  color: Colors.black54,
                  child: Text(
                    daysLabel,
                    style: AppTextStyles.caption(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

          // ─── Action buttons (normal mode) ────────────────
          if (!isSelected)
            Positioned(
              top:   4,
              right: 4,
              child: _TrashItemMenu(
                onRestore: onRestore,
                onDelete:  onDelete,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRASH ITEM CONTEXT MENU
// ─────────────────────────────────────────────────────────────

class _TrashItemMenu extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItemMenu({
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding:    const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:        Colors.black45,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusFull,
          ),
        ),
        child: const Icon(
          Icons.more_vert,
          color: Colors.white,
          size:  16,
        ),
      ),
      color:       const Color(0xFF2C2C2E),
      onSelected:  (value) {
        if (value == 'restore') onRestore();
        if (value == 'delete')  onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'restore',
          child: Row(children: [
            Icon(Icons.restore,
                color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Restore',
                style: TextStyle(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_forever,
                color: Color(0xFFFF3B30), size: 18),
            SizedBox(width: 10),
            Text('Delete Permanently',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INFO BANNER
// ─────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical:   AppDimensions.sm,
      ),
      color: SamsungColors.darkSurface,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: SamsungColors.textSecondaryDark,
            size:  16,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY TRASH
// ─────────────────────────────────────────────────────────────

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.delete_outline,
            color: SamsungColors.textSecondaryDark,
            size:  72,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Trash is Empty',
            style: AppTextStyles.headingMedium(),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Deleted photos will appear here\nbefore being permanently removed',
            style:     AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECTION BOTTOM BAR
// ─────────────────────────────────────────────────────────────

class _SelectionBottomBar extends StatelessWidget {
  final TrashController controller;
  const _SelectionBottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: SamsungColors.darkSurface,
        border: Border(
          top: BorderSide(
            color: SamsungColors.darkDivider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Restore
          _BottomAction(
            icon:  Icons.restore,
            label: 'Restore',
            color: SamsungColors.primary,
            onTap: controller.restoreSelected,
          ),

          // Delete permanently
          _BottomAction(
            icon:  Icons.delete_forever,
            label: 'Delete',
            color: SamsungColors.deleteRed,
            onTap: controller.deleteSelectedPermanently,
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color?       color;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? SamsungColors.textPrimaryDark;
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xl,
          vertical:   AppDimensions.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: AppDimensions.iconMd),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption(color: c)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHECKMARK
// ─────────────────────────────────────────────────────────────

class _CheckMark extends StatelessWidget {
  const _CheckMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:      22,
      height:     22,
      decoration: const BoxDecoration(
        color: SamsungColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        color: Colors.black,
        size:  14,
      ),
    );
  }
}