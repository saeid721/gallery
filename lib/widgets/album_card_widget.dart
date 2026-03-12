import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../models/album.dart';
import '../core/theme/app_text_styles.dart';

class AlbumCardWidget extends StatelessWidget {
  final Album        album;
  final bool         isSelected;
  final bool         isSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AlbumCardWidget({
    super.key,
    required this.album,
    required this.onTap,
    required this.onLongPress,
    this.isSelected  = false,
    this.isSelectMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:       onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── Cover ──────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSm,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: album.coverUri,
                    fit:      BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: SamsungColors.darkCard,
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: SamsungColors.textSecondaryDark,
                        size:  32,
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
                        decoration: BoxDecoration(
                          color: SamsungColors.selectedBg,
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
                if (isSelectMode)
                  Positioned(
                    top:   8,
                    right: 8,
                    child: _CheckCircle(isSelected: isSelected),
                  ),

                // Type icon badge
                Positioned(
                  top:  8,
                  left: 8,
                  child: _TypeBadge(type: album.albumType),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.xs),

          // ─── Name ────────────────────────────────────────
          Text(
            album.name,
            style:    AppTextStyles.headingSmall(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ─── Count ───────────────────────────────────────
          Text(
            album.itemCountLabel,
            style: AppTextStyles.caption(),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        Colors.black45,
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusFull,
        ),
      ),
      child: Icon(
        _icon(type),
        color: Colors.white,
        size:  12,
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'camera':     return Icons.camera_alt_outlined;
      case 'screenshot': return Icons.screenshot_outlined;
      case 'download':   return Icons.download_outlined;
      default:           return Icons.folder_outlined;
    }
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
          color: isSelected ? SamsungColors.primary : Colors.white,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.black, size: 13)
          : null,
    );
  }
}