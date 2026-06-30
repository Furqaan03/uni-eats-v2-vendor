import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// One segment in a [SegmentedTabs] control.
class SegTab {
  final String label;
  final IconData? icon;
  const SegTab(this.label, {this.icon});
}

/// A modern pill/segmented tab control backed by a [TabController] — a drop-in,
/// nicer-looking replacement for Material's underline [TabBar]. The selected
/// segment slides under a filled primary pill; tapping animates the controller
/// (and the paired [TabBarView]) to that page.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  final TabController controller;
  final List<SegTab> tabs;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final track = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: AnimatedBuilder(
        // Rebuild as the controller moves (tap or swipe).
        animation: controller.animation ?? controller,
        builder: (context, _) {
          final value = controller.animation?.value ?? controller.index.toDouble();
          return Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _Segment(
                    tab: tabs[i],
                    // Smoothly weight the pill toward the nearest tab so a
                    // swipe gesture animates instead of snapping.
                    selectedAmount: (1 - (value - i).abs()).clamp(0.0, 1.0),
                    onTap: () => controller.animateTo(i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.tab, required this.selectedAmount, required this.onTap});
  final SegTab tab;
  final double selectedAmount; // 0 = unselected, 1 = fully selected
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.outline;
    final fg = Color.lerp(muted, Colors.white, selectedAmount)!;
    final t = Curves.easeOut.transform(selectedAmount);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: t > 0.01
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: t),
                    AppColors.primaryDark.withValues(alpha: t),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(11),
          boxShadow: t > 0.5
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30 * t),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tab.icon != null) ...[
              Icon(tab.icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.lerp(FontWeight.w600, FontWeight.w800, t),
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
