import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/menu_item.dart';
import '../../widgets/staggered_fade_in.dart';
import '../../widgets/segmented_tabs.dart';
import 'add_item_screen.dart';
import '../../core/utils/page_transitions.dart';
import '../promotions/promotions_screen.dart';
import 'widgets/menu_item_card.dart';

/// What the status quick-filter (driven by the summary header) is showing.
enum _StatusFilter { all, available, hidden, offers }

/// How items are ordered within each category section.
enum _Sort { custom, nameAsc, priceAsc, priceDesc }

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  String _search = '';
  _StatusFilter _status = _StatusFilter.all;
  _Sort _sort = _Sort.custom;
  bool _reordering = false;

  final _searchCtrl = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _enterReorder() {
    setState(() {
      _reordering = true;
      // Reordering a filtered/sorted subset is confusing — show the full menu
      // in its saved order so the drag result is exactly what's persisted.
      _search = '';
      _searchCtrl.clear();
      _status = _StatusFilter.all;
      _selectedCategory = null;
      _sort = _Sort.custom;
    });
  }

  void _resetFilters() {
    setState(() {
      _search = '';
      _searchCtrl.clear();
      _status = _StatusFilter.all;
      _selectedCategory = null;
    });
  }

  List<MenuItem> _sortGroup(List<MenuItem> items) {
    final list = List<MenuItem>.of(items);
    switch (_sort) {
      case _Sort.custom:
        break; // already in saved order
      case _Sort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _Sort.priceAsc:
        list.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case _Sort.priceDesc:
        list.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          if (_tabController.index == 0 && !_reordering)
            IconButton(
              tooltip: 'Add item',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => Navigator.of(context).push(fadeSlidePage(const AddItemScreen())),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SegmentedTabs(
            controller: _tabController,
            tabs: const [
              SegTab('Items', icon: Icons.restaurant_menu_rounded),
              SegTab('Promotions', icon: Icons.local_offer_rounded),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Consumer<VendorProvider>(
            builder: (context, vendor, _) => _buildItemsTab(context, vendor),
          ),
          const PromotionsTabView(),
        ],
      ),
    );
  }

  Widget _buildItemsTab(BuildContext context, VendorProvider vendor) {
    final all = vendor.menuItems;

    // First-run empty menu — a friendly call to action, not a dead end.
    if (all.isEmpty) return _EmptyMenu(onAdd: _openAdd);

    // Category order = order each category first appears in the saved menu.
    final categoryOrder = <String>[];
    for (final it in all) {
      if (!categoryOrder.contains(it.category)) categoryOrder.add(it.category);
    }

    if (_reordering) {
      return _ReorderBody(
        vendor: vendor,
        categoryOrder: categoryOrder,
        onDone: () => setState(() => _reordering = false),
      );
    }

    // ---- Filter pipeline ----
    final q = _search.trim().toLowerCase();
    final filtered = all.where((it) {
      final statusOk = switch (_status) {
        _StatusFilter.all => true,
        _StatusFilter.available => it.isAvailable,
        _StatusFilter.hidden => !it.isAvailable,
        _StatusFilter.offers => it.hasDiscount,
      };
      final catOk = _selectedCategory == null || it.category == _selectedCategory;
      final searchOk = q.isEmpty ||
          it.name.toLowerCase().contains(q) ||
          it.description.toLowerCase().contains(q) ||
          it.category.toLowerCase().contains(q) ||
          it.tags.any((t) => t.toLowerCase().contains(q));
      return statusOk && catOk && searchOk;
    }).toList();

    // Group filtered items by category, preserving category order.
    final groups = <String, List<MenuItem>>{};
    for (final it in filtered) {
      groups.putIfAbsent(it.category, () => []).add(it);
    }
    final orderedCats = categoryOrder.where(groups.containsKey).toList();

    final filtersActive = q.isNotEmpty ||
        _status != _StatusFilter.all ||
        _selectedCategory != null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _SummaryHeader(
                items: all,
                active: _status,
                onTap: (f) => setState(() =>
                    _status = (_status == f && f != _StatusFilter.all) ? _StatusFilter.all : f),
              ),
              _SearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                onClear: () => setState(() {
                  _search = '';
                  _searchCtrl.clear();
                }),
              ),
              _CategoryBar(
                items: all,
                categoryOrder: categoryOrder,
                selected: _selectedCategory,
                onSelect: (c) => setState(() => _selectedCategory = c),
              ),
              _ToolBar(
                resultCount: filtered.length,
                sort: _sort,
                onSort: (s) => setState(() => _sort = s),
                onReorder: _enterReorder,
              ),
            ],
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResults(onClear: filtersActive ? _resetFilters : null),
          )
        else
          ..._buildCategorySlivers(vendor, orderedCats, groups),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  List<Widget> _buildCategorySlivers(
    VendorProvider vendor,
    List<String> orderedCats,
    Map<String, List<MenuItem>> groups,
  ) {
    final slivers = <Widget>[];
    var runningIndex = 0;
    for (final cat in orderedCats) {
      final items = _sortGroup(groups[cat]!);
      final hiddenCount = items.where((i) => !i.isAvailable).length;
      slivers.add(SliverToBoxAdapter(
        child: _CategoryHeader(
          title: cat,
          count: items.length,
          allHidden: hiddenCount == items.length,
          onHideAll: () => vendor.setCategoryAvailability(cat, false),
          onShowAll: () => vendor.setCategoryAvailability(cat, true),
        ),
      ));
      slivers.add(SliverPadding(
        padding: AppSpacing.screenInsets.copyWith(top: 0, bottom: 4),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StaggeredFadeIn(
                index: runningIndex + i,
                child: MenuItemCard(item: items[i], vendor: vendor),
              ),
            ),
            childCount: items.length,
          ),
        ),
      ));
      runningIndex += items.length;
    }
    return slivers;
  }

  void _openAdd() =>
      Navigator.of(context).push(fadeSlidePage(const AddItemScreen()));
}

// ── Summary header ─────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.items, required this.active, required this.onTap});
  final List<MenuItem> items;
  final _StatusFilter active;
  final ValueChanged<_StatusFilter> onTap;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final available = items.where((i) => i.isAvailable).length;
    final hidden = total - available;
    final offers = items.where((i) => i.hasDiscount).length;

    return Padding(
      padding: AppSpacing.screenInsets.copyWith(top: 14, bottom: 6),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.restaurant_menu_rounded,
            label: 'Items',
            value: '$total',
            color: AppColors.primary,
            selected: active == _StatusFilter.all,
            onTap: () => onTap(_StatusFilter.all),
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Live',
            value: '$available',
            color: AppColors.accent,
            selected: active == _StatusFilter.available,
            onTap: () => onTap(_StatusFilter.available),
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.visibility_off_rounded,
            label: 'Hidden',
            value: '$hidden',
            color: AppColors.error,
            selected: active == _StatusFilter.hidden,
            onTap: () => onTap(_StatusFilter.hidden),
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.local_offer_rounded,
            label: 'Offers',
            value: '$offers',
            color: AppColors.star,
            selected: active == _StatusFilter.offers,
            onTap: () => onTap(_StatusFilter.offers),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
          decoration: BoxDecoration(
            // Soft tinted fill when selected; a clean surface otherwise — no
            // heavy outline, so the row reads as a set of cards, not boxes.
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
                  )
                : null,
            color: selected ? null : surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 7),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: selected ? color : theme.colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : theme.colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search ──────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenInsets.copyWith(top: 10, bottom: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search name, tag, or category…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}

// ── Category chips (with counts) ─────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.items,
    required this.categoryOrder,
    required this.selected,
    required this.onSelect,
  });
  final List<MenuItem> items;
  final List<String> categoryOrder;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final it in items) {
      counts[it.category] = (counts[it.category] ?? 0) + 1;
    }
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenInsets.copyWith(top: 2, bottom: 2),
        children: [
          _CategoryChip(
            label: 'All',
            count: items.length,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final c in categoryOrder)
            _CategoryChip(
              label: c,
              count: counts[c] ?? 0,
              selected: selected == c,
              onTap: () => onSelect(c),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 0 : 1.2,
          ),
        ),
        child: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}

// ── Toolbar: result count + sort + reorder ───────────────────────────────────

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.resultCount,
    required this.sort,
    required this.onSort,
    required this.onReorder,
  });
  final int resultCount;
  final _Sort sort;
  final ValueChanged<_Sort> onSort;
  final VoidCallback onReorder;

  String get _sortLabel => switch (sort) {
        _Sort.custom => 'Custom order',
        _Sort.nameAsc => 'Name (A–Z)',
        _Sort.priceAsc => 'Price (low–high)',
        _Sort.priceDesc => 'Price (high–low)',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = theme.colorScheme.outline;
    return Padding(
      padding: AppSpacing.screenInsets.copyWith(top: 4, bottom: 4),
      child: Row(
        children: [
          Text('$resultCount item${resultCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(color: sub)),
          const Spacer(),
          // Reorder
          TextButton.icon(
            onPressed: onReorder,
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: const Text('Reorder'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Sort
          PopupMenuButton<_Sort>(
            tooltip: 'Sort',
            onSelected: onSort,
            itemBuilder: (_) => [
              for (final s in _Sort.values)
                CheckedPopupMenuItem(
                  value: s,
                  checked: s == sort,
                  child: Text(switch (s) {
                    _Sort.custom => 'Custom order',
                    _Sort.nameAsc => 'Name (A–Z)',
                    _Sort.priceAsc => 'Price (low–high)',
                    _Sort.priceDesc => 'Price (high–low)',
                  }),
                ),
            ],
            child: Row(
              children: [
                Icon(Icons.sort_rounded, size: 18, color: sub),
                const SizedBox(width: 4),
                Text(_sortLabel, style: theme.textTheme.bodySmall?.copyWith(color: sub)),
                Icon(Icons.arrow_drop_down_rounded, size: 18, color: sub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category section header ──────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.title,
    required this.count,
    required this.allHidden,
    required this.onHideAll,
    required this.onShowAll,
  });
  final String title;
  final int count;
  final bool allHidden;
  final VoidCallback onHideAll;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.screenInsets.copyWith(top: 14, bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text('$count',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Category actions',
            icon: Icon(Icons.more_horiz_rounded, size: 20, color: theme.colorScheme.outline),
            padding: EdgeInsets.zero,
            onSelected: (v) => v == 'hide' ? onHideAll() : onShowAll(),
            itemBuilder: (_) => [
              if (!allHidden)
                const PopupMenuItem(value: 'hide', child: Text('Hide all')),
              const PopupMenuItem(value: 'show', child: Text('Show all')),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reorder mode ─────────────────────────────────────────────────────────────

class _ReorderBody extends StatelessWidget {
  const _ReorderBody({
    required this.vendor,
    required this.categoryOrder,
    required this.onDone,
  });
  final VendorProvider vendor;
  final List<String> categoryOrder;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groups = <String, List<MenuItem>>{};
    for (final it in vendor.menuItems) {
      groups.putIfAbsent(it.category, () => []).add(it);
    }
    final cats = categoryOrder.where(groups.containsKey).toList();

    return Column(
      children: [
        // Instruction banner + Done
        Container(
          width: double.infinity,
          color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.10),
          padding: AppSpacing.screenInsets.copyWith(top: 12, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag items to set the order customers see. Reorder within a category.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              for (final cat in cats) ...[
                Padding(
                  padding: AppSpacing.screenInsets.copyWith(top: 14, bottom: 6),
                  child: Text(cat,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  padding: AppSpacing.screenInsets.copyWith(top: 0, bottom: 0),
                  itemCount: groups[cat]!.length,
                  onReorder: (oldI, newI) => vendor.reorderCategoryItem(cat, oldI, newI),
                  itemBuilder: (ctx, i) {
                    final item = groups[cat]![i];
                    return _ReorderTile(
                      key: ValueKey(item.id),
                      item: item,
                      index: i,
                      isDark: isDark,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReorderTile extends StatelessWidget {
  const _ReorderTile({super.key, required this.item, required this.index, required this.isDark});
  final MenuItem item;
  final int index;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: item.imagePath != null
                    ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.fastfood_rounded,
                            color: AppColors.primary.withValues(alpha: 0.6), size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(formatCurrency(item.discountedPrice),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            if (!item.isAvailable)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.visibility_off_rounded, size: 16, color: AppColors.error),
              ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.drag_handle_rounded, color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty states ─────────────────────────────────────────────────────────────

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text('Your menu is empty',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Add your first dish so customers can start ordering.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first item'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 46, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No items match',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Try a different search or filter.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            if (onClear != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
