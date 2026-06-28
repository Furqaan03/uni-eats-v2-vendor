import 'dart:math' as math;

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
  DateTimeRange? _customRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) setState(() => _customRange = picked);
  }

  String get _windowLabel {
    final range = _customRange;
    if (range == null) return _period.windowLabel;
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    return '${fmt(range.start)} – ${fmt(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendor = context.watch<VendorProvider>();
    final range = _customRange;
    final summary = AnalyticsRepository().getSummary(
      vendor.orders,
      period: _period,
      customStart: range?.start,
      customEnd: range?.end,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              index: 0,
              child: Row(
                children: [
                  Expanded(
                    child: _PeriodSelector(
                      selected: _period,
                      onChanged: (p) => setState(() {
                        _period = p;
                        _customRange = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ByDateButton(active: _customRange != null, onTap: _pickDateRange),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 1,
              child: Row(
                children: [
                  Expanded(child: Text(_windowLabel, style: theme.textTheme.titleMedium)),
                  if (_customRange != null)
                    TextButton(
                      onPressed: () => setState(() => _customRange = null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 2,
              child: _RevenueChart(data: summary.weeklyRevenue),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 3,
              child: Text('Order Outcomes', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 4,
              child: _OutcomeCard(stats: summary.outcomeStats),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 5,
              child: Text('Summary', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 6,
              child: _SummaryGrid(summary: summary),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 7,
              child: Text('What People Bought', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 8,
              child: _TopItemsCard(items: summary.topItems),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 9,
              child: Text('Discounts', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 10,
              child: _DiscountCard(stats: summary.discountStats),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 11,
              child: Text('Pickup vs Delivery', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              index: 12,
              child: _OrderTypeCard(stats: summary.orderTypeStats),
            ),
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 13,
              child: _CancellationRow(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "By Date" toggle ─────────────────────────────────────────────────────────

class _ByDateButton extends StatelessWidget {
  const _ByDateButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: active
          ? AppColors.primary
          : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: active ? Colors.white : null),
              const SizedBox(width: 6),
              Text('By Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Order outcome pie chart ─────────────────────────────────────────────────

class _OutcomeCard extends StatefulWidget {
  const _OutcomeCard({required this.stats});
  final OutcomeStats stats;

  @override
  State<_OutcomeCard> createState() => _OutcomeCardState();
}

class _OutcomeCardState extends State<_OutcomeCard> {
  int? _selected;

  static const _slices = [
    (label: 'Completed', color: AppColors.primary),
    (label: 'Cancelled', color: AppColors.error),
    (label: 'Rejected', color: AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = widget.stats;
    final values = [stats.completed, stats.cancelledByCustomer, stats.rejectedByVendor];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: stats.total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text('No orders in this period yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ),
            )
          : Row(
              children: [
                GestureDetector(
                  onTapUp: (details) => setState(() {
                    final tapped = _sliceAtOffset(details.localPosition, values);
                    _selected = _selected == tapped ? null : tapped;
                  }),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        values: values,
                        colors: _slices.map((s) => s.color).toList(),
                        selectedIndex: _selected,
                        holeColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _slices.length; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: i < _slices.length - 1 ? 10 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = _selected == i ? null : i),
                            child: _OutcomeLegendRow(
                              color: _slices[i].color,
                              label: _slices[i].label,
                              count: values[i],
                              share: stats.total == 0 ? 0 : values[i] / stats.total,
                              isSelected: _selected == i,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Maps a tap inside the chart's bounding box to the slice under it, by
  /// re-deriving the same angle math the painter used to draw the wedges
  /// (starting at 12 o'clock, sweeping clockwise).
  int? _sliceAtOffset(Offset local, List<int> values) {
    const size = 120.0;
    const center = Offset(size / 2, size / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    const radius = size / 2;
    if (dx * dx + dy * dy > radius * radius) return null;

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final total = values.fold(0, (a, b) => a + b);
    if (total == 0) return null;
    var acc = 0.0;
    for (var i = 0; i < values.length; i++) {
      acc += values[i] / total * 2 * math.pi;
      if (angle <= acc) return i;
    }
    return values.length - 1;
  }
}

class _OutcomeLegendRow extends StatelessWidget {
  const _OutcomeLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.share,
    required this.isSelected,
  });
  final Color color;
  final String label;
  final int count;
  final double share;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
        ),
        Text('$count',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text('(${(share * 100).toStringAsFixed(0)}%)',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.values,
    required this.colors,
    required this.holeColor,
    this.selectedIndex,
  });
  final List<int> values;
  final List<Color> colors;
  final Color holeColor;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = values[i] / total * 2 * math.pi;
      final isSelected = selectedIndex == i;
      final r = isSelected ? radius : radius * 0.92;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }

    // Punches a visible donut hole, painted in the card's own background
    // color — a transparent paint here would leave the arcs as a solid
    // disc instead, since "transparent" just means "draw nothing."
    canvas.drawCircle(center, radius * 0.5, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.holeColor != holeColor;
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

class _RevenueChart extends StatefulWidget {
  const _RevenueChart({required this.data});
  final List<DailyRevenue> data;

  @override
  State<_RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<_RevenueChart> {
  int? _selected;

  @override
  void didUpdateWidget(_RevenueChart old) {
    super.didUpdateWidget(old);
    // Selection refers to a day index — stale once the period changes.
    if (old.data != widget.data) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.data;
    final maxAmount = data.map((d) => d.amount).fold(0.0, (a, b) => a > b ? a : b);
    final hasRevenue = maxAmount > 0;

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
          // Tapped day's exact figures — replaces a long-press-only Tooltip
          // that most users would never discover.
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.topLeft,
            child: _selected == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${data[_selected!].label}: ${formatCurrency(data[_selected!].amount)} · '
                        '${data[_selected!].orders} order${data[_selected!].orders == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          if (!hasRevenue)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text('No revenue in this period yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final day = entry.value;
                  final ratio = maxAmount > 0 ? day.amount / maxAmount : 0.0;
                  final isSelected = _selected == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = isSelected ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
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
                                      borderRadius:
                                          const BorderRadius.vertical(top: Radius.circular(6)),
                                      gradient: LinearGradient(
                                        colors: [AppColors.primaryLight, AppColors.primaryDark],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      border: isSelected
                                          ? Border.all(color: AppColors.accent, width: 2)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.w800 : null,
                                color: isSelected ? AppColors.primary : null,
                              ),
                              maxLines: 1,
                            ),
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
    final totalRevenue = items.fold<double>(0, (s, i) => s + i.revenue);

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
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showItemDetail(context, items[i], rank: i + 1, totalRevenue: totalRevenue),
              child: Row(
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
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.outline),
              ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showItemDetail(BuildContext context, TopItemStat item,
      {required int rank, required double totalRevenue}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final share = totalRevenue == 0 ? 0.0 : item.revenue / totalRevenue;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name, style: Theme.of(ctx).textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.star.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('#$rank best seller',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.star)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ItemDetailRow(label: 'Units sold', value: '${item.qty}'),
            const SizedBox(height: 8),
            _ItemDetailRow(label: 'Revenue', value: formatCurrency(item.revenue)),
            const SizedBox(height: 8),
            _ItemDetailRow(
                label: 'Share of top-sellers revenue', value: '${(share * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}

class _ItemDetailRow extends StatelessWidget {
  const _ItemDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
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
