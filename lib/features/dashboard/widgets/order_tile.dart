import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/vendor_provider.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/models/order.dart';
import '../../orders/order_detail_screen.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.vendor});

  final VendorOrder order;
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(fadeSlidePage(OrderDetailScreen(orderId: order.id))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TileHeader(order: order, isDark: isDark),
            const Divider(height: 1, indent: 14, endIndent: 14),
            _ItemsList(order: order),
            const Divider(height: 1, indent: 14, endIndent: 14),
            _TileFooter(order: order, vendor: vendor),
          ],
        ),
      ),
    );
  }
}

// ── Header: order number · customer name | countdown timer ──────────────────

class _TileHeader extends StatelessWidget {
  const _TileHeader({required this.order, required this.isDark});
  final VendorOrder order;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final waitMinutes = DateTime.now().difference(order.placedAt).inMinutes;
    final isUrgent = waitMinutes >= 3 && order.status == OrderStatus.newOrder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${order.orderNumber} · ${order.customerName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (isUrgent)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.error),
                    ),
                  Text(
                    isUrgent
                        ? 'Waiting $waitMinutes min'
                        : 'Received ${waitMinutes < 1 ? 'just now' : '$waitMinutes min ago'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isUrgent ? AppColors.error : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _TypeBadge(order: order),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (order.status == OrderStatus.newOrder)
            _CountdownTimer(placedAt: order.placedAt),
        ],
      ),
    );
  }
}

// ── Items list ───────────────────────────────────────────────────────────────

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: order.items.map((item) => _ItemRow(item: item, isDark: isDark)).toList(),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.isDark});
  final OrderItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.qty}×',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.cookingInstructions != null && item.cookingInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.cookingInstructions!
                    .map((instruction) => _InstructionPill(text: instruction))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _InstructionPill extends StatelessWidget {
  const _InstructionPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryTintDark : AppColors.primaryTintLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Footer: total | Reject + Accept ─────────────────────────────────────────

class _TileFooter extends StatelessWidget {
  const _TileFooter({required this.order, required this.vendor});
  final VendorOrder order;
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          Text(
            'QAR ${order.total.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
            _RejectButton(onTap: () => vendor.cancelOrder(order.id)),
            const SizedBox(width: 8),
            _AcceptButton(order: order, vendor: vendor),
          ],
        ],
      ),
    );
  }
}

class _RejectButton extends StatelessWidget {
  const _RejectButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF3D1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Reject',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.order, required this.vendor});
  final VendorOrder order;
  final VendorProvider vendor;

  String get _label => switch (order.status) {
        OrderStatus.newOrder => 'Accept ✓',
        OrderStatus.preparing => 'Mark Ready',
        OrderStatus.ready => 'Delivered',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => vendor.advanceOrder(order.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          _label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Order type badge ─────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Countdown timer (3-min window for new orders) ────────────────────────────

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.placedAt});
  final DateTime placedAt;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  static const _windowSeconds = 180; // 3-minute response window
  late Timer _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_update);
    });
  }

  void _update() {
    final elapsed = DateTime.now().difference(widget.placedAt).inSeconds;
    _remainingSeconds = (_windowSeconds - elapsed).clamp(0, _windowSeconds);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds < 60;
    final isExpired = _remainingSeconds == 0;
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    final label = '${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';

    final color = isExpired
        ? AppColors.error
        : isUrgent
            ? AppColors.error
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.alarm_rounded : Icons.timer_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Overdue' : label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
