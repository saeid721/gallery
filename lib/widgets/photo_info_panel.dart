import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../models/media_item.dart';
import '../core/theme/app_text_styles.dart';

class PhotoInfoPanel extends StatelessWidget {
  final MediaItem    item;
  final VoidCallback onClose;

  const PhotoInfoPanel({
    super.key,
    required this.item,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SamsungColors.darkSurface,
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

          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                Text('Details', style: AppTextStyles.headingMedium()),
                const Spacer(),
                IconButton(
                  icon:      const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                  padding:   EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: SamsungColors.darkDivider),

          // Info rows
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              children: [
                _InfoRow(
                  icon:  Icons.image_outlined,
                  label: 'Filename',
                  value: item.filename,
                ),
                _InfoRow(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _formatDate(item.dateTime),
                ),
                _InfoRow(
                  icon:  Icons.photo_size_select_large_outlined,
                  label: 'Resolution',
                  value: item.resolution,
                ),
                _InfoRow(
                  icon:  Icons.storage_outlined,
                  label: 'File Size',
                  value: item.formattedSize,
                ),
                _InfoRow(
                  icon:  Icons.perm_media_outlined,
                  label: 'Type',
                  value: item.mediaType.toUpperCase(),
                ),
                if (item.hasLocation)
                  _InfoRow(
                    icon:       Icons.location_on_outlined,
                    label:      'Location',
                    value: '${item.latitude!.toStringAsFixed(4)}, '
                        '${item.longitude!.toStringAsFixed(4)}',
                    valueColor: SamsungColors.primary,
                  ),
                if (item.isFavorite)
                  _InfoRow(
                    icon:       Icons.favorite,
                    label:      'Favorited',
                    value:      'Yes',
                    iconColor:  SamsungColors.favorite,
                    valueColor: SamsungColors.favorite,
                  ),
              ],
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   iconColor;
  final Color?   valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? SamsungColors.textSecondaryDark,
            size:  AppDimensions.iconSm,
          ),
          const SizedBox(width: AppDimensions.md),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodySmall(),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium(
                color: valueColor ?? SamsungColors.textPrimaryDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}