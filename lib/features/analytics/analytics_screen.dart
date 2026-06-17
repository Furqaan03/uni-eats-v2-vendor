import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/analytics_data.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../widgets/staggered_fade_in.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = AnalyticsRepository().getSummary();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              index: 0,
              child: Text('This Week', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 1,
              child: _RevenueChart(data: summary.weeklyRevenue),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 2,
              child: Text('Summary', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 3,
              child: _SummaryGrid(summary: summary),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 4,
              child: _TopItemCard(itemName: summary.topItem, theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<DailyRevenue> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxAmount = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);

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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.05, 1.0),
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
                        Text(day.label, style: theme.textTheme.labelSmall),
                      ],
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
                    color: AppColors.primaryTintLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${change!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
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

class _TopItemCard extends StatelessWidget {
  const _TopItemCard({required this.itemName, required this.theme});
  final String itemName;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Selling Item',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(itemName,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
