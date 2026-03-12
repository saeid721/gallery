import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

class ShimmerGrid extends StatefulWidget {
  final int columnCount;
  const ShimmerGrid({super.key, required this.columnCount});

  @override
  State<ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.xs),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   widget.columnCount,
        crossAxisSpacing: AppDimensions.xs,
        mainAxisSpacing:  AppDimensions.xs,
      ),
      itemCount: widget.columnCount * 6,
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _anim,
        builder:   (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment(_anim.value - 1, 0),
                end:    Alignment(_anim.value, 0),
                colors: const [
                  SamsungColors.shimmerBase,
                  SamsungColors.shimmerHighlight,
                  SamsungColors.shimmerBase,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}