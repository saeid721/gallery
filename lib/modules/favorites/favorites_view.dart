import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'favorites_controller.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../widgets/media_grid_widget.dart';
import '../../widgets/media_list_tile_widget.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/selection_app_bar.dart';
import '../../widgets/sort_bottom_sheet.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

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
  final FavoritesController controller;
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
            return const _EmptyFavorites();
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
          Text('Favorites', style: AppTextStyles.appBarTitle()),
          Obx(() => Text(
            controller.subtitle,
            style: AppTextStyles.caption(),
          )),
        ],
      ),
      actions: [
        // View mode toggle
        Obx(() {
          final prefs = Get.find<PreferencesService>();
          return IconButton(
            icon: Icon(
              prefs.viewMode.value == 'grid'
                  ? Icons.view_list_outlined
                  : Icons.grid_view_outlined,
            ),
            onPressed: prefs.toggleViewMode,
          );
        }),

        // More options
        PopupMenuButton<String>(
          icon:        const Icon(Icons.more_vert),
          color:       const Color(0xFF2C2C2E),
          onSelected:  _onMenuSelected,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'sort',
              child: Row(children: [
                Icon(Icons.sort, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Sort by',
                    style: TextStyle(color: Colors.white)),
              ]),
            ),
            PopupMenuItem(
              value: 'slideshow',
              child: Row(children: [
                Icon(Icons.slideshow, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Slideshow',
                    style: TextStyle(color: Colors.white)),
              ]),
            ),
            PopupMenuItem(
              value: 'select',
              child: Row(children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Select',
                    style: TextStyle(color: Colors.white)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'sort':
        Get.bottomSheet(const SortBottomSheet());
        break;
      case 'slideshow':
        controller.startSlideshow();
        break;
      case 'select':
        if (controller.mediaList.isNotEmpty) {
          controller.enterSelectMode(
            controller.mediaList.first.id!,
          );
        }
        break;
    }
  }

  // ─── Body ────────────────────────────────────────────────
  Widget _buildBody() {
    return Obx(() {
      final prefs = Get.find<PreferencesService>();
      if (prefs.viewMode.value == 'list') {
        return _buildListView();
      }
      return _buildGroupedGrid();
    });
  }

  // ─── Grouped Grid ────────────────────────────────────────
  Widget _buildGroupedGrid() {
    return Obx(() {
      final prefs  = Get.find<PreferencesService>();
      final groups = controller.groupedMedia;

      return CustomScrollView(
        slivers: [
          for (final group in groups) ...[
            // Date section header
            SliverToBoxAdapter(
              child: _DateHeader(label: group.label),
            ),

            // Photo grid
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.xs),
              sliver: MediaGridWidget(
                items:       group.items,
                columnCount: prefs.gridColumnCount.value,
                onTap: (item) {
                  final index = controller.mediaList.indexOf(item);
                  controller.openPhoto(index);
                },
                onLongPress: (item) {
                  controller.enterSelectMode(item.id!);
                },
                selectedIds: controller.selectedIds.map((id) => id.toString()).toSet(),
                isSelectMode:     controller.isSelectMode.value,
                onToggleSelect:   (item) =>
                    controller.toggleSelect(item.id!),
                onToggleFavorite: (item) =>
                    controller.unfavorite(item.id!),
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      );
    });
  }

  // ─── List View ───────────────────────────────────────────
  Widget _buildListView() {
    return Obx(() {
      final groups   = controller.groupedMedia;
      final allItems = groups.expand((g) => g.items).toList();

      return ListView.builder(
        itemCount:   allItems.length,
        itemBuilder: (_, index) {
          final item = allItems[index];
          return MediaListTileWidget(
            item:         item,
            isSelected:   controller.isSelected(item.id!),
            isSelectMode: controller.isSelectMode.value,
            onTap: () {
              if (controller.isSelectMode.value) {
                controller.toggleSelect(item.id!);
              } else {
                controller.openPhoto(index);
              }
            },
            onLongPress: () => controller.enterSelectMode(item.id!),
            onFavorite:  () => controller.unfavorite(item.id!),
          );
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// SELECT MODE SCAFFOLD
// ─────────────────────────────────────────────────────────────

class _SelectModeScaffold extends StatelessWidget {
  final FavoritesController controller;
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
        final prefs  = Get.find<PreferencesService>();
        final groups = controller.groupedMedia;

        return CustomScrollView(
          slivers: [
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: _DateHeader(label: group.label),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.xs),
                sliver: MediaGridWidget(
                  items:           group.items,
                  columnCount:     prefs.gridColumnCount.value,
                  isSelectMode:    true,
                  selectedIds: controller.selectedIds.map((id) => id.toString()).toSet(),
                  onTap:           (item) =>
                      controller.toggleSelect(item.id!),
                  onLongPress:     (_) {},
                  onToggleSelect:  (item) =>
                      controller.toggleSelect(item.id!),
                  onToggleFavorite: (_) {},
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      }),
      bottomNavigationBar: _SelectionBottomBar(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY FAVORITES
// ─────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated heart
          TweenAnimationBuilder<double>(
            tween:    Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve:    Curves.elasticOut,
            builder:  (_, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: SamsungColors.favorite,
              size:  72,
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          Text(
            'No Favorites Yet',
            style: AppTextStyles.headingMedium(),
          ),

          const SizedBox(height: AppDimensions.sm),

          Text(
            'Tap the heart icon on any photo\nto add it here',
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
  final FavoritesController controller;
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
          // Share
          _BottomAction(
            icon:  Icons.share_outlined,
            label: 'Share',
            onTap: () {},
          ),

          // Unfavorite
          _BottomAction(
            icon:  Icons.heart_broken_outlined,
            label: 'Unfavorite',
            color: SamsungColors.favorite,
            onTap: controller.unfavoriteSelected,
          ),

          // Delete
          _BottomAction(
            icon:  Icons.delete_outline,
            label: 'Delete',
            color: SamsungColors.deleteRed,
            onTap: controller.deleteSelected,
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
          horizontal: AppDimensions.lg,
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
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.lg,
        AppDimensions.lg,
        AppDimensions.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.dateSectionHeader(),
      ),
    );
  }
}