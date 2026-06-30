import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/vendor_notification.dart';
import '../../data/models/voucher.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/menu_repository.dart';
import '../../services/firestore_order_service.dart';
import '../../services/push/notification_service.dart';
import '../../services/push/order_push.dart';
import '../constants/restaurants.dart';

class VendorProvider extends ChangeNotifier {
  VendorProvider() {
    _seedInitialNotifications();
    _startOverdueWatcher();
    if (kUseFirebase) {
      // Real multi-vendor mode: there is no "this device's restaurant" yet —
      // that's only known once the real vendor's session resolves and calls
      // setRestaurant(). Subscribing here with the kVendorId placeholder
      // used to mean every vendor's app briefly streamed/showed Tim Hortons'
      // (r001) live orders and menu before login completed.
      _menuItems = const [];
    } else {
      // Offline/no-Firebase test mode: kVendorId is the intentional "which
      // restaurant does this physical test device represent" switch — keep
      // using it here, since there's no auth flow to derive it from.
      _applyDefaultsFor(_activeVendorId);
      _menuItems = _menuRepo.getForRestaurant(_activeVendorId);
      _orders = _ordersRepo.getAll();
    }
  }

  final _ordersRepo = OrdersRepository();
  final _menuRepo = MenuRepository();
  Timer? _overdueTimer;
  StreamSubscription<List<VendorOrder>>? _firestoreSub;
  StreamSubscription<List<Voucher>>? _voucherSub;
  StreamSubscription<List<Map<String, dynamic>>>? _nameChangeSub;
  StreamSubscription<bool>? _capacitySub;

  // Live delivery-capacity signal (driver count vs. in-flight orders).
  // Defaults to true (optimistic) until the first snapshot arrives, so the
  // dashboard never flashes a false "no capacity" warning on load.
  bool hasDeliveryCapacity = true;

  bool isOpen = true;
  bool isBusy = false;
  // Set by an admin via the admin dashboard — overrides the vendor's own
  // open/closed toggle and can't be reversed from this app.
  bool isAdminSuspended = false;
  // True once the open/busy status has been confirmed from Firestore (or
  // immediately if running without Firebase) — lets the dashboard avoid
  // flashing the "Open" default before the real persisted value loads.
  bool isStatusLoaded = !kUseFirebase;
  // In Firebase mode there's no real restaurant until setRestaurant() runs
  // after login — these placeholders are never shown for more than a frame
  // since every screen that reads them sits behind the splash/login flow.
  // In offline test mode, kVendorId/kVendorName ARE the real values (this
  // device's single hardcoded test restaurant), so use them directly.
  String restaurantName = kUseFirebase ? '' : kVendorName;
  String restaurantLocation = kUseFirebase ? '' : kVendorLocation;
  String _activeVendorId = kUseFirebase ? '' : kVendorId;

  // Catalog profile fields the customer app needs to render this restaurant
  // (category, delivery estimate, min order, delivery/pickup support).
  // Pre-filled from kCampusRestaurantDefaults so the settings form — and any
  // customer viewing this restaurant before the vendor has edited anything —
  // shows sensible values instead of blanks/zeros. campusX/Y aren't included
  // here: there's no map-pin-placement UI yet, so those always come straight
  // from kCampusRestaurantDefaults regardless of Firestore.
  String category = '';
  String description = '';
  int deliveryTimeMin = 10;
  double minOrder = 0;
  bool offersDelivery = true;
  bool offersPickup = true;
  // {day3Letter: {isOpen, openMinutes, closeMinutes}} — null until either
  // Firestore has loaded or the vendor has saved hours at least once.
  Map<String, dynamic>? openingHours;

  void _applyDefaultsFor(String restaurantId) {
    final d = kCampusRestaurantDefaults[restaurantId];
    category = d?.category ?? '';
    description = d?.description ?? '';
    deliveryTimeMin = d?.deliveryTimeMin ?? 10;
    minOrder = d?.minOrder ?? 0;
    offersDelivery = d?.offersDelivery ?? true;
    offersPickup = d?.offersPickup ?? true;
  }

  /// Called after login to switch to the authenticated vendor's restaurant.
  void setRestaurant({
    required String id,
    required String name,
    required String location,
  }) {
    restaurantName = name;
    restaurantLocation = location;
    _activeVendorId = id;
    _applyDefaultsFor(id);
    _menuItems = _menuRepo.getForRestaurant(id);
    _firestoreSub?.cancel();
    _voucherSub?.cancel();
    _nameChangeSub?.cancel();
    _capacitySub?.cancel();
    _orders = [];
    if (kUseFirebase) {
      isStatusLoaded = false;
      _subscribeToFirestore();
      _loadPersistedMenu(id);
      _loadPersistedRestaurantInfo(id);
      _subscribeToVouchers(id);
      _subscribeToNameChangeRequests(id);
      _subscribeToCapacity();
      _registerPushToken(id);
    }
    notifyListeners();
  }

  // Save this restaurant's FCM token (and keep it fresh on rotation) so the
  // customer app can push new-order alerts to it. Best-effort.
  bool _pushRefreshHooked = false;
  void _registerPushToken(String restaurantId) {
    NotificationService.instance.currentToken().then((token) {
      if (token != null && token.isNotEmpty) {
        FirestoreOrderService.instance
            .saveRestaurantFcmToken(restaurantId, token)
            .catchError((e) => debugPrint('[push] saveRestaurantFcmToken failed: $e'));
      }
    });
    if (_pushRefreshHooked) return;
    _pushRefreshHooked = true;
    NotificationService.instance.onTokenRefresh((token) {
      if (_activeVendorId.isNotEmpty) {
        FirestoreOrderService.instance
            .saveRestaurantFcmToken(_activeVendorId, token)
            .catchError((e) => debugPrint('[push] saveRestaurantFcmToken refresh failed: $e'));
      }
    });
  }

  /// Live delivery-capacity stream — keeps [hasDeliveryCapacity] current as
  /// drivers go online/offline or orders finish, instead of only checking at
  /// the moment the vendor taps Accept/Mark-Ready.
  void _subscribeToCapacity() {
    _capacitySub = FirestoreOrderService.instance.streamDeliveryCapacity().listen((capacity) {
      hasDeliveryCapacity = capacity;
      notifyListeners();
    }, onError: (Object e) => debugPrint('[Firestore] streamDeliveryCapacity failed: $e'));
  }

  /// Streams this restaurant's own voucher codes from Firestore — replaces
  /// the old hardcoded local list (WELCOME10/SAVE5 baked into this file)
  /// that the Promotions screen edited but never actually persisted, so
  /// vendor edits never reached the customer checkout that validates codes
  /// against the real `vouchers/{code}` collection.
  void _subscribeToVouchers(String restaurantId) {
    _voucherSub = FirestoreOrderService.instance.streamVouchers(restaurantId).listen((vouchers) {
      if (restaurantId != _activeVendorId) return;
      _vouchers = vouchers;
      notifyListeners();
    }, onError: (Object e) => debugPrint('[Firestore] streamVouchers failed: $e'));
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
        if (info['category'] != null) category = info['category'] as String;
        if (info['description'] != null) description = info['description'] as String;
        if (info['deliveryTimeMin'] != null) {
          deliveryTimeMin = (info['deliveryTimeMin'] as num).toInt();
        }
        if (info['minOrder'] != null) minOrder = (info['minOrder'] as num).toDouble();
        if (info['offersDelivery'] != null) offersDelivery = info['offersDelivery'] as bool;
        if (info['offersPickup'] != null) offersPickup = info['offersPickup'] as bool;
        if (info['openingHours'] != null) {
          openingHours = Map<String, dynamic>.from(info['openingHours'] as Map);
        }
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
  List<Voucher> _vouchers = [];

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
      final previousNoDriversById = {for (final o in _orders) o.id: o.noDriversAvailable};
      final previousUnreachableById = {for (final o in _orders) o.id: o.customerUnreachable};
      final previousIncidentById = {for (final o in _orders) o.id: o.driverIncident};

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
        } else if (o.status == OrderStatus.awaitingDriver && o.driverCancelReason != null) {
          // Driver gave up before pickup — order is back in the
          // available-orders pool. Distinct from the initial post-accept
          // 'awaitingDriver' wait, which never carries a driverCancelReason.
          _push(
            type: NotificationType.orderOverdue,
            title: 'Driver Cancelled',
            body: '${o.orderNumber} for ${o.customerName} lost its driver (${o.driverCancelReason}). '
                'Looking for a replacement.',
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

      // No driver online to take over — fires whether this came from a
      // driver abandoning mid-delivery or every online driver declining a
      // fresh order. The vendor is the one in a position to actually reach
      // the customer (call/text) about picking up themselves or cancelling,
      // so they need to know right away rather than finding out when the
      // customer eventually complains.
      for (final o in incoming) {
        if (!o.isDelivery) continue;
        final wasNoDrivers = previousNoDriversById[o.id] ?? false;
        if (!wasNoDrivers && o.noDriversAvailable) {
          _push(
            type: NotificationType.orderOverdue,
            title: 'No Drivers Available',
            body: '${o.orderNumber} for ${o.customerName} has no driver and none are free. '
                'Consider calling/texting the customer about picking up themselves.',
            orderId: o.id,
          );
        }
      }

      // S8/S9 — driver is stuck at the customer's door. The vendor has a
      // direct line to the customer, so they're best placed to call/text
      // about it — read-only here, the customer app owns clearing the flag.
      for (final o in incoming) {
        final wasUnreachable = previousUnreachableById[o.id] ?? false;
        if (!wasUnreachable && o.customerUnreachable) {
          _push(
            type: NotificationType.customerUnreachable,
            title: 'Driver can\'t reach the customer',
            body: '${o.orderNumber} — please try calling ${o.customerName} at ${o.customerPhone}.',
            orderId: o.id,
          );
        }
      }

      // S17/S18 — blocking incident after pickup. High-urgency: the order is
      // already in transit and can't be resolved from this app alone.
      for (final o in incoming) {
        final wasIncident = previousIncidentById[o.id] ?? false;
        if (!wasIncident && o.driverIncident) {
          _push(
            type: NotificationType.driverIncident,
            title: '⚠️ Driver reported an incident',
            body: '${o.orderNumber}: ${incidentReasonLabel(o.driverIncidentReason)}. '
                'This order may not be delivered — contact the driver or admin.',
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

  static String incidentReasonLabel(String? reason) => switch (reason) {
        'accident_vehicle' => 'Vehicle or accident issue',
        'food_damaged' => 'Food was damaged in transit',
        'safety_concern' => 'Safety concern reported',
        'customer_refused' => 'Customer refused delivery',
        _ => 'Other issue reported',
      };

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

      // Vendor just accepted the order (newOrder → next): confirm to the
      // customer. Delivery is now finding a driver; pickup is being prepared.
      if (order.status == OrderStatus.newOrder) {
        OrderPush.notifyCustomer(
          orderId: order.id,
          title: 'Order confirmed ✅',
          body: order.isDelivery
              ? '$kVendorName accepted your order — finding you a driver.'
              : '$kVendorName accepted your order — preparing it now.',
        ).catchError((e) => debugPrint('[push] notifyCustomer (accept) failed: $e'));
      }

      // Vendor just accepted a delivery order (→ awaitingDriver): loudly alert
      // every available driver that it's up for grabs. Fire-and-forget.
      if (order.isDelivery && next == OrderStatus.awaitingDriver) {
        OrderPush.notifyDriversNewDelivery(
          orderId: order.id,
          orderNumber: order.orderNumber,
          restaurantName: kVendorName,
        ).catchError((e) => debugPrint('[push] notifyDrivers failed: $e'));
      }

      // Pickup order marked ready → tell the customer to come collect it.
      if (!order.isDelivery && next == OrderStatus.ready) {
        OrderPush.notifyCustomer(
          orderId: order.id,
          title: 'Your order is ready 🛍️',
          body: '${order.orderNumber} is ready for pickup at $kVendorName.',
        ).catchError((e) => debugPrint('[push] notifyCustomer (ready) failed: $e'));
      }

      // Accept (now landing on awaitingDriver for delivery orders) and
      // Mark-Ready are the moments a delivery order actually needs a driver
      // soon — warn (don't block) if the live capacity signal looks thin.
      if (order.isDelivery &&
          (next == OrderStatus.awaitingDriver || next == OrderStatus.ready) &&
          !hasDeliveryCapacity) {
        _push(
          type: NotificationType.orderOverdue,
          title: 'Low Driver Availability',
          body: '${order.orderNumber} may sit a while — no drivers are free for delivery right now.',
          orderId: order.id,
        );
        notifyListeners();
      }
    }
  }

  void cancelOrder(String id, {required String reason}) {
    final order = _orders.cast<VendorOrder?>().firstWhere((o) => o!.id == id, orElse: () => null);
    if (order == null) return;
    _orders = [
      for (final o in _orders)
        if (o.id == id)
          o.copyWith(status: OrderStatus.cancelled, cancelReason: reason, cancelledBy: 'vendor')
        else
          o,
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
      // Tell the customer their order was rejected (and why).
      OrderPush.notifyCustomer(
        orderId: id,
        title: 'Order could not be accepted',
        body: '${order.orderNumber} was rejected: $reason. Any hold is refunded.',
      ).catchError((e) => debugPrint('[push] notifyCustomer (reject) failed: $e'));
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

  // The restaurant's displayed name now requires admin approval — see
  // firestore.rules, which carves `name` out of the vendor's normal write
  // access to their own restaurant doc. `restaurantName` here is left
  // untouched until the request is actually approved and the Firestore
  // listener picks up the real change; `pendingNameChangeRequest` surfaces
  // the in-flight/rejected state in the meantime.
  Map<String, dynamic>? pendingNameChangeRequest;

  Future<String?> requestNameChange(String name) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Not signed in.';
    try {
      await FirestoreOrderService.instance.submitNameChangeRequest(
        restaurantId: _activeVendorId,
        requestedName: name,
        requestedBy: uid,
      );
      return null;
    } catch (e) {
      debugPrint('[Firestore] requestNameChange failed: $e');
      return 'Could not submit your request. Please try again.';
    }
  }

  void _subscribeToNameChangeRequests(String restaurantId) {
    _nameChangeSub = FirestoreOrderService.instance.streamNameChangeRequests(restaurantId).listen((requests) {
      if (restaurantId != _activeVendorId) return;
      pendingNameChangeRequest =
          requests.cast<Map<String, dynamic>?>().firstWhere(
                (r) => r!['status'] == 'pending',
                orElse: () => requests.isNotEmpty ? requests.first : null,
              );
      notifyListeners();
    }, onError: (Object e) => debugPrint('[Firestore] streamNameChangeRequests failed: $e'));
  }

  void updateOpeningHours(Map<String, dynamic> hours) {
    openingHours = hours;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, openingHours: hours)
          .catchError((e) => debugPrint('[Firestore] updateOpeningHours failed: $e'));
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

  void updateCategory(String value) {
    category = value;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, category: value)
          .catchError((e) => debugPrint('[Firestore] updateCategory failed: $e'));
    }
  }

  void updateDescription(String value) {
    description = value;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, description: value)
          .catchError((e) => debugPrint('[Firestore] updateDescription failed: $e'));
    }
  }

  void updateDeliveryTimeMin(int value) {
    deliveryTimeMin = value;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, deliveryTimeMin: value)
          .catchError((e) => debugPrint('[Firestore] updateDeliveryTimeMin failed: $e'));
    }
  }

  void updateMinOrder(double value) {
    minOrder = value;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, minOrder: value)
          .catchError((e) => debugPrint('[Firestore] updateMinOrder failed: $e'));
    }
  }

  void setOffersDelivery(bool value) {
    offersDelivery = value;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, offersDelivery: value)
          .catchError((e) => debugPrint('[Firestore] setOffersDelivery failed: $e'));
    }
  }

  void setOffersPickup(bool value) {
    offersPickup = value;
    notifyListeners();
    if (kUseFirebase) {
      FirestoreOrderService.instance
          .updateRestaurantInfo(_activeVendorId, offersPickup: value)
          .catchError((e) => debugPrint('[Firestore] setOffersPickup failed: $e'));
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
  //
  // `_vouchers` is now driven entirely by _subscribeToVouchers' live
  // Firestore stream — these methods only write through to Firestore (doc
  // ID = code, pinned to this restaurant) and let the stream's own snapshot
  // update `_vouchers` + notify, instead of mutating local state directly
  // and risking it drifting from what's actually persisted.

  List<Voucher> get vouchers => List.unmodifiable(_vouchers);

  void addVoucher(Voucher v) {
    if (!kUseFirebase) {
      _vouchers = [..._vouchers, v];
      notifyListeners();
      return;
    }
    FirestoreOrderService.instance
        .upsertVoucher(v.copyWith()..restaurantId = _activeVendorId)
        .catchError((e) => debugPrint('[Firestore] addVoucher failed: $e'));
  }

  void updateVoucher(Voucher updated) {
    if (!kUseFirebase) {
      _vouchers = [for (final v in _vouchers) if (v.id == updated.id) updated else v];
      notifyListeners();
      return;
    }
    FirestoreOrderService.instance
        .upsertVoucher(updated.copyWith()..restaurantId = _activeVendorId)
        .catchError((e) => debugPrint('[Firestore] updateVoucher failed: $e'));
  }

  void deleteVoucher(String id) {
    if (!kUseFirebase) {
      _vouchers = _vouchers.where((v) => v.id != id).toList();
      notifyListeners();
      return;
    }
    FirestoreOrderService.instance
        .deleteVoucherDoc(id)
        .catchError((e) => debugPrint('[Firestore] deleteVoucher failed: $e'));
  }

  void toggleVoucher(String id) {
    final voucher = _vouchers.cast<Voucher?>().firstWhere((v) => v!.id == id, orElse: () => null);
    if (voucher == null) return;
    updateVoucher(voucher.copyWith(isActive: !voucher.isActive));
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
    _voucherSub?.cancel();
    _nameChangeSub?.cancel();
    _capacitySub?.cancel();
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
