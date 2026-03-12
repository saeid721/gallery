import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String   message;
  final String?  actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            TweenAnimationBuilder<double>(
              tween:    Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve:    Curves.elasticOut,
              builder:  (_, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Icon(
                icon,
                size:  72,
                color: SamsungColors.textSecondaryDark,
              ),
            ),

            const SizedBox(height: AppDimensions.lg),

            // Message
            Text(
              message,
              style:     AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.xl),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: SamsungColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xl,
                    vertical:   AppDimensions.sm,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.button(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}