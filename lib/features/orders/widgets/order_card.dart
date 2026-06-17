import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/vendor_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/models/order.dart';
import '../order_detail_screen.dart';
import 'delivery_tracker_card.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.vendor,
    this.actionLabel,
    this.actionColor,
    this.onAction,
    this.onCancel,
    this.embedTracker = false,
  });

  final VendorOrder order;
  final VendorProvider vendor;
  final String? actionLabel;
  final Color? actionColor;
  final VoidCallback? onAction;
  final VoidCallback? onCancel;
  final bool embedTracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(fadeSlidePage(OrderDetailScreen(orderId: order.id))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            // ── Compact summary ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  // Left: order number + customer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              order.orderNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            _TypeBadge(order: order),
                            if (order.isScheduled)
                              _ScheduledBadge(order: order),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              order.customerName,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.receipt_long_outlined,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right: total + time + arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'QAR ${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo(order.placedAt),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey.withValues(alpha: 0.6)),
                ],
              ),
            ),

            // ── Embedded delivery tracker (Ready tab, delivery orders) ────
            if (embedTracker && order.isDelivery) ...[
              Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.15),
                  indent: 14,
                  endIndent: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: DeliveryTrackerCard(order: order, compact: true),
              ),
            ],

            // ── Action row ────────────────────────────────────────────────
            if (actionLabel != null || onCancel != null) ...[
              Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.15),
                  indent: 14,
                  endIndent: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null) ...[
                      _ActionButton(
                        label: 'Cancel',
                        color: AppColors.error,
                        filled: false,
                        onTap: onCancel!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (actionLabel != null && onAction != null)
                      _ActionButton(
                        label: actionLabel!,
                        color: actionColor ?? AppColors.primary,
                        filled: true,
                        onTap: onAction!,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (order.orderType) {
      OrderType.pickup => ('Pickup', AppColors.info),
      OrderType.delivery => ('Delivery', AppColors.accent),
      OrderType.scheduledPickup => ('Sched. Pickup', AppColors.primary),
      OrderType.scheduledDelivery => ('Sched. Delivery', AppColors.primaryDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Scheduled time badge ──────────────────────────────────────────────────────

class _ScheduledBadge extends StatelessWidget {
  const _ScheduledBadge({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    if (order.scheduledFor == null) return const SizedBox.shrink();
    final dt = order.scheduledFor!;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text('$h:$m $period',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: filled ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
