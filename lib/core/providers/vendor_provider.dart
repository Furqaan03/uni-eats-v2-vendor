import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/vendor_notification.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/menu_repository.dart';

class VendorProvider extends ChangeNotifier {
  VendorProvider() {
    _orders = _ordersRepo.getAll();
    _menuItems = _menuRepo.getAll();
    _seedInitialNotifications();
    _startOverdueWatcher();
  }

  final _ordersRepo = OrdersRepository();
  final _menuRepo = MenuRepository();
  Timer? _overdueTimer;

  bool isOpen = true;
  bool isBusy = false;
  String restaurantName = 'Campus Bites';
  String restaurantLocation = 'UDST Main Cafeteria';

  late List<VendorOrder> _orders;
  late List<MenuItem> _menuItems;
  final List<VendorNotification> _notifications = [];

  // ── Order getters ─────────────────────────────────────────────────────────

  List<VendorOrder> get orders => _orders;
  List<VendorOrder> get newOrders =>
      _orders.where((o) => o.status == OrderStatus.newOrder).toList();
  List<VendorOrder> get preparingOrders =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();
  List<VendorOrder> get readyOrders =>
      _orders.where((o) => o.status == OrderStatus.ready).toList();
  List<VendorOrder> get activeOrders => _orders
      .where((o) =>
          o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .toList();
  List<VendorOrder> get historyOrders => _orders
      .where((o) =>
          o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
      .toList();
  double get todayRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0, (s, o) => s + o.total);
  int get todayOrderCount =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;

  List<MenuItem> get menuItems => _menuItems;

  // ── Notification getters ──────────────────────────────────────────────────

  List<VendorNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Order actions ─────────────────────────────────────────────────────────

  void toggleOpen() {
    isOpen = !isOpen;
    _push(
      type: isOpen ? NotificationType.restaurantOpened : NotificationType.restaurantClosed,
      title: isOpen ? 'Restaurant is now Open' : 'Restaurant is now Closed',
      body: isOpen
          ? 'You are accepting new orders.'
          : 'You have stopped receiving new orders.',
    );
    notifyListeners();
  }

  void toggleBusy() {
    isBusy = !isBusy;
    _push(
      type: isBusy ? NotificationType.busyModeOn : NotificationType.busyModeOff,
      title: isBusy ? 'Busy Mode On' : 'Busy Mode Off',
      body: isBusy
          ? 'Customers will see longer estimated wait times.'
          : 'Back to normal pace.',
    );
    notifyListeners();
  }

  void advanceOrder(String id) {
    final order = _orders.firstWhere((o) => o.id == id);
    final next = _nextStatus(order.status);
    _orders = [
      for (final o in _orders)
        if (o.id == id) o.copyWith(status: next) else o,
    ];
    _pushOrderStatusNotification(order, next);
    notifyListeners();
  }

  void cancelOrder(String id) {
    final order = _orders.firstWhere((o) => o.id == id);
    _orders = [
      for (final o in _orders)
        if (o.id == id) o.copyWith(status: OrderStatus.cancelled) else o,
    ];
    _push(
      type: NotificationType.orderCancelled,
      title: 'Order Rejected',
      body: '${order.orderNumber} from ${order.customerName} has been rejected.',
      orderId: id,
    );
    notifyListeners();
  }

  void updateRestaurantName(String name) {
    restaurantName = name;
    notifyListeners();
  }

  void updateRestaurantLocation(String location) {
    restaurantLocation = location;
    notifyListeners();
  }

  void toggleItemAvailability(String id) {
    _menuItems = [
      for (final item in _menuItems)
        if (item.id == id) item.copyWith(isAvailable: !item.isAvailable) else item,
    ];
    notifyListeners();
  }

  void addMenuItem(MenuItem item) {
    _menuItems = [..._menuItems, item];
    notifyListeners();
  }

  void updateMenuItem(MenuItem updated) {
    _menuItems = [
      for (final item in _menuItems)
        if (item.id == updated.id) updated else item,
    ];
    notifyListeners();
  }

  void removeMenuItem(String id) {
    _menuItems = _menuItems.where((item) => item.id != id).toList();
    notifyListeners();
  }

  // ── Notification actions ──────────────────────────────────────────────────

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _push({
    required NotificationType type,
    required String title,
    required String body,
    String? orderId,
  }) {
    _notifications.insert(
      0,
      VendorNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        orderId: orderId,
      ),
    );
    // Cap at 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
  }

  void _pushOrderStatusNotification(VendorOrder order, OrderStatus next) {
    switch (next) {
      case OrderStatus.preparing:
        _push(
          type: NotificationType.orderAccepted,
          title: 'Order Accepted',
          body: '${order.orderNumber} from ${order.customerName} is now being prepared.',
          orderId: order.id,
        );
      case OrderStatus.ready:
        _push(
          type: NotificationType.orderReady,
          title: 'Order Ready',
          body:
              '${order.orderNumber} for ${order.customerName} is ready for ${order.orderType == OrderType.delivery ? 'delivery' : 'pickup'}.',
          orderId: order.id,
        );
      case OrderStatus.delivered:
        _push(
          type: NotificationType.orderDelivered,
          title: 'Order Completed',
          body:
              '${order.orderNumber} delivered to ${order.customerName}. +QAR ${order.total.toStringAsFixed(2)}',
          orderId: order.id,
        );
      default:
        break;
    }
  }

  // Seed realistic-looking startup notifications matching mock orders
  void _seedInitialNotifications() {
    final now = DateTime.now();
    final seeds = [
      VendorNotification(
        id: 'seed_1',
        type: NotificationType.newOrder,
        title: 'New Order Received',
        body: '#P4821 from Sara M. · QAR 63.00',
        createdAt: now.subtract(const Duration(minutes: 1)),
        orderId: 'o1',
      ),
      VendorNotification(
        id: 'seed_2',
        type: NotificationType.newOrder,
        title: 'New Order Received',
        body: '#D4820 from Ahmed K. · QAR 40.00 · Delivery',
        createdAt: now.subtract(const Duration(minutes: 4)),
        orderId: 'o2',
      ),
      VendorNotification(
        id: 'seed_3',
        type: NotificationType.orderAccepted,
        title: 'Order Accepted',
        body: '#P4819 from Khalid H. is now being prepared.',
        createdAt: now.subtract(const Duration(minutes: 14)),
        orderId: 'o3',
        isRead: true,
      ),
      VendorNotification(
        id: 'seed_4',
        type: NotificationType.orderAccepted,
        title: 'Order Accepted',
        body: '#T4818 (Table 7) from Fatima Z. is now being prepared.',
        createdAt: now.subtract(const Duration(minutes: 18)),
        orderId: 'o4',
        isRead: true,
      ),
      VendorNotification(
        id: 'seed_5',
        type: NotificationType.orderReady,
        title: 'Order Ready',
        body: '#D4817 from Omar B. is ready for delivery.',
        createdAt: now.subtract(const Duration(minutes: 25)),
        orderId: 'o5',
        isRead: true,
      ),
    ];
    _notifications.addAll(seeds);
  }

  // Watch for new orders that haven't been accepted in 3+ minutes
  void _startOverdueWatcher() {
    _overdueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final overdue = _orders.where((o) =>
          o.status == OrderStatus.newOrder &&
          DateTime.now().difference(o.placedAt).inMinutes >= 3);

      for (final o in overdue) {
        final alreadyWarned = _notifications.any(
          (n) => n.type == NotificationType.orderOverdue && n.orderId == o.id,
        );
        if (!alreadyWarned) {
          _push(
            type: NotificationType.orderOverdue,
            title: 'Order Overdue!',
            body:
                '${o.orderNumber} from ${o.customerName} has been waiting over 3 minutes. Please respond.',
            orderId: o.id,
          );
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _overdueTimer?.cancel();
    super.dispose();
  }

  OrderStatus _nextStatus(OrderStatus current) => switch (current) {
        OrderStatus.newOrder => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.delivered,
        _ => current,
      };
}
