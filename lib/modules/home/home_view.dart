import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/media_group.dart';
import '../../models/media_item.dart';
import '../../core/services/media_service.dart';
import 'home_controller.dart';
import '../../widgets/media_grid_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor:           Colors.transparent,
        systemNavigationBarColor: SamsungColors.navBar,
      ),
      child: Scaffold(
        backgroundColor: SamsungColors.background,
        body: Obx(() {
          // ── Permission denied ────────────────────────────
          if (controller.permissionDenied.value) {
            return _PermissionScreen(controller: controller);
          }
          // ── Normal / Select mode ─────────────────────────
          return controller.isSelectMode.value
              ? _SelectModeScaffold(controller: controller)
              : _NormalScaffold(controller: controller);
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PERMISSION SCREEN
// ─────────────────────────────────────────────────────────────

class _PermissionScreen extends StatelessWidget {
  final HomeController controller;
  const _PermissionScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color:        SamsungColors.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: SamsungColors.accent, size: 44),
              ),
              const SizedBox(height: 24),
              const Text(
                'Allow Gallery to access\nyour photos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:      SamsungColors.textPrimary,
                  fontSize:   20,
                  fontWeight: FontWeight.w700,
                  height:     1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gallery needs access to your photos\nand videos to display them here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    SamsungColors.textSecondary,
                  fontSize: 14,
                  height:   1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.retryPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SamsungColors.accent,
                    padding:   const EdgeInsets.symmetric(vertical: 15),
                    shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Allow Access',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: controller.openSystemSettings,
                child: const Text('Open Settings',
                    style: TextStyle(color: SamsungColors.accent, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NORMAL MODE SCAFFOLD
// ─────────────────────────────────────────────────────────────

class _NormalScaffold extends StatelessWidget {
  final HomeController controller;
  const _NormalScaffold({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: SamsungColors.background,
        appBar: _SamsungAppBar(controller: controller),
        body: Column(
          children: [
            _SamsungTabBar(),
            // Limited access banner (iOS)
            Obx(() => controller.permissionLimited.value
                ? _LimitedAccessBanner(controller: controller)
                : const SizedBox.shrink()),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PhotosTab(controller: controller),
                  _AlbumsTab(controller: controller),
                  _StoriesTab(),
                  _SharedTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _SamsungBottomNav(controller: controller),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECT MODE SCAFFOLD
// ─────────────────────────────────────────────────────────────

class _SelectModeScaffold extends StatelessWidget {
  final HomeController controller;
  const _SelectModeScaffold({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.background,
      appBar: _SelectAppBar(controller: controller),
      body: Column(
        children: [
          _SelectActionBar(controller: controller),
          Expanded(child: _PhotosTab(controller: controller)),
        ],
      ),
      bottomNavigationBar: _SamsungBottomNav(controller: controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LIMITED ACCESS BANNER  (iOS only)
// ─────────────────────────────────────────────────────────────

class _LimitedAccessBanner extends StatelessWidget {
  final HomeController controller;
  const _LimitedAccessBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SamsungColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: SamsungColors.accent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Limited access — some photos may not appear.',
              style: TextStyle(color: SamsungColors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: controller.openSystemSettings,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Manage',
                style: TextStyle(color: SamsungColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SAMSUNG APP BAR
// ─────────────────────────────────────────────────────────────

class _SamsungAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;
  const _SamsungAppBar({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showSearch = controller.showSearch.value;
      return AppBar(
        backgroundColor:  SamsungColors.background,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        toolbarHeight:    60,
        titleSpacing:     20,
        title: showSearch
            ? _SearchField(controller: controller)
            : const Text('Gallery',
            style: TextStyle(
              color:      SamsungColors.textPrimary,
              fontSize:   28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            )),
        actions: showSearch
            ? [
          TextButton(
            onPressed: () {
              controller.showSearch.value = false;
              controller.searchQuery.value = '';
            },
            child: const Text('Cancel',
                style: TextStyle(color: SamsungColors.accent, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ]
            : [
          IconButton(
            onPressed: () => controller.showSearch.value = true,
            icon: const Icon(Icons.search, color: SamsungColors.textPrimary, size: 24),
          ),
          _SortMenuButton(controller: controller),
        ],
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  final HomeController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color:        SamsungColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        autofocus:   true,
        style:       const TextStyle(color: SamsungColors.textPrimary, fontSize: 16),
        cursorColor: SamsungColors.accent,
        onChanged:   (v) => controller.searchQuery.value = v,
        decoration: InputDecoration(
          hintText:       'Search',
          hintStyle:      const TextStyle(color: SamsungColors.textTertiary),
          prefixIcon:     const Icon(Icons.search, color: SamsungColors.textTertiary, size: 20),
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.cancel, color: SamsungColors.textTertiary, size: 18),
            onPressed: () => controller.searchQuery.value = '',
          )
              : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final HomeController controller;
  const _SortMenuButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon:  const Icon(Icons.more_vert, color: SamsungColors.textPrimary),
      color: SamsungColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        _item('Sort by date taken',    Icons.calendar_today_outlined),
        _item('Sort by date modified', Icons.edit_calendar_outlined),
        _item('Grid size',             Icons.grid_view_outlined),
        const PopupMenuDivider(height: 1),
        _item('Settings',              Icons.settings_outlined),
        _item('Trash',                 Icons.delete_outline),
      ],
      onSelected: (v) {
        if (v == 'Settings') controller.openSettings();
        if (v == 'Trash')    controller.openTrash();
      },
    );
  }

  PopupMenuItem<String> _item(String label, IconData icon) =>
      PopupMenuItem(
        value: label,
        child: Row(children: [
          Icon(icon, color: SamsungColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: SamsungColors.textPrimary, fontSize: 15)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// SELECT APP BAR
// ─────────────────────────────────────────────────────────────

class _SelectAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;
  const _SelectAppBar({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:  SamsungColors.background,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: SamsungColors.textPrimary),
        onPressed: controller.exitSelectMode,
      ),
      title: Obx(() => Text(
        controller.selectedCount > 0
            ? '${controller.selectedCount} selected'
            : 'Select items',
        style: const TextStyle(
          color:      SamsungColors.textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.w600,
        ),
      )),
      actions: [
        TextButton(
          onPressed: controller.selectAll,
          child: const Text('All',
              style: TextStyle(color: SamsungColors.accent, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECT ACTION BAR
// ─────────────────────────────────────────────────────────────

class _SelectActionBar extends StatelessWidget {
  final HomeController controller;
  const _SelectActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ActionChip(label: 'Share',  icon: Icons.share_outlined,  onTap: () {}),
          const SizedBox(width: 8),
          _ActionChip(
            label: 'Delete',
            icon:  Icons.delete_outline,
            color: SamsungColors.danger,
            onTap: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
          _ActionChip(label: 'More',   icon: Icons.more_horiz,      onTap: () {}),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context:           context,
      backgroundColor:   SamsungColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        SamsungColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() => Text(
                'Move ${controller.selectedCount} item${controller.selectedCount > 1 ? 's' : ''} to trash?',
                style: const TextStyle(color: SamsungColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
              )),
              const SizedBox(height: 8),
              const Text('Items in trash are deleted after 30 days.',
                  style: TextStyle(color: SamsungColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side:    const BorderSide(color: SamsungColors.divider),
                        shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: SamsungColors.textPrimary, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        controller.deleteSelected();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SamsungColors.danger,
                        shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding:   const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Move to trash',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = SamsungColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        SamsungColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────

class _SamsungTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SamsungColors.divider, width: 0.5)),
      ),
      child: TabBar(
        labelColor:           SamsungColors.textPrimary,
        unselectedLabelColor: SamsungColors.textTertiary,
        indicatorColor:       SamsungColors.accent,
        indicatorWeight:      2.5,
        indicatorSize:        TabBarIndicatorSize.label,
        labelStyle:           const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        isScrollable:         true,
        tabAlignment:         TabAlignment.start,
        padding:              const EdgeInsets.symmetric(horizontal: 8),
        tabs: const [
          Tab(text: 'Photos'),
          Tab(text: 'Albums'),
          Tab(text: 'Stories'),
          Tab(text: 'Shared'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────

class _SamsungBottomNav extends StatelessWidget {
  final HomeController controller;
  const _SamsungBottomNav({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  SamsungColors.navBar,
        border: Border(top: BorderSide(color: SamsungColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.grid_view_rounded,    label: 'Photos',  onTap: () {}),
              _NavItem(icon: Icons.photo_album_outlined,  label: 'Albums',  onTap: controller.openFavorites),
              _NavItem(icon: Icons.auto_stories_outlined, label: 'Stories', onTap: () {}),
              _NavItem(icon: Icons.people_outline,        label: 'Shared',  onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: SamsungColors.textSecondary, size: 26),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
              color: SamsungColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PHOTOS TAB
// ─────────────────────────────────────────────────────────────

class _PhotosTab extends StatelessWidget {
  final HomeController controller;
  const _PhotosTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color:       SamsungColors.accent,
            strokeWidth: 2,
          ),
        );
      }
      if (controller.isEmpty) {
        return _EmptyState(
          icon:    Icons.photo_library_outlined,
          message: 'No photos yet',
          sub:     'Photos and videos from your device will appear here',
        );
      }

      return NotificationListener<ScrollNotification>(
        // Trigger next-page load when near bottom
        onNotification: (n) {
          if (n is ScrollEndNotification &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
            controller.loadNextPage();
          }
          return false;
        },
        child: RefreshIndicator(
          color:         SamsungColors.accent,
          backgroundColor: SamsungColors.surface,
          onRefresh:     () => controller.loadMedia(reset: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            cacheExtent: 800, // pre-render cells below/above viewport
            slivers: [
              // Grid size picker
              SliverToBoxAdapter(
                child: _GridSizePicker(controller: controller),
              ),

              // Date groups
              ...controller.groupedMedia.map((group) =>
                  _GroupSliver(group: group, controller: controller)),

              // Load-more spinner
              SliverToBoxAdapter(
                child: Obx(() => controller.isLoadingMore.value
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color:       SamsungColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                )
                    : const SizedBox(height: 16)),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// GRID SIZE PICKER
// ─────────────────────────────────────────────────────────────

class _GridSizePicker extends StatelessWidget {
  final HomeController controller;
  const _GridSizePicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color:        SamsungColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [2, 3, 4, 5].map((n) {
                final active = controller.columnCount.value == n;
                return GestureDetector(
                  onTap: () => controller.setColumnCount(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width:   32,
                    height:  28,
                    margin:  const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color:        active ? SamsungColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: _GridIcon(columns: n, active: active)),
                  ),
                );
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }
}

class _GridIcon extends StatelessWidget {
  final int  columns;
  final bool active;
  const _GridIcon({required this.columns, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : SamsungColors.textTertiary;
    return SizedBox(
      width: 14, height: 14,
      child: GridView.count(
        crossAxisCount:   columns,
        mainAxisSpacing:  1.5,
        crossAxisSpacing: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(columns * columns, (_) => Container(
          decoration: BoxDecoration(
              color:        color,
              borderRadius: BorderRadius.circular(0.5)),
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GROUP SLIVER
// ─────────────────────────────────────────────────────────────

class _GroupSliver extends StatelessWidget {
  final MediaGroup     group;
  final HomeController controller;
  const _GroupSliver({required this.group, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(group.label,
                    style: const TextStyle(
                        color: SamsungColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('${group.items.length} photos',
                    style: const TextStyle(color: SamsungColors.textTertiary, fontSize: 13)),
              ],
            ),
          ),
        ),
        // Grid
        Obx(() => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          sliver: MediaGridWidget(
            items:        group.items,
            columnCount:  controller.columnCount.value,
            isSelectMode: controller.isSelectMode.value,
            selectedIds: controller.selectedIds.toSet(),
            onTap: (item) {
              final idx = controller.mediaList.indexOf(item);
              controller.openPhoto(idx >= 0 ? idx : 0);
            },
            onLongPress:      (item) => controller.enterSelectMode(item.assetId ?? ''),
            onToggleSelect:   (item) => controller.toggleSelect(item.assetId ?? ''),
            onToggleFavorite: (item) => controller.toggleFavorite(item.assetId ?? ''),
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ALBUMS TAB
// ─────────────────────────────────────────────────────────────

class _AlbumsTab extends StatelessWidget {
  final HomeController controller;
  const _AlbumsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final albums = controller.albums;
      if (albums.isEmpty) {
        return const _EmptyState(icon: Icons.photo_album_outlined, message: 'No albums');
      }
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Albums',
                  style: const TextStyle(
                      color: SamsungColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                    (_, i) => _AlbumCell(album: albums[i]),
                childCount: albums.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    });
  }
}

class _AlbumCell extends StatelessWidget {
  final DeviceAlbum album;
  const _AlbumCell({required this.album});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: album.coverData != null
                ? Image.memory(album.coverData!, fit: BoxFit.cover, width: double.infinity)
                : Container(
              color: SamsungColors.surface,
              child: const Icon(Icons.photo_library_outlined,
                  color: SamsungColors.textTertiary, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(album.name,
            style: const TextStyle(
                color: SamsungColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('${album.count}',
            style: const TextStyle(color: SamsungColors.textTertiary, fontSize: 12)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PLACEHOLDER TABS
// ─────────────────────────────────────────────────────────────

class _StoriesTab extends StatelessWidget {
  @override
  Widget build(_) => const _EmptyState(
      icon: Icons.auto_stories_outlined,
      message: 'No stories yet',
      sub: 'Stories from your memories will appear here');
}

class _SharedTab extends StatelessWidget {
  @override
  Widget build(_) => const _EmptyState(
      icon: Icons.people_outline,
      message: 'No shared albums',
      sub: 'Albums shared with you will appear here');
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final String?  sub;

  const _EmptyState({required this.icon, required this.message, this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: SamsungColors.textTertiary, size: 64),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: SamsungColors.textSecondary, fontSize: 17, fontWeight: FontWeight.w600)),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(sub!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SamsungColors.textTertiary, fontSize: 14, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}