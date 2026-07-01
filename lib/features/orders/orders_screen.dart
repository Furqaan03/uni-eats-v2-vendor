import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../data/models/order.dart';
import '../../widgets/staggered_fade_in.dart';
import '../../widgets/segmented_tabs.dart';
import '../../core/utils/page_transitions.dart';
import 'order_detail_screen.dart';
import 'widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<VendorProvider>(
      builder: (context, vendor, _) {
        final preparing = vendor.preparingOrders;
        final ready = [...vendor.readyOrders, ...vendor.outForDeliveryOrders];
        final history = vendor.historyOrders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SegmentedTabs(
                controller: _tab,
                tabs: [
                  SegTab('Preparing',
                      count: preparing.length, badgeColor: AppColors.statusPreparing),
                  SegTab('Ready',
                      count: ready.length, badgeColor: AppColors.statusReady),
                  SegTab('History',
                      count: history.length, badgeColor: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _PreparingTab(orders: preparing, vendor: vendor),
              _ReadyTab(orders: ready, vendor: vendor),
              _HistoryTab(orders: history),
            ],
          ),
        );
      },
    );
  }
}

// ── Date filter: preset sheet ────────────────────────────────────────────────

/// Result of the date-filter sheet: a concrete range+label, or a request to
/// open the custom range picker, or to clear the filter.
class _DateSelection {
  final DateTimeRange? range;
  final String? label;
  final bool custom;
  final bool clear;
  const _DateSelection.range(this.range, this.label) : custom = false, clear = false;
  const _DateSelection.custom() : range = null, label = null, custom = true, clear = false;
  const _DateSelection.clear() : range = null, label = null, custom = false, clear = true;
}

class _DateFilterSheet extends StatelessWidget {
  const _DateFilterSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final sub = theme.colorScheme.outline;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange day(DateTime d) => DateTimeRange(start: d, end: d);
    final presets = <(IconData, String, _DateSelection)>[
      (Icons.today_rounded, 'Today', _DateSelection.range(day(today), 'Today')),
      (Icons.history_toggle_off_rounded, 'Yesterday',
          _DateSelection.range(day(today.subtract(const Duration(days: 1))), 'Yesterday')),
      (Icons.date_range_rounded, 'Last 7 days',
          _DateSelection.range(DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today), 'Last 7 days')),
      (Icons.calendar_month_rounded, 'This month',
          _DateSelection.range(DateTimeRange(start: DateTime(now.year, now.month, 1), end: today), 'This month')),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: sub.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('Filter by date',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ),
            for (final (icon, label, sel) in presets)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(icon, size: 20, color: AppColors.primary),
                title: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, sel),
              ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.primary),
              title: const Text('Custom range…', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sub),
              onTap: () => Navigator.pop(context, const _DateSelection.custom()),
            ),
            const Divider(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
              title: const Text('Clear date filter', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, const _DateSelection.clear()),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Date filter button / active chip ─────────────────────────────────────────

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.range,
    required this.label,
    required this.onPick,
    required this.onClear,
  });
  final DateTimeRange? range;
  final String? label;
  final VoidCallback onPick;
  final VoidCallback onClear;

  static String _label(DateTimeRange r) {
    final f = DateFormat('d MMM');
    final sameDay =
        r.start.year == r.end.year && r.start.month == r.end.month && r.start.day == r.end.day;
    return sameDay ? f.format(r.start) : '${f.format(r.start)} – ${f.format(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = range != null;
    final fg = active
        ? Colors.white
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 40,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label area — taps to open / re-open the picker.
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 0, active ? 8 : 14, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 15, color: fg),
                  const SizedBox(width: 7),
                  Text(
                    active ? (label ?? _label(range!)) : 'Filter by date',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clear — its own generous 40x40 tap target.
          if (active)
            InkResponse(
              onTap: onClear,
              radius: 22,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Preparing tab ─────────────────────────────────────────────────────────────

class _PreparingTab extends StatelessWidget {
  const _PreparingTab({required this.orders, required this.vendor});
  final List<VendorOrder> orders;
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyState(
        icon: Icons.outdoor_grill_rounded,
        message: 'Nothing cooking right now',
        sub: 'Accept new orders from the Home tab.',
      );
    }
    return ListView.separated(
      padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => StaggeredFadeIn(
        index: i,
        child: OrderCard(
          order: orders[i],
          vendor: vendor,
          actionLabel: 'Mark Ready',
          actionColor: AppColors.statusReady,
          onAction: () => vendor.advanceOrder(orders[i].id),
        ),
      ),
    );
  }
}

// ── Ready tab ─────────────────────────────────────────────────────────────────

class _ReadyTab extends StatelessWidget {
  const _ReadyTab({required this.orders, required this.vendor});
  final List<VendorOrder> orders;
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        message: 'No orders ready yet',
        sub: 'Orders will appear here once prepared.',
      );
    }
    return ListView.separated(
      padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final order = orders[i];
        // Delivery orders have no vendor-side action once Ready — the
        // driver app drives On the Way → Delivered from here. Only the
        // pickup flow still has a vendor-confirmed completion button.
        return StaggeredFadeIn(
          index: i,
          child: OrderCard(
            order: order,
            vendor: vendor,
            actionLabel: order.isDelivery ? null : 'Picked Up ✓',
            actionColor: AppColors.accent,
            onAction: order.isDelivery ? null : () => vendor.advanceOrder(order.id),
            embedTracker: order.isDelivery,
          ),
        );
      },
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

enum _HistorySubFilter { all, completed, cancelled, rejected }

extension on _HistorySubFilter {
  String get label => switch (this) {
        _HistorySubFilter.all => 'All',
        _HistorySubFilter.completed => 'Completed',
        _HistorySubFilter.cancelled => 'Cancelled',
        _HistorySubFilter.rejected => 'Rejected',
      };

  // 'Cancelled' here specifically means the customer cancelled it — a
  // vendor-initiated decline is its own 'Rejected' bucket, even though both
  // share Firestore status 'cancelled'. See VendorOrder.cancelledBy.
  bool matches(VendorOrder o) => switch (this) {
        _HistorySubFilter.all => true,
        _HistorySubFilter.completed => o.status == OrderStatus.delivered,
        _HistorySubFilter.cancelled =>
          o.status == OrderStatus.cancelled && !o.wasRejectedByVendor,
        _HistorySubFilter.rejected => o.status == OrderStatus.cancelled && o.wasRejectedByVendor,
      };
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab({required this.orders});
  final List<VendorOrder> orders;

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  _HistorySubFilter _filter = _HistorySubFilter.all;
  DateTimeRange? _dateRange;
  String? _dateLabel;

  bool _inDateRange(VendorOrder o) {
    final r = _dateRange;
    if (r == null) return true;
    final d = DateTime(o.placedAt.year, o.placedAt.month, o.placedAt.day);
    final start = DateTime(r.start.year, r.start.month, r.start.day);
    final end = DateTime(r.end.year, r.end.month, r.end.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  void _apply(DateTimeRange range, String label) =>
      setState(() {
        _dateRange = range;
        _dateLabel = label;
      });

  void _clearDate() => setState(() {
        _dateRange = null;
        _dateLabel = null;
      });

  Future<void> _openDateSheet() async {
    final selection = await showModalBottomSheet<_DateSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DateFilterSheet(),
    );
    if (selection == null || !mounted) return;
    if (selection.clear) {
      _clearDate();
    } else if (selection.custom) {
      await _pickCustom();
    } else {
      _apply(selection.range!, selection.label!);
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final earliest = widget.orders.isEmpty
        ? DateTime(now.year - 1)
        : widget.orders.map((o) => o.placedAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestDay = DateTime(earliest.year, earliest.month, earliest.day);
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    final first = earliestDay.isBefore(oneYearAgo) ? earliestDay : oneYearAgo;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDateRange: _dateRange,
      helpText: 'Pick a date range',
      saveText: 'Apply',
    );
    if (picked != null) _apply(picked, _DateFilterButton._label(picked));
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.orders.where(_filter.matches).where(_inDateRange).toList();
    final dateActive = _dateRange != null;

    return Column(
      children: [
        Padding(
          padding: AppSpacing.screenInsets.copyWith(top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HistoryFilterChips(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 10),
              _DateFilterButton(
                range: _dateRange,
                label: _dateLabel,
                onPick: _openDateSheet,
                onClear: _clearDate,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  icon: dateActive ? Icons.event_busy_rounded : Icons.history_rounded,
                  message: widget.orders.isEmpty
                      ? 'No history yet'
                      : dateActive
                          ? 'No orders for that date'
                          : 'Nothing in ${_filter.label}',
                  sub: widget.orders.isEmpty
                      ? 'Completed, cancelled, and rejected orders will appear here.'
                      : dateActive
                          ? 'Try a different date or clear the date filter.'
                          : 'Try a different filter above.',
                )
              : _buildGroupedList(filtered),
        ),
      ],
    );
  }

  Widget _buildGroupedList(List<VendorOrder> orders) {
    final grouped = <String, List<VendorOrder>>{};
    for (final o in orders) {
      final key = _dayLabel(o.placedAt);
      grouped.putIfAbsent(key, () => []).add(o);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: AppSpacing.screenInsets.copyWith(top: 12, bottom: 24),
      itemCount: sections.length,
      itemBuilder: (ctx, si) {
        final section = sections[si];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8, top: si == 0 ? 0 : 16),
              child: Text(
                section.key,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...section.value.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StaggeredFadeIn(
                    index: e.key,
                    child: _HistoryCard(order: e.value),
                  ),
                )),
          ],
        );
      },
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    // Compare *calendar* days, not elapsed 24-hour periods — an order from
    // 7pm yesterday is <24h old but is still "Yesterday". Round via hours so
    // a DST transition can't push a midnight-to-midnight span off by one.
    final daysAgo = (today.difference(that).inHours / 24).round();
    if (daysAgo == 0) return 'TODAY';
    if (daysAgo == 1) return 'YESTERDAY';
    final fmt = dt.year == now.year ? DateFormat('EEE, d MMM') : DateFormat('d MMM yyyy');
    return fmt.format(dt).toUpperCase();
  }
}

class _HistoryFilterChips extends StatelessWidget {
  const _HistoryFilterChips({required this.selected, required this.onChanged});
  final _HistorySubFilter selected;
  final ValueChanged<_HistorySubFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _HistorySubFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final filter = _HistorySubFilter.values[i];
          final isSelected = filter == selected;
          return GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                filter.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCancelled = order.status == OrderStatus.cancelled;
    // Distinct colors for the two cancellation paths — amber for "we
    // rejected it" (a restaurant decision, less alarming) vs red for "the
    // customer backed out" (a real lost sale worth the customer's eye).
    final statusColor = !isCancelled
        ? Colors.grey
        : order.wasRejectedByVendor
            ? AppColors.accent
            : AppColors.error;
    final statusLabel = !isCancelled
        ? 'Completed'
        : order.wasRejectedByVendor
            ? 'Rejected'
            : 'Cancelled';

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(fadeSlidePage(OrderDetailScreen(orderId: order.id))),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderNumber,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.customerName} · ${order.typeLabel}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.itemCount} item${order.itemCount != 1 ? 's' : ''} · QAR ${order.total.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            _timeLabel(order.placedAt),
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    ),
    );
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });
  final IconData icon;
  final String message;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.primary.withValues(alpha: 0.35)),
          const SizedBox(height: 14),
          Text(message, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            sub,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
