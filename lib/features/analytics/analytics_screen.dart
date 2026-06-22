import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/analytics_data.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../widgets/staggered_fade_in.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendor = context.watch<VendorProvider>();
    final summary = AnalyticsRepository().getSummary(vendor.orders, period: _period);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              index: 0,
              child: _PeriodSelector(
                selected: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 1,
              child: Text(_period.windowLabel, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 2,
              child: _RevenueChart(data: summary.weeklyRevenue),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 3,
              child: Text('Summary', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 4,
              child: _SummaryGrid(summary: summary),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 5,
              child: Text('What People Bought', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 6,
              child: _TopItemsCard(items: summary.topItems),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 7,
              child: Text('Discounts', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 8,
              child: _DiscountCard(stats: summary.discountStats),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 9,
              child: Text('Pickup vs Delivery', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 10,
              child: _OrderTypeCard(stats: summary.orderTypeStats),
            ),
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 11,
              child: _CancellationRow(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period selector ─────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: AnalyticsPeriod.values.map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Revenue chart ────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<DailyRevenue> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxAmount = data.map((d) => d.amount).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenue', style: theme.textTheme.labelLarge),
              Text(
                formatCurrency(data.fold(0.0, (s, d) => s + d.amount)),
                style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((day) {
                final ratio = maxAmount > 0 ? day.amount / maxAmount : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Tooltip(
                      message: '${formatCurrency(day.amount)} · ${day.orders} orders',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio.clamp(0.04, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    gradient: LinearGradient(
                                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(day.label, style: theme.textTheme.labelSmall, maxLines: 1),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary grid ─────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.attach_money_rounded,
          label: 'Total Revenue',
          value: formatCurrency(summary.totalRevenue),
          change: summary.revenueChange,
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.receipt_long_rounded,
          label: 'Total Orders',
          value: '${summary.totalOrders}',
          change: summary.ordersChange,
          color: AppColors.statusNew,
        ),
        _StatCard(
          icon: Icons.shopping_cart_outlined,
          label: 'Avg Order',
          value: formatCurrency(summary.avgOrderValue),
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'Rating',
          value: '${summary.avgRating} / 5.0',
          color: AppColors.star,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.change,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUp = (change ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isUp ? AppColors.primary : AppColors.error).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${change!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isUp ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Top items ────────────────────────────────────────────────────────────────

class _TopItemsCard extends StatelessWidget {
  const _TopItemsCard({required this.items});
  final List<TopItemStat> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Center(
          child: Text('No completed orders in this period yet.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        ),
      );
    }

    final maxQty = items.map((i) => i.qty).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppColors.star.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == 0 ? AppColors.star : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: maxQty == 0 ? 0 : items[i].qty / maxQty,
                          minHeight: 5,
                          backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${items[i].qty}× sold',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(formatCurrency(items[i].revenue),
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Discount breakdown ───────────────────────────────────────────────────────

class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.stats});
  final DiscountStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.totalOrders > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (stats.discountedOrders > 0)
                    Expanded(
                      flex: stats.discountedOrders,
                      child: Container(height: 10, color: AppColors.accent),
                    ),
                  if (stats.fullPriceOrders > 0)
                    Expanded(
                      flex: stats.fullPriceOrders,
                      child: Container(
                          height: 10, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DiscountStatTile(
                  dotColor: AppColors.accent,
                  label: 'With Discount',
                  orders: stats.discountedOrders,
                  revenue: stats.discountedRevenue,
                ),
              ),
              Expanded(
                child: _DiscountStatTile(
                  dotColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  label: 'Full Price',
                  orders: stats.fullPriceOrders,
                  revenue: stats.fullPriceRevenue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You gave away ${formatCurrency(stats.totalDiscountGiven)} in discounts'
                    '${stats.totalOrders > 0 ? ' (${(stats.discountedShare * 100).toStringAsFixed(0)}% of orders used one)' : ''}.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountStatTile extends StatelessWidget {
  const _DiscountStatTile({
    required this.dotColor,
    required this.label,
    required this.orders,
    required this.revenue,
  });
  final Color dotColor;
  final String label;
  final int orders;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text('$orders orders',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(formatCurrency(revenue), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
      ],
    );
  }
}

// ── Pickup vs delivery ───────────────────────────────────────────────────────

class _OrderTypeCard extends StatelessWidget {
  const _OrderTypeCard({required this.stats});
  final OrderTypeStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = stats.totalOrders;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OrderTypeTile(
              icon: Icons.storefront_outlined,
              label: 'Pickup',
              orders: stats.pickupOrders,
              revenue: stats.pickupRevenue,
              share: total == 0 ? 0 : stats.pickupOrders / total,
              color: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 50, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          Expanded(
            child: _OrderTypeTile(
              icon: Icons.delivery_dining_outlined,
              label: 'Delivery',
              orders: stats.deliveryOrders,
              revenue: stats.deliveryRevenue,
              share: total == 0 ? 0 : stats.deliveryOrders / total,
              color: AppColors.statusNew,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeTile extends StatelessWidget {
  const _OrderTypeTile({
    required this.icon,
    required this.label,
    required this.orders,
    required this.revenue,
    required this.share,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int orders;
  final double revenue;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text('$orders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(formatCurrency(revenue), style: theme.textTheme.bodySmall?.copyWith(color: color)),
        Text('${(share * 100).toStringAsFixed(0)}% of orders',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }
}

// ── Cancellation rate ────────────────────────────────────────────────────────

class _CancellationRow extends StatelessWidget {
  const _CancellationRow({required this.summary});
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHigh = summary.cancellationRate > 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Icon(
            isHigh ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: isHigh ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${summary.cancelledOrders} cancelled order${summary.cancelledOrders == 1 ? '' : 's'} '
              '(${summary.cancellationRate.toStringAsFixed(1)}% of all orders) in ${summary.period.windowLabel.toLowerCase()}.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
