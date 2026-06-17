import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/vendor_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/models/menu_item.dart';
import '../menu_item_detail_screen.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item, required this.vendor});

  final MenuItem item;
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          fadeSlidePage(MenuItemDetailScreen(itemId: item.id))),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAvailable
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.imagePath != null
                  ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.fastfood_rounded,
                          color: AppColors.primary.withValues(alpha: 0.6),
                          size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Content — no toggle here, no overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: theme.textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (item.isFeatured)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Featured',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(item.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(formatCurrency(item.price),
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.primary)),
                    if (item.calories != null) ...[
                      const SizedBox(width: 8),
                      Text('${item.calories} cal',
                          style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Toggle — fixed-width column, never competes for space
          _AvailToggle(item: item, vendor: vendor),
        ],
      ),
    ),
    );
  }
}

class _AvailToggle extends StatelessWidget {
  const _AvailToggle({required this.item, required this.vendor});
  final MenuItem item;
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: item.isAvailable,
          onChanged: (_) => vendor.toggleItemAvailability(item.id),
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          inactiveThumbColor: AppColors.error,
          inactiveTrackColor: AppColors.error.withValues(alpha: 0.2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          item.isAvailable ? 'On' : 'Off',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: item.isAvailable ? AppColors.primary : AppColors.error,
          ),
        ),
      ],
    );
  }
}
