import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'search_controller.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/media_item.dart';
import '../../models/album.dart';
import '../../widgets/shimmer_grid.dart';

class SearchView extends GetView<SearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamsungColors.darkBackground,
      body: Column(
        children: [

          // ─── Search bar ──────────────────────────────────
          _SearchBar(controller: controller),

          // ─── Filter chips ────────────────────────────────
          Obx(() => controller.isSearching.value
              ? _FilterChips(controller: controller)
              : const SizedBox.shrink()),

          // ─── Body ────────────────────────────────────────
          Expanded(
            child: Obx(() {
              // Loading
              if (controller.isLoading.value) {
                return ShimmerGrid(
                  columnCount: Get
                      .find<PreferencesService>()
                      .gridColumnCount
                      .value,
                );
              }

              // Not yet searched → show recent + suggestions
              if (!controller.isSearching.value) {
                return _IdleBody(controller: controller);
              }

              // Empty results
              if (controller.isEmpty) {
                return _EmptyResults(
                  query: controller.query.value,
                );
              }

              // Results
              return _ResultsBody(controller: controller);
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final SearchController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color:   SamsungColors.darkSurface,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.sm,
        topPad + AppDimensions.sm,
        AppDimensions.sm,
        AppDimensions.sm,
      ),
      child: Row(
        children: [

          // Back button
          IconButton(
            icon:      const Icon(Icons.arrow_back),
            color:     SamsungColors.textPrimaryDark,
            onPressed: Get.back,
          ),

          // Search input
          Expanded(
            child: Container(
              height:     44,
              decoration: BoxDecoration(
                color:        SamsungColors.darkCard,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusFull,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    child: Icon(
                      Icons.search,
                      color: SamsungColors.textSecondaryDark,
                      size:  20,
                    ),
                  ),

                  // TextField
                  Expanded(
                    child: TextField(
                      controller:  controller.textController,
                      focusNode:   controller.focusNode,
                      style:       AppTextStyles.bodyLarge(),
                      decoration:  InputDecoration(
                        hintText:     'Search photos, albums...',
                        hintStyle:    AppTextStyles.bodyLarge(
                          color: SamsungColors.textSecondaryDark,
                        ),
                        border:       InputBorder.none,
                        isDense:      true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged:   controller.onQueryChanged,
                      onSubmitted: controller.submitSearch,
                      textInputAction: TextInputAction.search,
                    ),
                  ),

                  // Clear button
                  Obx(() => controller.query.value.isNotEmpty
                      ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: SamsungColors.textSecondaryDark,
                      size:  18,
                    ),
                    onPressed: controller.clearQuery,
                    padding:   EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth:  36,
                      minHeight: 36,
                    ),
                  )
                      : const SizedBox(width: AppDimensions.sm)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER CHIPS
// ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final SearchController controller;
  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:  SamsungColors.darkSurface,
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical:   AppDimensions.xs,
        ),
        children: [
          _buildChip(
            label:  'All',
            count:  controller.mediaCount + controller.albumCount,
            filter: SearchFilter.all,
          ),
          _buildChip(
            label:  'Photos',
            count:  controller.mediaResults
                .where((m) => m.mediaType == 'image')
                .length,
            filter: SearchFilter.photos,
          ),
          _buildChip(
            label:  'Videos',
            count:  controller.mediaResults
                .where((m) => m.mediaType == 'video')
                .length,
            filter: SearchFilter.videos,
          ),
          _buildChip(
            label:  'Albums',
            count:  controller.albumCount,
            filter: SearchFilter.albums,
          ),
          _buildChip(
            label:  'Favorites',
            count:  controller.favoriteCount,
            filter: SearchFilter.favorites,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String       label,
    required int          count,
    required SearchFilter filter,
  }) {
    return Obx(() {
      final isActive = controller.activeFilter.value == filter;
      return GestureDetector(
        onTap: () => controller.setFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: AppDimensions.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical:   AppDimensions.xs,
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
            count > 0 ? '$label ($count)' : label,
            style: AppTextStyles.caption(
              color: isActive
                  ? Colors.black
                  : SamsungColors.textSecondaryDark,
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// IDLE BODY (before search)
// ─────────────────────────────────────────────────────────────

class _IdleBody extends StatelessWidget {
  final SearchController controller;
  const _IdleBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [

        // ─── Recent searches ──────────────────────────────
        Obx(() => controller.recentSearches.isNotEmpty
            ? SliverToBoxAdapter(
          child: _RecentSearches(controller: controller),
        )
            : const SliverToBoxAdapter(child: SizedBox.shrink())),

        // ─── Search suggestions ───────────────────────────
        SliverToBoxAdapter(
          child: _SearchSuggestions(controller: controller),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }
}

// ─── Recent searches ──────────────────────────────────────────
class _RecentSearches extends StatelessWidget {
  final SearchController controller;
  const _RecentSearches({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.lg,
            AppDimensions.lg,
            AppDimensions.lg,
            AppDimensions.xs,
          ),
          child: Row(
            children: [
              Text(
                'RECENT',
                style: AppTextStyles.dateSectionHeader(),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.clearRecentSearches,
                child: Text(
                  'Clear',
                  style: AppTextStyles.caption(
                    color: SamsungColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Recent list
        ...controller.recentSearches.map((r) {
          return _RecentSearchTile(
            query:    r.query,
            onTap:    () => controller.searchFromRecent(r.query),
            onRemove: () => controller.removeRecentSearch(r.query),
          );
        }),
      ],
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final String       query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchTile({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical:   AppDimensions.md,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history,
              color: SamsungColors.textSecondaryDark,
              size:  AppDimensions.iconSm,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(
                query,
                style: AppTextStyles.bodyMedium(
                  color: SamsungColors.textPrimaryDark,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                color: SamsungColors.textSecondaryDark,
                size:  AppDimensions.iconSm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search suggestions ───────────────────────────────────────
class _SearchSuggestions extends StatelessWidget {
  final SearchController controller;
  const _SearchSuggestions({required this.controller});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      _Suggestion(
        icon:  Icons.calendar_today_outlined,
        label: 'Today',
        color: SamsungColors.primary,
      ),
      _Suggestion(
        icon:  Icons.favorite_outline,
        label: 'Favorites',
        color: SamsungColors.favorite,
      ),
      _Suggestion(
        icon:  Icons.camera_alt_outlined,
        label: 'Camera',
        color: const Color(0xFF4CAF50),
      ),
      _Suggestion(
        icon:  Icons.screenshot_outlined,
        label: 'Screenshots',
        color: const Color(0xFFFF9800),
      ),
      _Suggestion(
        icon:  Icons.download_outlined,
        label: 'Downloads',
        color: const Color(0xFF9C27B0),
      ),
      _Suggestion(
        icon:  Icons.location_on_outlined,
        label: 'Location',
        color: const Color(0xFFE91E63),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.md,
          ),
          child: Text(
            'SUGGESTIONS',
            style: AppTextStyles.dateSectionHeader(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
          ),
          child: Wrap(
            spacing:     AppDimensions.sm,
            runSpacing:  AppDimensions.sm,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  controller.textController.text = s.label;
                  controller.onQueryChanged(s.label);
                  controller.focusNode.unfocus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical:   AppDimensions.sm,
                  ),
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(
                      color: s.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, color: s.color, size: 14),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        s.label,
                        style: AppTextStyles.caption(color: s.color),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String   label;
  final Color    color;
  const _Suggestion({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────
// RESULTS BODY
// ─────────────────────────────────────────────────────────────

class _ResultsBody extends StatelessWidget {
  final SearchController controller;
  const _ResultsBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [

        // Result count header
        Obx(() => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.md,
              AppDimensions.lg,
              AppDimensions.xs,
            ),
            child: Text(
              controller.resultCountLabel,
              style: AppTextStyles.caption(),
            ),
          ),
        )),

        // Results list
        Obx(() => SliverList(
          delegate: SliverChildBuilderDelegate(
                (_, index) {
              final result = controller.results[index];
              if (result.type == SearchResultType.album) {
                return _AlbumResultTile(
                  album:  result.album!,
                  query:  controller.query.value,
                  onTap:  () => controller.openAlbum(result.album!),
                );
              }
              return _MediaResultTile(
                item:   result.media!,
                query:  controller.query.value,
                onTap:  () => controller.openPhoto(result.media!),
              );
            },
            childCount: controller.results.length,
          ),
        )),

        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MEDIA RESULT TILE
// ─────────────────────────────────────────────────────────────

class _MediaResultTile extends StatelessWidget {
  final MediaItem    item;
  final String       query;
  final VoidCallback onTap;

  const _MediaResultTile({
    required this.item,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical:   AppDimensions.sm,
        ),
        child: Row(
          children: [

            // Thumbnail
            Hero(
              tag: item.heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusSm,
                ),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUri,
                  width:    56,
                  height:   56,
                  fit:      BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  // Highlighted filename
                  _HighlightedText(
                    text:  item.filename,
                    query: query,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(item.dateTime),
                    style: AppTextStyles.caption(),
                  ),
                  Text(
                    item.formattedSize,
                    style: AppTextStyles.caption(
                      color: SamsungColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // Favorite
            if (item.isFavorite)
              const Padding(
                padding: EdgeInsets.only(left: AppDimensions.sm),
                child: Icon(
                  Icons.favorite,
                  color: SamsungColors.favorite,
                  size:  14,
                ),
              ),

            // Video badge
            if (item.isVideo)
              const Padding(
                padding: EdgeInsets.only(left: AppDimensions.xs),
                child: Icon(
                  Icons.play_circle_outline,
                  color: SamsungColors.primary,
                  size:  14,
                ),
              ),
          ],
        ),
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
// ALBUM RESULT TILE
// ─────────────────────────────────────────────────────────────

class _AlbumResultTile extends StatelessWidget {
  final Album        album;
  final String       query;
  final VoidCallback onTap;

  const _AlbumResultTile({
    required this.album,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical:   AppDimensions.sm,
        ),
        child: Row(
          children: [

            // Album cover
            ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusSm,
              ),
              child: CachedNetworkImage(
                imageUrl: album.coverUri,
                width:    56,
                height:   56,
                fit:      BoxFit.cover,
                placeholder: (_, __) => Container(
                  width:  56,
                  height: 56,
                  color:  SamsungColors.darkCard,
                  child: const Icon(
                    Icons.folder_outlined,
                    color: SamsungColors.textSecondaryDark,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  // Highlighted album name
                  _HighlightedText(
                    text:  album.name,
                    query: query,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.itemCountLabel,
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
            ),

            // Album badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.sm,
                vertical:   2,
              ),
              decoration: BoxDecoration(
                color: SamsungColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Album',
                style: AppTextStyles.caption(
                  color: SamsungColors.primary,
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.sm),
            const Icon(
              Icons.chevron_right,
              color: SamsungColors.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY RESULTS
// ─────────────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size:  64,
            color: SamsungColors.textSecondaryDark,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'No results for',
            style: AppTextStyles.bodyMedium(),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            '"$query"',
            style: AppTextStyles.headingMedium(
              color: SamsungColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Try different keywords',
            style: AppTextStyles.caption(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HIGHLIGHTED TEXT
// ─────────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({
    required this.text,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style:    AppTextStyles.bodyMedium(
          color: SamsungColors.textPrimaryDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText  = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index      = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style:    AppTextStyles.bodyMedium(
          color: SamsungColors.textPrimaryDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          // Before match
          if (index > 0)
            TextSpan(
              text:  text.substring(0, index),
              style: AppTextStyles.bodyMedium(
                color: SamsungColors.textPrimaryDark,
              ),
            ),

          // Match (highlighted)
          TextSpan(
            text: text.substring(index, index + query.length),
            style: AppTextStyles.bodyMedium(
              color: SamsungColors.primary,
            ).copyWith(
              backgroundColor: SamsungColors.primary.withOpacity(0.15),
              fontWeight:      FontWeight.w700,
            ),
          ),

          // After match
          if (index + query.length < text.length)
            TextSpan(
              text:  text.substring(index + query.length),
              style: AppTextStyles.bodyMedium(
                color: SamsungColors.textPrimaryDark,
              ),
            ),
        ],
      ),
    );
  }
}