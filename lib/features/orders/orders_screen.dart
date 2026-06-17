import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../data/models/order.dart';
import '../../widgets/staggered_fade_in.dart';
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
        final ready = vendor.readyOrders;
        final history = vendor.historyOrders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders'),
            bottom: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : AppColors.lightTextSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(
                  child: _TabLabel(
                    label: 'Preparing',
                    count: preparing.length,
                    color: AppColors.statusPreparing,
                  ),
                ),
                Tab(
                  child: _TabLabel(
                    label: 'Ready',
                    count: ready.length,
                    color: AppColors.statusReady,
                  ),
                ),
                Tab(
                  child: _TabLabel(
                    label: 'History',
                    count: history.length,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
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

// ── Tab label with optional badge ────────────────────────────────────────────

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
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
          onCancel: () => vendor.cancelOrder(orders[i].id),
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
        return StaggeredFadeIn(
          index: i,
          child: OrderCard(
            order: order,
            vendor: vendor,
            actionLabel: order.isDelivery ? 'Delivered ✓' : 'Picked Up ✓',
            actionColor: AppColors.accent,
            onAction: () => vendor.advanceOrder(order.id),
            embedTracker: order.isDelivery,
          ),
        );
      },
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.orders});
  final List<VendorOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        message: 'No history yet',
        sub: 'Completed and cancelled orders will appear here.',
      );
    }

    // Group by date
    final grouped = <String, List<VendorOrder>>{};
    for (final o in orders) {
      final key = _dayLabel(o.placedAt);
      grouped.putIfAbsent(key, () => []).add(o);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 24),
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
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return '${dt.day}/${dt.month}/${dt.year}';
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
    final statusColor = isCancelled ? AppColors.error : Colors.grey;
    final statusLabel = isCancelled ? 'Cancelled' : 'Completed';

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
