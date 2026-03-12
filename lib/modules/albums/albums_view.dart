import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/preferences_service.dart';
import 'albums_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/album.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/selection_app_bar.dart';

class AlbumsView extends GetView<AlbumsController> {
  const AlbumsView({super.key});

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
  final AlbumsController controller;
  const _NormalScaffold({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Obx(() {
          if (controller.isLoading.value) {
            return const ShimmerGrid(columnCount: 2);
          }
          if (controller.isEmpty) {
            return const EmptyStateWidget(
              icon:    Icons.photo_album_outlined,
              message: 'No albums yet',
            );
          }
          return _buildAlbumGrid();
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
      title:           Text('Albums', style: AppTextStyles.appBarTitle()),
      actions: [
        // New album button
        IconButton(
          icon:      const Icon(Icons.create_new_folder_outlined),
          onPressed: () {},
        ),

        // More options
        PopupMenuButton<String>(
          icon:        const Icon(Icons.more_vert),
          onSelected:  _onMenuSelected,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'toggle_hidden',
              child: Text('Show/Hide Hidden Albums'),
            ),
          ],
        ),
      ],
    );
  }

  void _onMenuSelected(String value) {
    if (value == 'toggle_hidden') {
      Get.find<PreferencesService>().showHidden.value =
      !Get.find<PreferencesService>().showHidden.value;
    }
  }

  // ─── Album Grid (2 columns) ──────────────────────────────
  Widget _buildAlbumGrid() {
    return RefreshIndicator(
      color:       SamsungColors.primary,
      onRefresh:   controller.loadAlbums,
      child: Obx(() => GridView.builder(
        padding:     const EdgeInsets.all(AppDimensions.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing:  AppDimensions.md,
          childAspectRatio: 0.85,
        ),
        itemCount:   controller.albumList.length,
        itemBuilder: (_, index) {
          final album = controller.albumList[index];
          return _AlbumCard(
            album:        album,
            isSelected:   controller.isSelected(album.id!),
            isSelectMode: controller.isSelectMode.value,
            onTap: () {
              if (controller.isSelectMode.value) {
                controller.toggleSelect(album.id!);
              } else {
                controller.openAlbum(album);
              }
            },
            onLongPress: () => controller.enterSelectMode(album.id!),
            onRename:    () => controller.renameAlbum(album),
            onHide:      () => controller.toggleAlbumVisibility(album),
          );
        },
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECT MODE SCAFFOLD
// ─────────────────────────────────────────────────────────────

class _SelectModeScaffold extends StatelessWidget {
  final AlbumsController controller;
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
      body: Obx(() => GridView.builder(
        padding:     const EdgeInsets.all(AppDimensions.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing:  AppDimensions.md,
          childAspectRatio: 0.85,
        ),
        itemCount:   controller.albumList.length,
        itemBuilder: (_, index) {
          final album = controller.albumList[index];
          return _AlbumCard(
            album:        album,
            isSelected:   controller.isSelected(album.id!),
            isSelectMode: true,
            onTap:        () => controller.toggleSelect(album.id!),
            onLongPress:  () {},
            onRename:     () {},
            onHide:       () {},
          );
        },
      )),
      bottomNavigationBar: _SelectionBottomBar(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ALBUM CARD
// ─────────────────────────────────────────────────────────────

class _AlbumCard extends StatelessWidget {
  final Album        album;
  final bool         isSelected;
  final bool         isSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRename;
  final VoidCallback onHide;

  const _AlbumCard({
    required this.album,
    required this.isSelected,
    required this.isSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRename,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:      onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Stack(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSm,
                  ),
                  child: CachedNetworkImage(
                    imageUrl:   album.coverUri,
                    fit:        BoxFit.cover,
                    width:      double.infinity,
                    height:     double.infinity,
                    placeholder: (_, __) => Container(
                      color: SamsungColors.darkCard,
                      child: const Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: SamsungColors.textSecondaryDark,
                          size:  32,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: SamsungColors.darkCard,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: SamsungColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                ),

                // Selected overlay
                if (isSelected)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      child: Container(
                        color: SamsungColors.selectedBg,
                      ),
                    ),
                  ),

                // Selected border
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

                // Checkmark
                if (isSelected)
                  const Positioned(
                    top:   8,
                    right: 8,
                    child: _CheckMark(),
                  ),

                // Context menu (normal mode only)
                if (!isSelectMode)
                  Positioned(
                    top:   4,
                    right: 4,
                    child: _AlbumContextMenu(
                      album:    album,
                      onRename: onRename,
                      onHide:   onHide,
                    ),
                  ),

                // Hidden badge
                if (album.isHidden)
                  Positioned(
                    top:  8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical:   2,
                      ),
                      decoration: BoxDecoration(
                        color:        Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            color: Colors.white,
                            size:  10,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Hidden',
                            style: TextStyle(
                              color:    Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.xs),

          // Album name
          Text(
            album.name,
            style:     AppTextStyles.headingSmall(),
            maxLines:  1,
            overflow:  TextOverflow.ellipsis,
          ),

          // Item count
          Text(
            album.itemCountLabel,
            style: AppTextStyles.caption(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ALBUM CONTEXT MENU
// ─────────────────────────────────────────────────────────────

class _AlbumContextMenu extends StatelessWidget {
  final Album        album;
  final VoidCallback onRename;
  final VoidCallback onHide;

  const _AlbumContextMenu({
    required this.album,
    required this.onRename,
    required this.onHide,
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
        if (value == 'rename') onRename();
        if (value == 'hide')   onHide();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'rename',
          child: Row(children: [
            Icon(Icons.edit_outlined,
                color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Rename',
                style: TextStyle(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: 'hide',
          child: Row(children: [
            Icon(
              album.isHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white,
              size:  18,
            ),
            const SizedBox(width: 10),
            Text(
              album.isHidden ? 'Unhide' : 'Hide',
              style: const TextStyle(color: Colors.white),
            ),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHECKMARK WIDGET
// ─────────────────────────────────────────────────────────────

class _CheckMark extends StatelessWidget {
  const _CheckMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:      22,
      height:     22,
      decoration: const BoxDecoration(
        color:  SamsungColors.primary,
        shape:  BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        color: Colors.black,
        size:  14,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECTION BOTTOM BAR
// ─────────────────────────────────────────────────────────────

class _SelectionBottomBar extends StatelessWidget {
  final AlbumsController controller;
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
          // Rename (single select only)
          Obx(() => controller.selectedCount == 1
              ? _BottomAction(
            icon:  Icons.edit_outlined,
            label: 'Rename',
            onTap: () {
              final album = controller.albumList.firstWhere(
                    (a) => controller.selectedIds.contains(a.id),
              );
              controller.renameAlbum(album);
            },
          )
              : const SizedBox.shrink()),

          // Hide/Unhide
          _BottomAction(
            icon:  Icons.visibility_off_outlined,
            label: 'Hide',
            onTap: () async {
              for (final id in controller.selectedIds.toList()) {
                final album = controller.albumList
                    .firstWhere((a) => a.id == id);
                await controller.toggleAlbumVisibility(album);
              }
              controller.exitSelectMode();
            },
          ),

          // Delete
          _BottomAction(
            icon:  Icons.delete_outline,
            label: 'Delete',
            color: SamsungColors.deleteRed,
            onTap: controller.deleteSelectedAlbums,
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