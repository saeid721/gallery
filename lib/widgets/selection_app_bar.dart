import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class SelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int          selectedCount;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;

  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onSelectAll,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:        SamsungColors.darkSurface,
      elevation:              0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon:      const Icon(Icons.close),
        onPressed: onClose,
        color:     SamsungColors.textPrimaryDark,
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          key:   ValueKey(selectedCount),
          '$selectedCount selected',
          style: AppTextStyles.headingMedium(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onSelectAll,
          child: Text(
            'Select All',
            style: AppTextStyles.button(),
          ),
        ),
      ],
    );
  }
}