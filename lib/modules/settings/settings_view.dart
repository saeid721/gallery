import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/preferences_service.dart';
import 'settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: _buildBody(),
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
      title: Text('Settings', style: AppTextStyles.appBarTitle()),
    );
  }

  // ─── Body ────────────────────────────────────────────────
  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [

        // ─── Appearance ───────────────────────────────────
        _SectionHeader(label: 'APPEARANCE'),
        _buildAppearanceSection(),

        // ─── View ─────────────────────────────────────────
        _SectionHeader(label: 'VIEW'),
        _buildViewSection(),

        // ─── Sort ─────────────────────────────────────────
        _SectionHeader(label: 'SORT'),
        _buildSortSection(),

        // ─── Media ────────────────────────────────────────
        _SectionHeader(label: 'MEDIA'),
        _buildMediaSection(),

        // ─── Storage ──────────────────────────────────────
        _SectionHeader(label: 'STORAGE'),
        _buildStorageSection(),

        // ─── Database Info ────────────────────────────────
        _SectionHeader(label: 'DATABASE'),
        _buildDatabaseSection(),

        // ─── SharedPreferences Info ───────────────────────
        _SectionHeader(label: 'SHARED PREFERENCES'),
        _buildPreferencesSection(),

        // ─── Reset ────────────────────────────────────────
        _SectionHeader(label: 'RESET'),
        _buildResetSection(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // APPEARANCE SECTION
  // SharedPreferences key: "theme_mode"
  // ─────────────────────────────────────────────────────────

  Widget _buildAppearanceSection() {
    return _SettingsCard(
      children: [
        // Dark / Light mode toggle
        Obx(() => _SettingsTile(
          icon:  Icons.dark_mode_outlined,
          title: 'Dark Mode',
          trailing: Switch(
            value:       controller.isDark,
            onChanged:   (_) => controller.toggleTheme(),
            activeColor: SamsungColors.primary,
          ),
        )),

        const _Divider(),

        // Theme mode selector
        Obx(() => _SettingsTile(
          icon:     Icons.palette_outlined,
          title:    'Theme',
          subtitle: _prefs.themeMode.value.capitalize,
          trailing: const Icon(
            Icons.chevron_right,
            color: SamsungColors.textSecondaryDark,
          ),
          onTap: () => _showThemePicker(),
        )),
      ],
    );
  }

  void _showThemePicker() {
    Get.bottomSheet(
      _BottomPicker(
        title:   'Theme Mode',
        options: const ['dark', 'light', 'system'],
        labels:  const ['Dark', 'Light', 'System'],
        current: _prefs.themeMode.value,
        onSelect: controller.setThemeMode,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // VIEW SECTION
  // SharedPreferences keys: "view_mode", "grid_column_count"
  // ─────────────────────────────────────────────────────────

  Widget _buildViewSection() {
    return _SettingsCard(
      children: [
        // View mode
        Obx(() => _SettingsTile(
          icon:     Icons.grid_view_outlined,
          title:    'View Mode',
          subtitle: controller.viewMode == 'grid' ? 'Grid' : 'List',
          trailing: _SegmentedControl(
            options:  const ['grid', 'list'],
            labels:   const ['Grid', 'List'],
            current:  controller.viewMode,
            onSelect: controller.setViewMode,
          ),
        )),

        const _Divider(),

        // Grid columns
        Obx(() => _SettingsTile(
          icon:     Icons.view_column_outlined,
          title:    'Grid Columns',
          subtitle: '${controller.gridColumnCount} columns',
          trailing: const SizedBox.shrink(),
          bottom: Padding(
            padding: const EdgeInsets.only(
              left:   AppDimensions.xxxl + AppDimensions.sm,
              right:  AppDimensions.lg,
              bottom: AppDimensions.md,
            ),
            child: Column(
              children: [
                // Slider 3 → 5
                SliderTheme(
                  data: SliderTheme.of(Get.context!).copyWith(
                    activeTrackColor:   SamsungColors.primary,
                    inactiveTrackColor: SamsungColors.darkDivider,
                    thumbColor:         SamsungColors.primary,
                    overlayColor:
                    SamsungColors.primary.withOpacity(0.2),
                    trackHeight:        3,
                    showValueIndicator:
                    ShowValueIndicator.always,
                    valueIndicatorColor: SamsungColors.primary,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  child: Slider(
                    value:   controller.gridColumnCount.toDouble(),
                    min:     3,
                    max:     5,
                    divisions: 2,
                    label:   '${controller.gridColumnCount}',
                    onChanged: (v) =>
                        controller.setGridColumnCount(v.toInt()),
                  ),
                ),

                // Labels
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text('3', style: TextStyle(
                        color: SamsungColors.textSecondaryDark,
                        fontSize: 12,
                      )),
                      Text('4', style: TextStyle(
                        color: SamsungColors.textSecondaryDark,
                        fontSize: 12,
                      )),
                      Text('5', style: TextStyle(
                        color: SamsungColors.textSecondaryDark,
                        fontSize: 12,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // SORT SECTION
  // SharedPreferences keys: "sort_by", "sort_order"
  // ─────────────────────────────────────────────────────────

  Widget _buildSortSection() {
    return _SettingsCard(
      children: [
        // Sort by
        Obx(() => _SettingsTile(
          icon:     Icons.sort,
          title:    'Sort By',
          subtitle: controller.sortByLabel,
          trailing: const Icon(
            Icons.chevron_right,
            color: SamsungColors.textSecondaryDark,
          ),
          onTap: () => _showSortByPicker(),
        )),

        const _Divider(),

        // Sort order
        Obx(() => _SettingsTile(
          icon:     Icons.swap_vert,
          title:    'Order',
          subtitle: controller.sortOrderLabel,
          trailing: _SegmentedControl(
            options:  const ['DESC', 'ASC'],
            labels:   const ['Newest', 'Oldest'],
            current:  controller.sortOrder,
            onSelect: controller.setSortOrder,
          ),
        )),
      ],
    );
  }

  void _showSortByPicker() {
    Get.bottomSheet(
      _BottomPicker(
        title:   'Sort By',
        options: const ['date_added', 'name', 'file_size'],
        labels:  const ['Date Added', 'Name', 'File Size'],
        current: controller.sortBy,
        onSelect: controller.setSortBy,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MEDIA SECTION
  // SharedPreferences keys:
  //   "auto_play_video", "show_video_duration",
  //   "show_hidden", "slideshow_interval"
  // ─────────────────────────────────────────────────────────

  Widget _buildMediaSection() {
    return _SettingsCard(
      children: [
        // Auto play video
        Obx(() => _SettingsTile(
          icon:  Icons.play_circle_outline,
          title: 'Auto Play Video',
          trailing: Switch(
            value:       controller.autoPlayVideo,
            onChanged:   (_) => controller.toggleAutoPlayVideo(),
            activeColor: SamsungColors.primary,
          ),
        )),

        const _Divider(),

        // Show video duration
        Obx(() => _SettingsTile(
          icon:  Icons.timer_outlined,
          title: 'Show Video Duration',
          trailing: Switch(
            value:       controller.showVideoDuration,
            onChanged:   (_) => controller.toggleShowVideoDuration(),
            activeColor: SamsungColors.primary,
          ),
        )),

        const _Divider(),

        // Show hidden albums
        Obx(() => _SettingsTile(
          icon:  Icons.visibility_outlined,
          title: 'Show Hidden Albums',
          trailing: Switch(
            value:       controller.showHidden,
            onChanged:   (_) => controller.toggleShowHidden(),
            activeColor: SamsungColors.primary,
          ),
        )),

        const _Divider(),

        // Slideshow interval
        Obx(() => _SettingsTile(
          icon:     Icons.slideshow_outlined,
          title:    'Slideshow Speed',
          subtitle: controller.slideshowIntervalLabel,
          trailing: const SizedBox.shrink(),
          bottom: Padding(
            padding: const EdgeInsets.only(
              left:   AppDimensions.xxxl + AppDimensions.sm,
              right:  AppDimensions.lg,
              bottom: AppDimensions.md,
            ),
            child: SliderTheme(
              data: SliderTheme.of(Get.context!).copyWith(
                activeTrackColor:   SamsungColors.primary,
                inactiveTrackColor: SamsungColors.darkDivider,
                thumbColor:         SamsungColors.primary,
                trackHeight:        3,
                showValueIndicator: ShowValueIndicator.always,
                valueIndicatorColor: SamsungColors.primary,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.black,
                ),
              ),
              child: Slider(
                value:     controller.slideshowInterval.toDouble(),
                min:       1000,
                max:       10000,
                divisions: 9,
                label:     controller.slideshowIntervalLabel,
                onChanged: (v) =>
                    controller.setSlideshowInterval(v.toInt()),
              ),
            ),
          ),
        )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // STORAGE SECTION
  // SharedPreferences key: "recycle_bin_days"
  // ─────────────────────────────────────────────────────────

  Widget _buildStorageSection() {
    return _SettingsCard(
      children: [
        // Recycle bin auto-delete days
        Obx(() => _SettingsTile(
          icon:     Icons.delete_sweep_outlined,
          title:    'Auto-Delete Trash After',
          subtitle: controller.recycleBinDaysLabel,
          trailing: const SizedBox.shrink(),
          bottom: Padding(
            padding: const EdgeInsets.only(
              left:   AppDimensions.xxxl + AppDimensions.sm,
              right:  AppDimensions.lg,
              bottom: AppDimensions.md,
            ),
            child: SliderTheme(
              data: SliderTheme.of(Get.context!).copyWith(
                activeTrackColor:   SamsungColors.primary,
                inactiveTrackColor: SamsungColors.darkDivider,
                thumbColor:         SamsungColors.primary,
                trackHeight:        3,
                showValueIndicator: ShowValueIndicator.always,
                valueIndicatorColor: SamsungColors.primary,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.black,
                ),
              ),
              child: Slider(
                value:     controller.recycleBinDays.toDouble(),
                min:       7,
                max:       90,
                divisions: 11,
                label:     controller.recycleBinDaysLabel,
                onChanged: (v) =>
                    controller.setRecycleBinDays(v.toInt()),
              ),
            ),
          ),
        )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // DATABASE SECTION
  // Shows live SQLite stats
  // ─────────────────────────────────────────────────────────

  Widget _buildDatabaseSection() {
    return _SettingsCard(
      children: [
        Obx(() {
          if (controller.isLoadingStats.value) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.lg),
              child: Center(
                child: CircularProgressIndicator(
                  color:       SamsungColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          return Column(
            children: [
              // Total photos
              _StatTile(
                icon:  Icons.photo_library_outlined,
                label: 'Total Photos',
                value: '${controller.totalPhotos}',
              ),
              const _Divider(),

              // Total albums
              _StatTile(
                icon:  Icons.folder_outlined,
                label: 'Total Albums',
                value: '${controller.totalAlbums}',
              ),
              const _Divider(),

              // Total favorites
              _StatTile(
                icon:       Icons.favorite_outline,
                iconColor:  SamsungColors.favorite,
                label:      'Favorites',
                value:      '${controller.totalFavorites}',
              ),
              const _Divider(),

              // Total trash
              _StatTile(
                icon:       Icons.delete_outline,
                iconColor:  SamsungColors.deleteRed,
                label:      'In Trash',
                value:      '${controller.totalTrash}',
              ),
              const _Divider(),

              // Refresh button
              _SettingsTile(
                icon:     Icons.refresh,
                title:    'Refresh Stats',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: SamsungColors.textSecondaryDark,
                ),
                onTap: controller.loadDbStats,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED PREFERENCES SECTION
  // Live view of all SharedPreferences keys + values
  // ─────────────────────────────────────────────────────────

  Widget _buildPreferencesSection() {
    return _SettingsCard(
      children: [
        Obx(() {
          final values = _prefs.allValues;
          return Column(
            children: values.entries.map((entry) {
              final isLast = entry.key == values.keys.last;
              return Column(
                children: [
                  _PrefTile(
                    key_:  entry.key,
                    value: '${entry.value}',
                  ),
                  if (!isLast) const _Divider(),
                ],
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // RESET SECTION
  // ─────────────────────────────────────────────────────────

  Widget _buildResetSection() {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon:       Icons.restore,
          iconColor:  SamsungColors.deleteRed,
          title:      'Reset All Settings',
          titleColor: SamsungColors.deleteRed,
          trailing:   const Icon(
            Icons.chevron_right,
            color: SamsungColors.deleteRed,
          ),
          onTap: controller.resetAllPreferences,
        ),
      ],
    );
  }

  // ─── Convenience getter ──────────────────────────────────
  PreferencesService get _prefs => Get.find<PreferencesService>();
}

// ─────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.xl,
        AppDimensions.lg,
        AppDimensions.xs,
      ),
      child: Text(
        label,
        style: AppTextStyles.dateSectionHeader(
          color: SamsungColors.primary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:     const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
      ),
      decoration: BoxDecoration(
        color:        SamsungColors.darkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData    icon;
  final Color?      iconColor;
  final String      title;
  final Color?      titleColor;
  final String?     subtitle;
  final Widget      trailing;
  final Widget?     bottom;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    required this.trailing,
    this.bottom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical:   AppDimensions.md,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width:       36,
                  height:      36,
                  decoration:  BoxDecoration(
                    color: (iconColor ?? SamsungColors.primary)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSm,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? SamsungColors.primary,
                    size:  18,
                  ),
                ),

                const SizedBox(width: AppDimensions.md),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge(
                          color: titleColor ??
                              SamsungColors.textPrimaryDark,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTextStyles.caption(),
                        ),
                    ],
                  ),
                ),

                trailing,
              ],
            ),
          ),

          // Optional bottom widget (sliders)
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color?   iconColor;
  final String   label;
  final String   value;

  const _StatTile({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical:   AppDimensions.md,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? SamsungColors.textSecondaryDark,
            size:  AppDimensions.iconSm,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(
                color: SamsungColors.textPrimaryDark,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.headingSmall(
              color: SamsungColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final String key_;
  final String value;

  const _PrefTile({
    required this.key_,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical:   AppDimensions.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key_,
              style: AppTextStyles.caption(
                color: SamsungColors.textSecondaryDark,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: AppTextStyles.caption(
                color: SamsungColors.primary,
              ),
              textAlign: TextAlign.right,
              overflow:  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height:  1,
      color:   SamsungColors.darkDivider,
      indent:  AppDimensions.xxxl + AppDimensions.sm,
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<String>   options;
  final List<String>   labels;
  final String         current;
  final Function(String) onSelect;

  const _SegmentedControl({
    required this.options,
    required this.labels,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        SamsungColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final isActive = current == options[i];
          return GestureDetector(
            onTap: () => onSelect(options[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:  const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical:   AppDimensions.xs,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? SamsungColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusSm,
                ),
              ),
              child: Text(
                labels[i],
                style: AppTextStyles.caption(
                  color: isActive
                      ? Colors.black
                      : SamsungColors.textSecondaryDark,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomPicker extends StatelessWidget {
  final String           title;
  final List<String>     options;
  final List<String>     labels;
  final String           current;
  final Function(String) onSelect;

  const _BottomPicker({
    required this.title,
    required this.options,
    required this.labels,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        SamsungColors.darkSurface,
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

          // Title
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Text(
              title,
              style: AppTextStyles.headingMedium(),
            ),
          ),

          const Divider(height: 1, color: SamsungColors.darkDivider),

          // Options
          ...List.generate(options.length, (i) {
            final isSelected = current == options[i];
            return InkWell(
              onTap: () {
                onSelect(options[i]);
                Get.back();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical:   AppDimensions.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labels[i],
                        style: AppTextStyles.bodyLarge(
                          color: isSelected
                              ? SamsungColors.primary
                              : SamsungColors.textPrimaryDark,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: SamsungColors.primary,
                        size:  20,
                      ),
                  ],
                ),
              ),
            );
          }),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                AppDimensions.lg,
          ),
        ],
      ),
    );
  }
}