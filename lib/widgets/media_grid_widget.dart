import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../models/media_item.dart';

class MediaGridWidget extends StatelessWidget {
  final List<MediaItem>     items;
  final int                 columnCount;
  final bool                isSelectMode;
  final Set<String> selectedIds;   // assetId-based
  final Function(MediaItem) onTap;
  final Function(MediaItem) onLongPress;
  final Function(MediaItem) onToggleSelect;
  final Function(MediaItem) onToggleFavorite;


  const MediaGridWidget({
    super.key,
    required this.items,
    required this.columnCount,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
    required this.onToggleFavorite,
    this.isSelectMode = false,
    this.selectedIds  = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   columnCount,
        crossAxisSpacing: AppDimensions.gridSpacing,
        mainAxisSpacing:  AppDimensions.gridSpacing,
      ),
      delegate: SliverChildBuilderDelegate(
            (_, index) {
          final item       = items[index];
          final assetId    = item.assetId ?? '';
          final isSelected = selectedIds.contains(assetId);

          return _MediaGridCell(
            key:              ValueKey(assetId.isNotEmpty ? assetId : item.filename),
            item:             item,
            isSelected:       isSelected,
            isSelectMode:     isSelectMode,
            showOverlays:     columnCount <= 4,
            onTap:            () => isSelectMode
                ? onToggleSelect(item)
                : onTap(item),
            onLongPress:      () => onLongPress(item),
            onToggleFavorite: () => onToggleFavorite(item),
          );
        },
        childCount: items.length,
        // Reuse cells as user scrolls — critical for performance
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SINGLE CELL
// ─────────────────────────────────────────────────────────────

class _MediaGridCell extends StatelessWidget {
  final MediaItem    item;
  final bool         isSelected;
  final bool         isSelectMode;
  final bool         showOverlays;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;

  const _MediaGridCell({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isSelectMode,
    required this.showOverlays,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:       onTap,
      onLongPress: onLongPress,
      child: AnimatedScale(
        scale:    isSelected ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve:    Curves.easeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ─── Thumbnail ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              child: _ThumbnailImage(item: item, isSelected: isSelected),
            ),

            // ─── Selected blue border ────────────────────
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      border: Border.all(
                        color: SamsungColors.accent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Check circle ────────────────────────────
            if (isSelectMode)
              Positioned(
                top:   6,
                right: 6,
                child: _CheckCircle(isSelected: isSelected),
              ),

            // ─── Bottom gradient ─────────────────────────
            if (showOverlays &&
                (item.isFavorite || item.isVideo || item.hasLocation) &&
                !isSelectMode)
              Positioned(
                left: 0, right: 0, bottom: 0, height: 44,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.topCenter,
                        end:    Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Video badge + duration ──────────────────
            if (item.isVideo && !isSelectMode && showOverlays)
              Positioned(
                bottom: 5,
                left:   5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size:  13,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    const SizedBox(width: 1),
                    Text(
                      item.formattedDuration,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Favorite heart ──────────────────────────
            if (item.isFavorite && !isSelectMode && showOverlays)
              Positioned(
                bottom: 5,
                right:  5,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color:   SamsungColors.favorite,
                    size:    14,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
              ),

            // ─── Location pin ─────────────────────────────
            if (item.hasLocation && !isSelectMode && showOverlays)
              Positioned(
                bottom: item.isFavorite ? 22 : 5,
                right:  5,
                child: const Icon(
                  Icons.location_on_rounded,
                  color:   SamsungColors.locationPin,
                  size:    12,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// THUMBNAIL IMAGE
// Uses AssetEntityImageProvider (photo_manager_image_provider)
// for native OS thumbnail cache — smooth & memory-efficient
// ─────────────────────────────────────────────────────────────

class _ThumbnailImage extends StatelessWidget {
  final MediaItem item;
  final bool      isSelected;

  const _ThumbnailImage({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    // If we have an assetId → use native provider
    if (item.assetId != null && item.assetId!.isNotEmpty) {
      return _AssetThumbnail(assetId: item.assetId!, isSelected: isSelected);
    }

    // Fallback for network/URL items (sample data)
    return Image.network(
      item.thumbnailUri,
      fit:         BoxFit.cover,
      color:       isSelected ? Colors.black.withOpacity(0.35) : null,
      colorBlendMode: BlendMode.darken,
      loadingBuilder: (_, child, progress) =>
      progress == null ? child : const _ShimmerCell(),
      errorBuilder: (_, __, ___) => const _BrokenImage(),
    );
  }
}

class _AssetThumbnail extends StatefulWidget {
  final String assetId;
  final bool   isSelected;

  const _AssetThumbnail({required this.assetId, required this.isSelected});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  AssetEntity? _entity;
  bool         _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadEntity();
  }

  Future<void> _loadEntity() async {
    final e = await AssetEntity.fromId(widget.assetId);
    if (mounted) setState(() { _entity = e; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const _ShimmerCell();
    if (_entity == null) return const _BrokenImage();

    return Hero(
      tag: 'media_${widget.assetId}',
      child: Image(
        image: AssetEntityImageProvider(
          _entity!,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize.square(300),
        ),
        fit:         BoxFit.cover,
        color:       widget.isSelected ? Colors.black.withOpacity(0.35) : null,
        colorBlendMode: BlendMode.darken,
        frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const _ShimmerCell();
        },
        errorBuilder: (_, __, ___) => const _BrokenImage(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHECK CIRCLE
// ─────────────────────────────────────────────────────────────

class _CheckCircle extends StatelessWidget {
  final bool isSelected;
  const _CheckCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width:  AppDimensions.checkboxSize,
      height: AppDimensions.checkboxSize,
      decoration: BoxDecoration(
        color:  isSelected ? SamsungColors.accent : Colors.black.withOpacity(0.35),
        shape:  BoxShape.circle,
        border: Border.all(
          color: isSelected ? SamsungColors.accent : Colors.white.withOpacity(0.85),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHIMMER PLACEHOLDER
// ─────────────────────────────────────────────────────────────

class _ShimmerCell extends StatefulWidget {
  const _ShimmerCell();

  @override
  State<_ShimmerCell> createState() => _ShimmerCellState();
}

class _ShimmerCellState extends State<_ShimmerCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment(_anim.value - 1, 0),
            end:    Alignment(_anim.value, 0),
            colors: const [
              SamsungColors.shimmerBase,
              SamsungColors.shimmerHigh,
              SamsungColors.shimmerBase,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BROKEN IMAGE
// ─────────────────────────────────────────────────────────────

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SamsungColors.surface,
      child: const Icon(Icons.broken_image_outlined,
          color: SamsungColors.textTertiary, size: 28),
    );
  }
}