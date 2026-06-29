import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../widgets/reject_reason_dialog.dart';
import 'widgets/delivery_tracker_card.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final order = vendor.orders.cast<VendorOrder?>().firstWhere(
          (o) => o!.id == orderId,
          orElse: () => null,
        );
    if (order == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Cancelling makes sense before the kitchen has started — either the
    // initial decision, or stuck waiting on a driver with no food committed.
    final canCancel =
        order.status == OrderStatus.newOrder || order.status == OrderStatus.awaitingDriver;
    final canAct = (canCancel || order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready) &&
        _actionLabel(order).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber,
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w500)),
        actions: [
          if (canCancel)
            TextButton(
              onPressed: () async {
                final reason = await showRejectReasonDialog(context);
                if (reason == null) return;
                vendor.cancelOrder(orderId, reason: reason);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Cancel Order',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status header ───────────────────────────────────────────
            _StatusHeader(order: order, isDark: isDark),
            const SizedBox(height: 12),

            // ── Driver incident (S17/S18) — highest urgency, read-only ───
            if (order.driverIncident) ...[
              _DriverIncidentBanner(order: order),
              const SizedBox(height: 10),
            ],

            // ── Customer unreachable (S8/S9) — read-only ─────────────────
            if (order.customerUnreachable) ...[
              _CustomerUnreachableBanner(order: order),
              const SizedBox(height: 10),
            ],

            // ── Customer ────────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: 'Customer', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    text: order.customerName,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    text: order.customerPhone,
                    isPhone: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Order type ──────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    label: 'Order Type',
                    icon: order.isDelivery
                        ? Icons.delivery_dining_rounded
                        : Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.local_shipping_outlined,
                    text: order.typeLabel,
                  ),
                  if (order.isDelivery && order.deliveryAddress != null) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      text: order.deliveryAddress!,
                    ),
                  ],
                  if (order.isScheduled && order.scheduledFor != null) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      text: 'Scheduled for ${_formatScheduled(order.scheduledFor!)}',
                      highlight: true,
                    ),
                  ],
                  if (order.estimatedMinutes > 0) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.timer_outlined,
                      text: 'Est. ${order.estimatedMinutes} min',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Items ───────────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    label: 'Items (${order.itemCount})',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 10),
                  ...order.items.asMap().entries.map((e) {
                    final isLast = e.key == order.items.length - 1;
                    return Column(
                      children: [
                        _ItemRow(item: e.value, isDark: isDark),
                        if (!isLast)
                          Divider(
                            height: 16,
                            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Pricing breakdown ────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: 'Pricing', icon: Icons.calculate_outlined),
                  const SizedBox(height: 10),
                  _PricingRow(label: 'Subtotal', value: order.subtotal),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 6),
                    _PricingRow(
                      label: 'Discount',
                      value: -order.discount,
                      valueColor: AppColors.accent,
                      prefix: '−',
                    ),
                  ],
                  if (order.deliveryFee > 0) ...[
                    const SizedBox(height: 6),
                    _PricingRow(label: 'Delivery fee', value: order.deliveryFee),
                  ],
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'QAR ${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PaymentChip(method: order.paymentMethod),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Special instructions ─────────────────────────────────────
            if (order.specialInstructions != null &&
                order.specialInstructions!.isNotEmpty) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      label: 'Special Instructions',
                      icon: Icons.sticky_note_2_outlined,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.specialInstructions!,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Delivery tracker (ready/on-the-way delivery orders) ──────
            if ((order.status == OrderStatus.ready ||
                    order.status == OrderStatus.onTheWay) &&
                order.isDelivery) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      label: 'Driver Tracker',
                      icon: Icons.directions_bike_rounded,
                    ),
                    const SizedBox(height: 10),
                    DeliveryTrackerCard(order: order, compact: true),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Order timeline ────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: 'Timeline', icon: Icons.history_rounded),
                  const SizedBox(height: 10),
                  _Timeline(order: order),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Primary action ────────────────────────────────────────────
            if (canAct)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _actionColor(order.status),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    vendor.advanceOrder(orderId);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    _actionLabel(order),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Delivery orders have no vendor action once Ready — the driver app
  // takes it from there (On the Way → Delivered), so the button is hidden.
  String _actionLabel(VendorOrder o) => switch (o.status) {
        OrderStatus.newOrder => 'Accept Order',
        OrderStatus.preparing => 'Mark as Ready',
        OrderStatus.ready => o.isDelivery ? '' : 'Mark as Picked Up',
        _ => '',
      };

  Color _actionColor(OrderStatus s) => switch (s) {
        OrderStatus.newOrder => AppColors.accent,
        OrderStatus.preparing => AppColors.statusReady,
        _ => AppColors.accent,
      };

  String _formatScheduled(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, $h:$m $period';
  }
}

// ── Status header card ────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order, required this.isDark});
  final VendorOrder order;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(order.status), color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Placed ${timeAgo(order.placedAt)} · ${formatTime(order.placedAt)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: statusColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.newOrder => AppColors.statusNew,
        OrderStatus.awaitingDriver => AppColors.statusNew,
        OrderStatus.preparing => AppColors.statusPreparing,
        OrderStatus.ready => AppColors.statusReady,
        OrderStatus.onTheWay => AppColors.statusReady,
        OrderStatus.delivered => AppColors.statusDelivered,
        OrderStatus.cancelled => AppColors.error,
      };

  String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.newOrder => 'New Order',
        OrderStatus.awaitingDriver => 'Finding a Driver',
        OrderStatus.preparing => 'Being Prepared',
        OrderStatus.ready => 'Ready for Pickup/Delivery',
        OrderStatus.onTheWay => 'Driver On The Way',
        OrderStatus.delivered => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  IconData _statusIcon(OrderStatus s) => switch (s) {
        OrderStatus.newOrder => Icons.fiber_new_rounded,
        OrderStatus.awaitingDriver => Icons.pending_outlined,
        OrderStatus.preparing => Icons.outdoor_grill_rounded,
        OrderStatus.ready => Icons.check_circle_outline_rounded,
        OrderStatus.onTheWay => Icons.delivery_dining_rounded,
        OrderStatus.delivered => Icons.done_all_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };
}

// ── Section card wrapper ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: child,
    );
  }
}

// ── Section title row ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Driver incident banner (S17/S18) ──────────────────────────────────────────
// Read-only: the vendor can't resolve this themselves, only admin can. The
// order's status is deliberately not rolled back — food is already in
// transit — so this is purely an awareness + escalation surface.

class _DriverIncidentBanner extends StatelessWidget {
  const _DriverIncidentBanner({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Driver reported an incident',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${VendorProvider.incidentReasonLabel(order.driverIncidentReason)}. '
            'This order may not be delivered. Please contact the driver or admin.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showContactAdminSheet(context, order),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              icon: const Icon(Icons.support_agent_rounded, size: 16),
              label: const Text('Contact Admin'),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactAdminSheet(BuildContext context, VendorOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escalate to Admin'),
        content: Text(
          'Report order ${order.orderNumber} (${VendorProvider.incidentReasonLabel(order.driverIncidentReason)}) '
          'to the admin team for resolution — refund, driver suspension, or manual review.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

// ── Customer unreachable banner (S8/S9, vendor side) ──────────────────────────
// Read-only on this side — the customer app owns clearing the flag. The
// vendor's role is just to know about it and try calling the customer.

class _CustomerUnreachableBanner extends StatelessWidget {
  const _CustomerUnreachableBanner({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.door_front_door_outlined, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Driver can\'t reach the customer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Please try calling the customer directly: ${order.customerPhone}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

// ── Detail row (icon + text) ──────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    this.isPhone = false,
    this.highlight = false,
  });
  final IconData icon;
  final String text;
  final bool isPhone;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = highlight ? AppColors.primary : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textColor,
              fontWeight: highlight ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.isDark});
  final OrderItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${item.qty}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.cookingInstructions != null &&
                      item.cookingInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: item.cookingInstructions!
                          .map((inst) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.primaryTintDark
                                      : AppColors.primaryTintLight,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  inst,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'QAR ${item.subtotal.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Pricing row ───────────────────────────────────────────────────────────────

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.prefix = '',
  });
  final String label;
  final double value;
  final Color? valueColor;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          '$prefix QAR ${value.abs().toStringAsFixed(2)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── Payment chip ──────────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.method});
  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (method) {
      PaymentMethod.card => ('Paid by Card', Icons.credit_card_rounded),
      PaymentMethod.cash => ('Pay with Cash', Icons.payments_outlined),
      PaymentMethod.wallet => ('Paid by Wallet', Icons.account_balance_wallet_outlined),
    };
    final isCard = method == PaymentMethod.card || method == PaymentMethod.wallet;
    final color = isCard ? AppColors.accent : AppColors.statusPreparing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(order);
    return Column(
      children: steps.asMap().entries.map((e) {
        final step = e.value;
        final isLast = e.key == steps.length - 1;
        return _TimelineStep(
          label: step.$1,
          sub: step.$2,
          done: step.$3,
          isActive: step.$4,
          showLine: !isLast,
        );
      }).toList(),
    );
  }

  List<(String, String, bool, bool)> _buildSteps(VendorOrder o) {
    final isCancelled = o.status == OrderStatus.cancelled;
    final statusIndex = OrderStatus.values.indexOf(o.status);

    (String, String, bool, bool) step(
        String label, String sub, OrderStatus threshold) {
      final tIndex = OrderStatus.values.indexOf(threshold);
      final isDone = statusIndex > tIndex ||
          (o.status == threshold && threshold != OrderStatus.newOrder);
      final isActive = o.status == threshold;
      return (label, sub, isDone && !isCancelled, isActive && !isCancelled);
    }

    return [
      (
        'Order Placed',
        formatTime(o.placedAt),
        true,
        o.status == OrderStatus.newOrder
      ),
      if (o.isDelivery)
        step('Finding a Driver', 'Kitchen waits until one is found', OrderStatus.awaitingDriver),
      step('Accepted & Preparing', 'Kitchen confirmed', OrderStatus.preparing),
      step('Ready', o.isDelivery ? 'Awaiting pickup' : 'Awaiting customer', OrderStatus.ready),
      if (o.isDelivery) ...[
        step('Out for Delivery', 'Driver picked up, en route', OrderStatus.onTheWay),
        step('Delivered', 'Order complete', OrderStatus.delivered),
      ] else
        step('Picked Up', 'Order complete', OrderStatus.delivered),
      if (isCancelled)
        ('Cancelled', '', false, true),
    ];
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.sub,
    required this.done,
    required this.isActive,
    required this.showLine,
  });
  final String label;
  final String sub;
  final bool done;
  final bool isActive;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isActive && !done
        ? AppColors.primary
        : done
            ? AppColors.accent
            : Colors.grey.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : isActive
                          ? const Icon(Icons.circle, size: 6, color: Colors.white)
                          : null,
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.primary : null,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
