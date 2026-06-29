import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/vendor_provider.dart';
import '../core/providers/nav_provider.dart';
import '../core/utils/page_transitions.dart';
import '../data/models/vendor_notification.dart';
import '../features/orders/order_detail_screen.dart';

void showNotificationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,       // tap outside → close
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<VendorProvider>()),
        ChangeNotifierProvider.value(value: context.read<NavProvider>()),
      ],
      child: const _NotificationSheet(),
    ),
  );
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vendor = context.watch<VendorProvider>();
    final notifications = vendor.notifications;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _SheetHandle(),
              _SheetHeader(
                unread: vendor.unreadCount,
                onMarkAll: vendor.markAllRead,
                onClear: notifications.isEmpty ? null : vendor.clearAll,
              ),
              const Divider(height: 1),
              Expanded(
                child: notifications.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (ctx, i) {
                          final n = notifications[i];
                          return _NotificationTile(
                            notification: n,
                            onTap: () => _handleTap(ctx, n),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, VendorNotification n) {
    // Mark read first
    context.read<VendorProvider>().markRead(n.id);

    final orderId = n.orderId;

    switch (n.type) {
      // Order-related → close sheet + push order detail
      case NotificationType.newOrder:
      case NotificationType.orderAccepted:
      case NotificationType.orderReady:
      case NotificationType.driverArrived:
      case NotificationType.orderOnTheWay:
      case NotificationType.orderDelivered:
      case NotificationType.orderCancelled:
      case NotificationType.orderOverdue:
      case NotificationType.customerUnreachable:
      case NotificationType.driverIncident:
        Navigator.pop(context); // close sheet
        if (orderId != null) {
          Navigator.of(context).push(fadeSlidePage(OrderDetailScreen(orderId: orderId)));
        }

      // Status changes → close sheet + switch to Home tab
      case NotificationType.restaurantOpened:
      case NotificationType.restaurantClosed:
      case NotificationType.busyModeOn:
      case NotificationType.busyModeOff:
        Navigator.pop(context);
        context.read<NavProvider>().switchTo(0);
    }
  }
}

// ── Handle ────────────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.unread,
    required this.onMarkAll,
    required this.onClear,
  });

  final int unread;
  final VoidCallback onMarkAll;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 12),
      child: Row(
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Spacer(),
          if (unread > 0)
            TextButton(
              onPressed: onMarkAll,
              child: Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              onPressed: onClear,
              tooltip: 'Clear all',
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text('No notifications yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'New orders and updates will show up here.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final VendorNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = _iconFor(notification.type);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? (isDark
                ? AppColors.primaryTintDark.withValues(alpha: 0.5)
                : AppColors.primaryTintLight.withValues(alpha: 0.5))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 6, top: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _timeAgo(notification.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                      if (_isNavigable(notification.type)) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· Tap to view',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  bool _isNavigable(NotificationType type) => switch (type) {
        NotificationType.newOrder ||
        NotificationType.orderAccepted ||
        NotificationType.orderReady ||
        NotificationType.driverArrived ||
        NotificationType.orderOnTheWay ||
        NotificationType.orderDelivered ||
        NotificationType.orderCancelled ||
        NotificationType.orderOverdue ||
        NotificationType.customerUnreachable ||
        NotificationType.driverIncident =>
          true,
        _ => false,
      };

  (IconData, Color) _iconFor(NotificationType type) => switch (type) {
        NotificationType.newOrder =>
          (Icons.shopping_bag_outlined, AppColors.statusNew),
        NotificationType.orderAccepted =>
          (Icons.outdoor_grill_rounded, AppColors.statusPreparing),
        NotificationType.orderReady =>
          (Icons.check_circle_outline_rounded, AppColors.statusReady),
        NotificationType.driverArrived =>
          (Icons.moped_outlined, AppColors.statusPreparing),
        NotificationType.orderOnTheWay =>
          (Icons.delivery_dining_rounded, AppColors.statusReady),
        NotificationType.orderDelivered =>
          (Icons.done_all_rounded, Colors.grey),
        NotificationType.orderCancelled =>
          (Icons.cancel_outlined, AppColors.error),
        NotificationType.orderOverdue =>
          (Icons.alarm_rounded, AppColors.error),
        NotificationType.restaurantOpened =>
          (Icons.storefront_rounded, AppColors.accent),
        NotificationType.restaurantClosed =>
          (Icons.store_mall_directory_outlined, Colors.grey),
        NotificationType.busyModeOn =>
          (Icons.speed_rounded, AppColors.error),
        NotificationType.busyModeOff =>
          (Icons.speed_rounded, AppColors.accent),
        NotificationType.customerUnreachable =>
          (Icons.door_front_door_outlined, AppColors.error),
        NotificationType.driverIncident =>
          (Icons.warning_amber_rounded, AppColors.error),
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
