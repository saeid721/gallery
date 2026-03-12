import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/preferences_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<PreferencesService>();

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

          // ─── Handle ──────────────────────────────────
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

          // ─── Title ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                Text(
                  'Sort By',
                  style: AppTextStyles.headingMedium(),
                ),
                const Spacer(),
                // ASC / DESC toggle
                Obx(() => _OrderToggle(
                  isDesc:   prefs.sortOrder.value == 'DESC',
                  onToggle: prefs.toggleSortOrder,
                )),
              ],
            ),
          ),

          const Divider(height: 1, color: SamsungColors.darkDivider),

          // ─── Sort options ─────────────────────────────
          Obx(() => Column(
            children: [
              _SortOption(
                icon:      Icons.calendar_today_outlined,
                label:     'Date Added',
                isActive:  prefs.sortBy.value == 'date_added',
                onTap: () {
                  prefs.sortBy.value = 'date_added';
                  Get.back();
                },
              ),
              const Divider(
                height: 1,
                color:  SamsungColors.darkDivider,
                indent: AppDimensions.xxxl + AppDimensions.sm,
              ),
              _SortOption(
                icon:      Icons.sort_by_alpha,
                label:     'Name',
                isActive:  prefs.sortBy.value == 'name',
                onTap: () {
                  prefs.sortBy.value = 'name';
                  Get.back();
                },
              ),
              const Divider(
                height: 1,
                color:  SamsungColors.darkDivider,
                indent: AppDimensions.xxxl + AppDimensions.sm,
              ),
              _SortOption(
                icon:      Icons.storage_outlined,
                label:     'File Size',
                isActive:  prefs.sortBy.value == 'file_size',
                onTap: () {
                  prefs.sortBy.value = 'file_size';
                  Get.back();
                },
              ),
            ],
          )),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                AppDimensions.lg,
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         isActive;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
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
            Icon(
              icon,
              color: isActive
                  ? SamsungColors.primary
                  : SamsungColors.textSecondaryDark,
              size: AppDimensions.iconSm,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge(
                  color: isActive
                      ? SamsungColors.primary
                      : SamsungColors.textPrimaryDark,
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check,
                color: SamsungColors.primary,
                size:  AppDimensions.iconSm,
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderToggle extends StatelessWidget {
  final bool         isDesc;
  final VoidCallback onToggle;

  const _OrderToggle({
    required this.isDesc,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical:   AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color:        SamsungColors.darkCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDesc
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: SamsungColors.primary,
              size:  14,
            ),
            const SizedBox(width: 4),
            Text(
              isDesc ? 'Newest' : 'Oldest',
              style: AppTextStyles.caption(
                color: SamsungColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}