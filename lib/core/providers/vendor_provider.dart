import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/vendor_notification.dart';
import '../../data/models/voucher.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/menu_repository.dart';
import '../../services/firestore_order_service.dart';

class VendorProvider extends ChangeNotifier {
  VendorProvider() {
    _menuItems = _menuRepo.getForRestaurant(_activeVendorId);
    _seedInitialNotifications();
    _startOverdueWatcher();
    if (kUseFirebase) {
      _subscribeToFirestore();
      _loadPersistedMenu(_activeVendorId);
      _loadPersistedRestaurantInfo(_activeVendorId);
    } else {
      _orders = _ordersRepo.getAll();
    }
  }

  final _ordersRepo = OrdersRepository();
  final _menuRepo = MenuRepository();
  Timer? _overdueTimer;
  StreamSubscription<List<VendorOrder>>? _firestoreSub;

  bool isOpen = true;
  bool isBusy = false;
  // Set by an admin via the admin dashboard — overrides the vendor's own
  // open/closed toggle and can't be reversed from this app.
  bool isAdminSuspended = false;
  // True once the open/busy status has been confirmed from Firestore (or
  // immediately if running without Firebase) — lets the dashboard avoid
  // flashing the "Open" default before the real persisted value loads.
  bool isStatusLoaded = !kUseFirebase;
  String restaurantName = kVendorName;
  String restaurantLocation = kVendorLocation;
  String _activeVendorId = kVendorId;

  /// Called after login to switch to the authenticated vendor's restaurant.
  void setRestaurant({
    required String id,
    required String name,
    required String location,
  }) {
    restaurantName = name;
    restaurantLocation = location;
    _activeVendorId = id;
    _menuItems = _menuRepo.getForRestaurant(id);
    _firestoreSub?.cancel();
    _orders = [];
    if (kUseFirebase) {
      isStatusLoaded = false;
      _subscribeToFirestore();
      _loadPersistedMenu(id);
      _loadPersistedRestaurantInfo(id);
    }
    notifyListeners();
  }

  Future<void> _loadPersistedRestaurantInfo(String restaurantId) async {
    try {
      final info = await FirestoreOrderService.instance.fetchRestaurantInfo(restaurantId);
      if (restaurantId != _activeVendorId) return;
      if (info != null) {
        if (info['name'] != null) restaurantName = info['name'] as String;
        if (info['location'] != null) restaurantLocation = info['location'] as String;
        if (info['isOpen'] != null) isOpen = info['isOpen'] as bool;
        if (info['isBusy'] != null) isBusy = info['isBusy'] as bool;
        isAdminSuspended = info['adminSuspended'] as bool? ?? false;
      }
      isStatusLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Firestore] loadPersistedRestaurantInfo failed: $e');
      isStatusLoaded = true;
      notifyListeners();
    }
  }

  /// Re-syncs the menu and restaurant info from Firestore — used by pull-to-refresh.
  Future<void> refresh() async {
    if (!kUseFirebase) return;
    await Future.wait([
      _loadPersistedMenu(_activeVendorId),
      _loadPersistedRestaurantInfo(_activeVendorId),
    ]);
  }

  /// Loads this restaurant's menu items from Firestore if any have ever been
  /// persisted; otherwise bootstraps Firestore from the local seed data so
  /// future edits have somewhere to land.
  Future<void> _loadPersistedMenu(String restaurantId) async {
    try {
      final docs = await FirestoreOrderService.instance.fetchMenuItems(restaurantId);
      if (docs.isEmpty) {
        for (final item in _menuItems) {
          await FirestoreOrderService.instance.upsertMenuItem(restaurantId, item.toMap());
        }
        return;
      }
      if (restaurantId != _activeVendorId) return; // vendor switched again mid-fetch
      _menuItems = docs.map((d) => MenuItem.fromMap(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[Firestore] loadPersistedMenu failed: $e');
    }
  }

  void _persistMenuItem(MenuItem item) {
    if (!kUseFirebase) return;
    FirestoreOrderService.instance
        .upsertMenuItem(_activeVendorId, item.toMap())
        .catchError((e) => debugPrint('[Firestore] persistMenuItem failed: $e'));
  }

  List<VendorOrder> _orders = [];
  late List<MenuItem> _menuItems;
  final List<VendorNotification> _notifications = [];
  final List<Voucher> _vouchers = [
    Voucher(id: 'v1', code: 'WELCOME10', type: VoucherType.percentage, value: 10, minOrderAmount: 0),
    Voucher(id: 'v2', code: 'SAVE5', type: VoucherType.flat, value: 5, minOrderAmount: 20),
  ];

  // ── Order getters ─────────────────────────────────────────────────────────

  List<VendorOrder> get orders => _orders;
  List<VendorOrder> get newOrders =>
      _orders.where((o) => o.status == OrderStatus.newOrder).toList();
  // Accepted, but the kitchen hasn't started — waiting on a driver to
  // commit first. No vendor action available here except cancelling.
  List<VendorOrder> get awaitingDriverOrders =>
      _orders.where((o) => o.status == OrderStatus.awaitingDriver).toList();
  List<VendorOrder> get preparingOrders =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();
  List<VendorOrder> get readyOrders =>
      _orders.where((o) => o.status == OrderStatus.ready).toList();
  // Driver has picked the order up — distinct from "ready" so the dashboard
  // can show "Out for Delivery" instead of implying it's still sitting there
  // waiting for pickup. No vendor action available, just a status tracker.
  List<VendorOrder> get outForDeliveryOrders =>
      _orders.where((o) => o.status == OrderStatus.onTheWay).toList();
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

  // ── Firestore integration ─────────────────────────────────────────────────

  void _subscribeToFirestore() {
    _firestoreSub = FirestoreOrderService.instance
        .streamVendorOrders(_activeVendorId)
        .listen((incoming) {
      final previousStatusById = {for (final o in _orders) o.id: o.status};
      final previousArrivedById = {for (final o in _orders) o.id: o.driverAtRestaurant};

      // Merge incoming orders — add new ones, push a notification for truly new orders
      final newOrders =
          incoming.where((o) => !previousStatusById.containsKey(o.id)).toList();
      for (final o in newOrders) {
        _push(
          type: NotificationType.newOrder,
          title: 'New Order Received',
          body: '${o.orderNumber} from ${o.customerName} · QAR ${o.total.toStringAsFixed(2)}',
          orderId: o.id,
        );
      }

      // Driver physically showing up at the restaurant — independent of
      // `status` (which stays preparing/ready until the kitchen actually
      // finishes), so an early arrival never jumps the dashboard bucket.
      for (final o in incoming) {
        if (!o.isDelivery) continue;
        final wasArrived = previousArrivedById[o.id] ?? false;
        if (!wasArrived && o.driverAtRestaurant) {
          _push(
            type: NotificationType.driverArrived,
            title: 'Driver Arrived',
            body: '${o.orderNumber} — the driver is at the restaurant for ${o.customerName}\'s order.',
            orderId: o.id,
          );
        }
      }

      // Driver-driven status changes — a driver accepting (which starts the
      // kitchen) and a driver's "on the way"/"delivered" progress all come
      // from the driver app, not a vendor button tap, so they're detected
      // here instead of in advanceOrder().
      for (final o in incoming) {
        if (!o.isDelivery) continue;
        final prevStatus = previousStatusById[o.id];
        if (prevStatus == null || prevStatus == o.status) continue;
        if (prevStatus == OrderStatus.awaitingDriver && o.status == OrderStatus.preparing) {
          _push(
            type: NotificationType.orderAccepted,
            title: 'Driver Found — Start Preparing!',
            body: '${o.orderNumber} for ${o.customerName} now has a driver. You can start cooking.',
            orderId: o.id,
          );
        } else if (o.status == OrderStatus.onTheWay) {
          // Fires once the driver has actually picked the order up and left
          // — "Driver Arrived" already fired separately above, earlier.
          _push(
            type: NotificationType.orderOnTheWay,
            title: 'Order Picked Up',
            body: '${o.orderNumber} — the driver picked up the order for ${o.customerName} and is out for delivery.',
            orderId: o.id,
          );
        } else if (o.status == OrderStatus.delivered) {
          _push(
            type: NotificationType.orderDelivered,
            title: 'Order Delivered',
            body:
                '${o.orderNumber} has been delivered to ${o.customerName}. +QAR ${o.total.toStringAsFixed(2)}',
            orderId: o.id,
          );
        }
      }

      _orders = incoming;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('[VendorProvider] Firestore stream error: $e');
    });
  }

  // ── Order actions ─────────────────────────────────────────────────────────

  void toggleOpen() {
    if (isAdminSuspended) return; // can't override an admin suspension here
    isOpen = !isOpen;
    _push(
      type: isOpen ? NotificationType.restaurantOpened : NotificationType.restaurantClosed,
      title: isOpen ? 'Restaurant is now Open' : 'Restaurant is now Closed',
      body: isOpen
          ? 'You are accepting new orders.'
          : 'You have stopped receiving new orders.',
    );
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, isOpen: isOpen)
          .catchError((e) => debugPrint('[Firestore] toggleOpen failed: $e'));
    }
  }

  void toggleBusy() {
    isBusy = !isBusy;
    _push(
      type: isBusy ? NotificationType.busyModeOn : NotificationType.busyModeOff,
      title: isBusy ? 'Busy Mode On' : 'Busy Mode Off',
      body: isBusy
          ? 'Customers won\'t be able to place new orders until you turn this off.'
          : 'Back to normal — customers can order again.',
    );
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, isBusy: isBusy)
          .catchError((e) => debugPrint('[Firestore] toggleBusy failed: $e'));
    }
  }

  void advanceOrder(String id) {
    final order = _orders.cast<VendorOrder?>().firstWhere((o) => o!.id == id, orElse: () => null);
    if (order == null) return;
    final next = _nextStatus(order.status, order.orderType);
    _orders = [
      for (final o in _orders)
        if (o.id == id) o.copyWith(status: next) else o,
    ];
    _pushOrderStatusNotification(order, next);
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateOrderStatus(id, _toFirestoreStatus(next, order.orderType))
          .catchError((e) => debugPrint('[Firestore] advanceOrder failed: $e'));

      // Accept (now landing on awaitingDriver for delivery orders) and
      // Mark-Ready are the moments a delivery order actually needs a driver
      // soon — warn (don't block) if capacity looks thin. Non-blocking and
      // best-effort: a failed check just skips the warning.
      if (order.isDelivery && (next == OrderStatus.awaitingDriver || next == OrderStatus.ready)) {
        FirestoreOrderService.instance.hasDeliveryCapacity().then((hasCapacity) {
          if (!hasCapacity) {
            _push(
              type: NotificationType.orderOverdue,
              title: 'Low Driver Availability',
              body: '${order.orderNumber} may sit a while — no drivers are free for delivery right now.',
              orderId: order.id,
            );
            notifyListeners();
          }
        }).catchError((e) => debugPrint('[Firestore] hasDeliveryCapacity failed: $e'));
      }
    }
  }

  void cancelOrder(String id, {required String reason}) {
    final order = _orders.cast<VendorOrder?>().firstWhere((o) => o!.id == id, orElse: () => null);
    if (order == null) return;
    _orders = [
      for (final o in _orders)
        if (o.id == id) o.copyWith(status: OrderStatus.cancelled, cancelReason: reason) else o,
    ];
    _push(
      type: NotificationType.orderCancelled,
      title: 'Order Rejected',
      body: '${order.orderNumber} from ${order.customerName} has been rejected: $reason',
      orderId: id,
    );
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateOrderStatus(id, 'cancelled', cancelReason: reason)
          .catchError((e) => debugPrint('[Firestore] cancelOrder failed: $e'));
    }
  }

  /// Maps vendor OrderStatus → Firestore status string.
  /// For pickup: the final vendor action ("delivered") means the customer
  /// picked up, so write 'pickedUp'. For delivery: write 'delivered'.
  String _toFirestoreStatus(OrderStatus s, OrderType type) => switch (s) {
        OrderStatus.newOrder => 'placed',
        OrderStatus.awaitingDriver => 'awaitingDriver',
        OrderStatus.preparing => 'preparing',
        OrderStatus.ready => 'ready',
        // Vendor never sets this directly — the driver app does — but the
        // mapping is here for completeness since OrderStatus is exhaustive.
        OrderStatus.onTheWay => 'onTheWay',
        OrderStatus.delivered =>
          (type == OrderType.pickup || type == OrderType.scheduledPickup)
              ? 'pickedUp'
              : 'delivered',
        OrderStatus.cancelled => 'cancelled',
      };

  void updateRestaurantName(String name) {
    restaurantName = name;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, name: name)
          .catchError((e) => debugPrint('[Firestore] updateRestaurantName failed: $e'));
    }
  }

  void updateRestaurantLocation(String location) {
    restaurantLocation = location;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, location: location)
          .catchError((e) => debugPrint('[Firestore] updateRestaurantLocation failed: $e'));
    }
  }

  void toggleItemAvailability(String id) {
    _menuItems = [
      for (final item in _menuItems)
        if (item.id == id) item.copyWith(isAvailable: !item.isAvailable) else item,
    ];
    notifyListeners();
    final updated = _menuItems.firstWhere((i) => i.id == id);
    _persistMenuItem(updated);
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateItemAvailability(_activeVendorId, id, updated.isAvailable)
          .catchError((e) => debugPrint('[Firestore] toggleAvailability failed: $e'));
    }
  }

  void addMenuItem(MenuItem item) {
    _menuItems = [..._menuItems, item];
    notifyListeners();
    _persistMenuItem(item);
  }

  void updateMenuItem(MenuItem updated) {
    _menuItems = [
      for (final item in _menuItems)
        if (item.id == updated.id) updated else item,
    ];
    notifyListeners();
    _persistMenuItem(updated);
  }

  void removeMenuItem(String id) {
    _menuItems = _menuItems.where((item) => item.id != id).toList();
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .deleteMenuItemDoc(_activeVendorId, id)
          .catchError((e) => debugPrint('[Firestore] deleteMenuItem failed: $e'));
    }
  }

  // ── Voucher management ────────────────────────────────────────────────────

  List<Voucher> get vouchers => List.unmodifiable(_vouchers);

  void addVoucher(Voucher v) {
    _vouchers.add(v);
    notifyListeners();
  }

  void updateVoucher(Voucher updated) {
    final idx = _vouchers.indexWhere((v) => v.id == updated.id);
    if (idx != -1) {
      _vouchers[idx] = updated;
      notifyListeners();
    }
  }

  void deleteVoucher(String id) {
    _vouchers.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  void toggleVoucher(String id) {
    final idx = _vouchers.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _vouchers[idx] = _vouchers[idx].copyWith(isActive: !_vouchers[idx].isActive);
      notifyListeners();
    }
  }

  void setItemDiscount(String itemId, double? percent) {
    _menuItems = [
      for (final item in _menuItems)
        if (item.id == itemId)
          item.copyWith(
            discountPercent: percent,
            clearDiscount: percent == null,
          )
        else
          item,
    ];
    notifyListeners();
    _persistMenuItem(_menuItems.firstWhere((i) => i.id == itemId));
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
      case OrderStatus.awaitingDriver:
        _push(
          type: NotificationType.orderAccepted,
          title: 'Order Accepted — Finding a Driver',
          body: '${order.orderNumber} from ${order.customerName} is on hold until a driver is found.',
          orderId: order.id,
        );
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
    _firestoreSub?.cancel();
    super.dispose();
  }

  // Pickup orders never need a driver, so they skip straight to preparing.
  // Delivery orders wait for a driver to commit before the kitchen starts —
  // that transition is driven by the driver app accepting, not this method.
  OrderStatus _nextStatus(OrderStatus current, OrderType type) => switch (current) {
        OrderStatus.newOrder => (type == OrderType.delivery || type == OrderType.scheduledDelivery)
            ? OrderStatus.awaitingDriver
            : OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.delivered,
        _ => current,
      };
}
