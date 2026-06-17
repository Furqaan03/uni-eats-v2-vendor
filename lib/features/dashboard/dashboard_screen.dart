import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/notification_sheet.dart';
import '../../widgets/staggered_fade_in.dart';
import 'widgets/kpi_card.dart';
import 'widgets/order_tile.dart';
import 'widgets/status_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scrollController = ScrollController();
  final _newOrdersKey = GlobalKey();
  final _preparingKey = GlobalKey();
  final _readyKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<VendorProvider>(
      builder: (context, vendor, _) {
        return Scaffold(
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context, theme, isDark, vendor),
                SliverPadding(
                  padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 8),
                  sliver: SliverToBoxAdapter(
                    child: StaggeredFadeIn(
                      index: 0,
                      child: StatusBanner(vendor: vendor),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.screenInsets.copyWith(top: 12, bottom: 8),
                  sliver: SliverToBoxAdapter(
                    child: StaggeredFadeIn(
                      index: 1,
                      child: _KpiRow(
                        vendor: vendor,
                        onTapNew: vendor.newOrders.isNotEmpty
                            ? () => _scrollTo(_newOrdersKey)
                            : null,
                        onTapPreparing: vendor.preparingOrders.isNotEmpty
                            ? () => _scrollTo(_preparingKey)
                            : null,
                        onTapReady: vendor.readyOrders.isNotEmpty
                            ? () => _scrollTo(_readyKey)
                            : null,
                      ),
                    ),
                  ),
                ),

                // ── New Orders section ──────────────────────────────────────
                if (vendor.newOrders.isNotEmpty)
                  SliverPadding(
                    padding: AppSpacing.screenInsets.copyWith(top: 16),
                    sliver: SliverToBoxAdapter(
                      child: StaggeredFadeIn(
                        index: 2,
                        child: _SectionHeader(
                          key: _newOrdersKey,
                          title: 'New Orders',
                          count: vendor.newOrders.length,
                          accentColor: AppColors.statusNew,
                        ),
                      ),
                    ),
                  ),
                if (vendor.newOrders.isNotEmpty)
                  SliverPadding(
                    padding: AppSpacing.screenInsets.copyWith(top: 8, bottom: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => StaggeredFadeIn(
                          index: i + 3,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: OrderTile(order: vendor.newOrders[i], vendor: vendor),
                          ),
                        ),
                        childCount: vendor.newOrders.length,
                      ),
                    ),
                  ),

                // ── Preparing section ───────────────────────────────────────
                if (vendor.preparingOrders.isNotEmpty)
                  SliverPadding(
                    padding: AppSpacing.screenInsets.copyWith(top: 16),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        key: _preparingKey,
                        title: 'Preparing',
                        count: vendor.preparingOrders.length,
                        accentColor: AppColors.statusPreparing,
                      ),
                    ),
                  ),
                if (vendor.preparingOrders.isNotEmpty)
                  SliverPadding(
                    padding: AppSpacing.screenInsets.copyWith(top: 8, bottom: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OrderTile(order: vendor.preparingOrders[i], vendor: vendor),
                        ),
                        childCount: vendor.preparingOrders.length,
                      ),
                    ),
                  ),

                // ── Ready for Pickup section ────────────────────────────────
                if (vendor.readyOrders.isNotEmpty)
                  SliverPadding(
                    padding: AppSpacing.screenInsets.copyWith(top: 16),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        key: _readyKey,
                        title: 'Ready for Pickup',
                        count: vendor.readyOrders.length,
                        accentColor: AppColors.statusReady,
                      ),
                    ),
                  ),
                if (vendor.readyOrders.isNotEmpty)
                  SliverPadding(
                    padding: AppSpacing.screenInsets.copyWith(top: 8, bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OrderTile(order: vendor.readyOrders[i], vendor: vendor),
                        ),
                        childCount: vendor.readyOrders.length,
                      ),
                    ),
                  ),

                if (vendor.activeOrders.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('All caught up!', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('No active orders right now.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    VendorProvider vendor,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.primaryDark,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.screenPadding,
      title: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'Uni Eats',
            style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
          ),
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'vendor',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _NotificationBell(count: vendor.unreadCount),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkHeroGradient : AppColors.lightHeroGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                kToolbarHeight + 4,
                AppSpacing.screenPadding,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    vendor.restaurantName,
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text(
                        vendor.restaurantLocation,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatDate(DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── KPI row: new / preparing / ready (tappable → scroll to section) ──────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.vendor,
    this.onTapNew,
    this.onTapPreparing,
    this.onTapReady,
  });

  final VendorProvider vendor;
  final VoidCallback? onTapNew;
  final VoidCallback? onTapPreparing;
  final VoidCallback? onTapReady;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            icon: Icons.fiber_new_rounded,
            label: 'New Orders',
            value: '${vendor.newOrders.length}',
            color: AppColors.statusNew,
            onTap: onTapNew,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KpiCard(
            icon: Icons.outdoor_grill_rounded,
            label: 'Preparing',
            value: '${vendor.preparingOrders.length}',
            color: AppColors.statusPreparing,
            onTap: onTapPreparing,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KpiCard(
            icon: Icons.check_circle_rounded,
            label: 'Ready',
            value: '${vendor.readyOrders.length}',
            color: AppColors.statusReady,
            onTap: onTapReady,
          ),
        ),
      ],
    );
  }
}

// ── Section header with GlobalKey support ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.accentColor,
  });

  final String title;
  final int count;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(color: accentColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── Notification bell ─────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.error,
      offset: const Offset(-2, 2),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        onPressed: () => showNotificationSheet(context),
      ),
    );
  }
}
