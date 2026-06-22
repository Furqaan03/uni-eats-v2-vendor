import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../widgets/staggered_fade_in.dart';
import 'add_item_screen.dart';
import '../../core/utils/page_transitions.dart';
import '../promotions/promotions_screen.dart';
import 'widgets/menu_item_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  String _search = '';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => Navigator.of(context).push(fadeSlidePage(const AddItemScreen())),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Items'),
            Tab(text: 'Promotions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Consumer<VendorProvider>(
            builder: (context, vendor, _) {
              final categories = {
                for (final item in vendor.menuItems) item.category
              }.toList();

              final filtered = vendor.menuItems.where((item) {
                final catMatch = _selectedCategory == null || item.category == _selectedCategory;
                final searchMatch = _search.isEmpty ||
                    item.name.toLowerCase().contains(_search.toLowerCase());
                return catMatch && searchMatch;
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: AppSpacing.screenInsets.copyWith(top: 12, bottom: 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search menu...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.screenInsets.copyWith(top: 2, bottom: 2),
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        ...categories.map((c) => _CategoryChip(
                              label: c,
                              selected: _selectedCategory == c,
                              onTap: () => setState(() => _selectedCategory = c),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('No items found',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline)),
                          )
                        : ListView.separated(
                            padding: AppSpacing.screenInsets.copyWith(top: 12, bottom: 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => StaggeredFadeIn(
                              index: i,
                              child: MenuItemCard(item: filtered[i], vendor: vendor),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          const PromotionsTabView(),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  final String label;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}
