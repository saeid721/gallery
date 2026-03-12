import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

class SamsungBottomNav extends StatelessWidget {
  final int          currentIndex;
  final Function(int) onTap;

  const SamsungBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SamsungColors.darkBottomNav,
        border: Border(
          top: BorderSide(
            color: SamsungColors.darkDivider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon:        Icons.photo_library_outlined,
                activeIcon:  Icons.photo_library,
                label:       'Photos',
                isActive:    currentIndex == 0,
                onTap:       () => onTap(0),
              ),
              _NavItem(
                icon:        Icons.grid_view_outlined,
                activeIcon:  Icons.grid_view,
                label:       'Albums',
                isActive:    currentIndex == 1,
                onTap:       () => onTap(1),
              ),
              _NavItem(
                icon:        Icons.auto_stories_outlined,
                activeIcon:  Icons.auto_stories,
                label:       'Stories',
                isActive:    currentIndex == 2,
                onTap:       () => onTap(2),
              ),
              _NavItem(
                icon:        Icons.explore_outlined,
                activeIcon:  Icons.explore,
                label:       'Explore',
                isActive:    currentIndex == 3,
                onTap:       () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData     icon;
  final IconData     activeIcon;
  final String       label;
  final bool         isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:     onTap,
      behavior:  HitTestBehavior.opaque,
      child: SizedBox(
        width: Get.width / 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:    isActive ? 20 : 0,
              height:   2,
              margin:   const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color:        SamsungColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),

            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key:   ValueKey(isActive),
                color: isActive
                    ? SamsungColors.primary
                    : SamsungColors.textSecondaryDark,
                size:  24,
              ),
            ),

            const SizedBox(height: 2),

            // Label
            Text(
              label,
              style: AppTextStyles.label(
                color: isActive
                    ? SamsungColors.primary
                    : SamsungColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}