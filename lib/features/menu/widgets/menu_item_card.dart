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

  void _openDetail(BuildContext context) => Navigator.of(context)
      .push(fadeSlidePage(MenuItemDetailScreen(itemId: item.id)));

  void _toggle(BuildContext context) {
    vendor.toggleItemAvailability(item.id);
    final nowHidden = item.isAvailable; // value flips after the call
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(nowHidden
            ? '"${item.name}" hidden from customers'
            : '"${item.name}" is now available'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        _openDetail(context);
        break;
      case 'duplicate':
        final copy = vendor.duplicateMenuItem(item.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Duplicated "${item.name}"'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Edit',
              onPressed: () => Navigator.of(context)
                  .push(fadeSlidePage(MenuItemDetailScreen(itemId: copy.id))),
            ),
          ));
        break;
      case 'toggle':
        _toggle(context);
        break;
      case 'delete':
        await _confirmDelete(context);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "${item.name}" from your menu? This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      vendor.removeMenuItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Removed "${item.name}"'),
            behavior: SnackBarBehavior.floating,
          ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hidden = !item.isAvailable;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hidden
                ? AppColors.error.withValues(alpha: 0.35)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail (with a "Hidden" overlay when unavailable)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.imagePath != null
                        ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.fastfood_rounded,
                                color: AppColors.primary.withValues(alpha: 0.6), size: 28),
                          ),
                    if (hidden)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: const Icon(Icons.visibility_off_rounded,
                            color: Colors.white, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Opacity(
                opacity: hidden ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item.name,
                              style: theme.textTheme.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (hidden)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Hidden',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(item.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    // Price + prep + key signals
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.hasDiscount) ...[
                          Text(formatCurrency(item.discountedPrice),
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: AppColors.primary)),
                          Text(formatCurrency(item.price),
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.error,
                                color: AppColors.error.withValues(alpha: 0.7),
                              )),
                          _Pill(
                            label: '-${item.discountPercent!.toInt()}%',
                            color: AppColors.primary,
                          ),
                        ] else
                          Text(formatCurrency(item.price),
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: AppColors.primary)),
                        _MetaText(icon: Icons.timer_outlined, label: '${item.prepMinutes} min'),
                        if (item.calories != null)
                          _MetaText(icon: Icons.local_fire_department_outlined, label: '${item.calories} cal'),
                      ],
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          for (final t in item.tags.take(3))
                            _Pill(label: t, color: _tagColor(t)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Controls — toggle + overflow menu
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: item.isAvailable,
                  onChanged: (_) => _toggle(context),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                  inactiveThumbColor: AppColors.error,
                  inactiveTrackColor: AppColors.error.withValues(alpha: 0.2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                _OverflowMenu(
                  isAvailable: item.isAvailable,
                  onSelected: (a) => _handleAction(context, a),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _tagColor(String tag) {
  switch (tag) {
    case 'Featured':
    case "Chef's Special":
      return AppColors.accent;
    case 'Best Seller':
    case 'Top Rated':
      return AppColors.star;
    case 'New':
      return AppColors.info;
    case 'Spicy':
      return AppColors.error;
    case 'Vegetarian':
    case 'Vegan':
    case 'Healthy':
      return AppColors.accent;
    default:
      return AppColors.primary;
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.isAvailable, required this.onSelected});
  final bool isAvailable;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final sub = Theme.of(context).colorScheme.outline;
    return PopupMenuButton<String>(
      tooltip: 'Item actions',
      icon: Icon(Icons.more_vert_rounded, size: 20, color: sub),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      onSelected: onSelected,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: _MenuRow(icon: Icons.copy_all_outlined, label: 'Duplicate'),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: _MenuRow(
            icon: isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            label: isAvailable ? 'Hide' : 'Show',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(icon: Icons.delete_outline_rounded, label: 'Delete', danger: true),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}
