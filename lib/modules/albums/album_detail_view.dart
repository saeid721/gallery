import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart';
import 'album_detail_controller.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../widgets/media_grid_widget.dart';
import '../../widgets/media_list_tile_widget.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/selection_app_bar.dart';
import '../../widgets/sort_bottom_sheet.dart';

class AlbumDetailView extends GetView<AlbumDetailController> {
  const AlbumDetailView({super.key});

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
  final AlbumDetailController controller;
  const _NormalScaffold({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(context),
        ],
        body: Obx(() {
          if (controller.isLoading.value) {
            return ShimmerGrid(columnCount: controller.columnCount);
          }
          if (controller.isEmpty) {
            return const EmptyStateWidget(
              icon:    Icons.photo_outlined,
              message: 'No photos in this album',
            );
          }
          return _buildBody();
        }),
      ),
    );
  }

  // ─── Sliver AppBar with Cover ────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return Obx(() => SliverAppBar(
      expandedHeight:  220,
      floating:        false,
      pinned:          true,
      backgroundColor: SamsungColors.darkAppBar,
      elevation:       0,
      leading: IconButton(
        icon:      const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: Get.back,
      ),
      actions: [
        // Search
        IconButton(
          icon:      const Icon(Icons.search, color: Colors.white),
          onPressed: () => _showSearchBar(context),
        ),

        // View mode toggle
        IconButton(
          icon: Icon(
            Get.find<PreferencesService>().viewMode.value == 'grid'
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: Colors.white,
          ),
          onPressed: Get.find<PreferencesService>().toggleViewMode,
        ),

        // More options
        PopupMenuButton<String>(
          icon:        const Icon(Icons.more_vert, color: Colors.white),
          color:       const Color(0xFF2C2C2E),
          onSelected:  _onMenuSelected,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'sort',
              child: Row(children: [
                Icon(Icons.sort, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Sort by', style: TextStyle(color: Colors.white)),
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
                Text('Select', style: TextStyle(color: Colors.white)),
              ]),
            ),
          ],
        ),
      ],

      // Cover image + album info
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background:   _AlbumCoverHeader(controller: controller),
        title: Obx(() => Text(
          controller.albumTitle,
          style: AppTextStyles.headingMedium(),
        )),
        titlePadding: const EdgeInsets.only(
          left: 56,
          bottom: 14,
        ),
      ),
    ));
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
          controller.enterSelectMode(controller.mediaList.first.id!);
        }
        break;
    }
  }

  void _showSearchBar(BuildContext context) {
    showSearch(
      context: context,
      delegate: _AlbumSearchDelegate(controller),
    );
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
          // Photo count header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.lg,
                AppDimensions.lg,
                AppDimensions.lg,
                AppDimensions.xs,
              ),
              child: Obx(() => Text(
                controller.albumSubtitle,
                style: AppTextStyles.bodySmall(),
              )),
            ),
          ),

          for (final group in groups) ...[
            // Date header
            SliverToBoxAdapter(
              child: _DateHeader(label: group.label),
            ),

            // Grid
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
                onToggleSelect:   (item) => controller.toggleSelect(item.id!),
                onToggleFavorite: (item) => controller.toggleFavorite(item.id!),
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
            onFavorite:  () => controller.toggleFavorite(item.id!),
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
  final AlbumDetailController controller;
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
                  onTap:           (item) => controller.toggleSelect(item.id!),
                  onLongPress:     (_) {},
                  onToggleSelect:  (item) => controller.toggleSelect(item.id!),
                  onToggleFavorite: (_) {},
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      }),
      bottomNavigationBar: _SelectionBottomBar(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ALBUM COVER HEADER
// ─────────────────────────────────────────────────────────────

class _AlbumCoverHeader extends StatelessWidget {
  final AlbumDetailController controller;
  const _AlbumCoverHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final album = controller.album.value;
      if (album == null) return const SizedBox.shrink();

      return Stack(
        fit: StackFit.expand,
        children: [
          // Cover image
          CachedNetworkImage(
            imageUrl:  album.coverUri,
            fit:       BoxFit.cover,
            placeholder: (_, __) => Container(
              color: SamsungColors.darkCard,
            ),
          ),

          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Album info bottom-left
          Positioned(
            left:   AppDimensions.lg,
            bottom: AppDimensions.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                // Album type icon
                Row(
                  children: [
                    Icon(
                      _albumTypeIcon(album.albumType),
                      color: SamsungColors.primary,
                      size:  16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      album.albumType.toUpperCase(),
                      style: AppTextStyles.caption(
                        color: SamsungColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Photo count
                Text(
                  controller.albumSubtitle,
                  style: AppTextStyles.bodySmall(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  IconData _albumTypeIcon(String type) {
    switch (type) {
      case 'camera':     return Icons.camera_alt_outlined;
      case 'screenshot': return Icons.screenshot_outlined;
      case 'download':   return Icons.download_outlined;
      default:           return Icons.folder_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// DATE HEADER
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

// ─────────────────────────────────────────────────────────────
// SELECTION BOTTOM BAR
// ─────────────────────────────────────────────────────────────

class _SelectionBottomBar extends StatelessWidget {
  final AlbumDetailController controller;
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
          _BottomAction(
            icon:  Icons.share_outlined,
            label: 'Share',
            onTap: () {},
          ),
          _BottomAction(
            icon:  Icons.favorite_border,
            label: 'Favorite',
            color: SamsungColors.favorite,
            onTap: controller.favoriteSelected,
          ),
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
// SEARCH DELEGATE
// ─────────────────────────────────────────────────────────────

class _AlbumSearchDelegate extends SearchDelegate<String> {
  final AlbumDetailController controller;
  _AlbumSearchDelegate(this.controller);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: SamsungColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: SamsungColors.darkSurface,
        elevation:       0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border:      InputBorder.none,
        hintStyle:   TextStyle(color: SamsungColors.textSecondaryDark),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon:      const Icon(Icons.clear),
        onPressed: () {
          query = '';
          controller.searchQuery.value = '';
        },
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon:      const Icon(Icons.arrow_back),
    onPressed: () {
      controller.searchQuery.value = '';
      close(context, '');
    },
  );

  @override
  Widget buildResults(BuildContext context) {
    controller.searchQuery.value = query;
    return _buildSearchBody();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    controller.searchQuery.value = query;
    return _buildSearchBody();
  }

  Widget _buildSearchBody() {
    return Obx(() {
      final prefs  = Get.find<PreferencesService>();
      final groups = controller.groupedMedia;
      final items  = groups.expand((g) => g.items).toList();

      if (items.isEmpty) {
        return const EmptyStateWidget(
          icon:    Icons.search_off,
          message: 'No photos found',
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.xs),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   prefs.gridColumnCount.value,
          crossAxisSpacing: AppDimensions.xs,
          mainAxisSpacing:  AppDimensions.xs,
        ),
        itemCount:   items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              close(context as BuildContext, '');
              controller.openPhoto(
                controller.mediaList.indexOf(item),
              );
            },
            child: Hero(
              tag: item.heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusSm,
                ),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUri,
                  fit:      BoxFit.cover,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}