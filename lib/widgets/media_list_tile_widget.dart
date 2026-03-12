import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../models/media_item.dart';
import '../core/theme/app_text_styles.dart';

class MediaListTileWidget extends StatelessWidget {
  final MediaItem    item;
  final bool         isSelected;
  final bool         isSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;

  const MediaListTileWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:       onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical:   AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? SamsungColors.selectedBg
              : Colors.transparent,
          border: isSelected
              ? Border.all(
            color: SamsungColors.selectedBorder,
            width: 0.5,
          )
              : null,
        ),
        child: Row(
          children: [

            // ─── Select checkbox ──────────────────────────
            if (isSelectMode)
              Padding(
                padding: const EdgeInsets.only(
                  right: AppDimensions.md,
                ),
                child: _CheckCircle(isSelected: isSelected),
              ),

            // ─── Thumbnail ────────────────────────────────
            Hero(
              tag: item.heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusSm,
                ),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUri,
                  width:    64,
                  height:   64,
                  fit:      BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width:  64,
                    height: 64,
                    color:  SamsungColors.darkCard,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.md),

            // ─── Info ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  // Filename
                  Text(
                    item.filename,
                    style:    AppTextStyles.bodyMedium(
                      color: SamsungColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Date
                  Text(
                    _formatDate(item.dateTime),
                    style: AppTextStyles.caption(),
                  ),

                  const SizedBox(height: 2),

                  // Meta row
                  Row(
                    children: [
                      // File size
                      Text(
                        item.formattedSize,
                        style: AppTextStyles.caption(
                          color: SamsungColors.textTertiaryDark,
                        ),
                      ),

                      const SizedBox(width: AppDimensions.sm),

                      // Resolution
                      Text(
                        item.resolution,
                        style: AppTextStyles.caption(
                          color: SamsungColors.textTertiaryDark,
                        ),
                      ),

                      // Location
                      if (item.hasLocation) ...[
                        const SizedBox(width: AppDimensions.xs),
                        const Icon(
                          Icons.location_on_outlined,
                          color: SamsungColors.primary,
                          size:  10,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ─── Trailing actions ─────────────────────────
            if (!isSelectMode)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite
                  GestureDetector(
                    onTap: onFavorite,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      child: Icon(
                        item.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: item.isFavorite
                            ? SamsungColors.favorite
                            : SamsungColors.textSecondaryDark,
                        size: AppDimensions.iconSm,
                      ),
                    ),
                  ),

                  // Video badge
                  if (item.isVideo)
                    const Icon(
                      Icons.play_circle_outline,
                      color: SamsungColors.primary,
                      size:  AppDimensions.iconSm,
                    ),
                ],
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

class _CheckCircle extends StatelessWidget {
  final bool isSelected;
  const _CheckCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width:    22,
      height:   22,
      decoration: BoxDecoration(
        color:  isSelected ? SamsungColors.primary : Colors.transparent,
        shape:  BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? SamsungColors.primary
              : SamsungColors.textSecondaryDark,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.black, size: 13)
          : null,
    );
  }
}