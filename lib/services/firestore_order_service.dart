import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/restaurants.dart';
import '../data/models/order.dart';
import '../data/models/voucher.dart';

// Set to true after Firebase setup. See PLAN.md.
const kUseFirebase = true;

/// Data environment (mirrors the admin dashboard's Live/Test switch).
///   test → unprefixed collections (all current data). Default.
///   live → `live_`-prefixed collections (real launch data), kept fully separate.
/// Flip [current] to [DataEnv.live] at real launch. Only TOP-LEVEL collection
/// names are prefixed — subcollections inherit their parent's namespace.
enum DataEnv { test, live }

class AppEnv {
  AppEnv._();
  static const DataEnv current = DataEnv.test;
  static String get _prefix => current == DataEnv.live ? 'live_' : '';
  static String col(String name) => '$_prefix$name';
}

/// Vendor ID for this restaurant instance.
/// Change this to match whichever restaurant this device represents.
/// Must match the restaurant ID in the User app's mock_data_service.dart.
///   r001 = Tim Hortons      r002 = Oakberry
///   r003 = Edge Cafe        r004 = Caribou Coffee
///   r005 = JamKai           r006 = Bold Café
///   r007 = L'Hardy          r008 = Ennabi 92
const kVendorId = 'r001';

String get kVendorName =>
    kCampusRestaurantInfo[kVendorId]?.$1 ?? 'Vendor';
String get kVendorLocation =>
    kCampusRestaurantInfo[kVendorId]?.$2 ?? 'UDST Campus';

// Mirrors the driver app's `_kMaxOrders` — how many concurrent deliveries
// one driver can realistically carry.
const _kMaxOrdersPerDriver = 3;
const _kInFlightDeliveryStatuses = {'ready', 'assigned', 'driverArrived', 'pickedUp', 'enRoute'};

// A driver only counts as genuinely online if their heartbeat (`lastActiveAt`)
// is fresher than this — mirrors the customer app's ghost-driver filter (90s,
// ~2 missed 30s beats) so we never push a new-delivery alert to a driver whose
// app died.
const _kDriverStaleAfter = Duration(seconds: 90);

class FirestoreOrderService {
  FirestoreOrderService._();
  static final FirestoreOrderService instance = FirestoreOrderService._();

  /// Live delivery-capacity signal — combines a driver-count stream
  /// with an in-flight-orders stream so the vendor dashboard can reflect
  /// capacity changes (a driver going online/offline, an order finishing)
  /// without waiting for the vendor's next Accept/Mark-Ready tap.
  Stream<bool> streamDeliveryCapacity() {
    late StreamController<bool> controller;
    int onlineDrivers = 0;
    int inFlight = 0;
    StreamSubscription? driversSub;
    StreamSubscription? ordersSub;

    controller = StreamController<bool>.broadcast(
      onListen: () {
        driversSub = FirebaseFirestore.instance
            .collection(AppEnv.col('drivers'))
            .where('isOnline', isEqualTo: true)
            .snapshots()
            .listen((snap) {
          onlineDrivers = snap.docs.length;
          controller.add((onlineDrivers * _kMaxOrdersPerDriver) - inFlight > 0);
        }, onError: (Object e) => controller.addError(e));

        ordersSub = FirebaseFirestore.instance
            .collection(AppEnv.col('orders'))
            .where('orderType', isEqualTo: 'delivery')
            .snapshots()
            .listen((snap) {
          inFlight = snap.docs
              .where((d) => _kInFlightDeliveryStatuses.contains(d.data()['status'] as String?))
              .length;
          controller.add((onlineDrivers * _kMaxOrdersPerDriver) - inFlight > 0);
        }, onError: (Object e) => controller.addError(e));
      },
      onCancel: () async {
        await driversSub?.cancel();
        await ordersSub?.cancel();
      },
    );
    return controller.stream;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(AppEnv.col('orders'));

  /// Real-time stream of orders for this vendor, sorted newest first.
  /// Sorts client-side to avoid requiring a Firestore composite index.
  /// Includes cancelled orders — VendorProvider's `activeOrders` getter is
  /// what excludes them from the live boards; the History tab needs them
  /// here to show Cancelled/Rejected at all.
  Stream<List<VendorOrder>> streamVendorOrders(String vendorId) {
    return _col
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs.map((d) => _fromFirestore(d.data())).toList()
            ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
          return orders;
        });
  }

  /// Push a status update for an order. `cancelledBy: 'vendor'` on a
  /// cancellation distinguishes "I rejected this" from "the customer
  /// cancelled it" — both share Firestore status 'cancelled', so without
  /// this tag the order-history Rejected/Cancelled split couldn't tell them
  /// apart after the fact.
  Future<void> updateOrderStatus(String orderId, String status, {String? cancelReason}) async {
    await _col.doc(orderId).update({
      'status': status,
      if (cancelReason != null) 'cancelReason': cancelReason,
      if (status == 'cancelled') 'cancelledBy': 'vendor',
    });
  }

  /// Write a single item's availability to Firestore.
  /// Document path: menuAvailability/{restaurantId}
  /// Structure: { itemId: isAvailable, ... }
  Future<void> updateItemAvailability(
      String restaurantId, String itemId, bool isAvailable) async {
    await FirebaseFirestore.instance
        .collection(AppEnv.col('menuAvailability'))
        .doc(restaurantId)
        .set({itemId: isAvailable}, SetOptions(merge: true));
  }

  /// Fetch a persisted name/location override for [restaurantId], if any.
  Future<Map<String, dynamic>?> fetchRestaurantInfo(String restaurantId) async {
    final snap = await FirebaseFirestore.instance.collection(AppEnv.col('restaurants')).doc(restaurantId).get();
    return snap.data();
  }

  /// Persist a catalog-profile edit for [restaurantId]. Only the fields
  /// passed are written (merge: true) — the rest of the doc is untouched.
  Future<void> updateRestaurantInfo(
    String restaurantId, {
    String? name,
    String? location,
    bool? isOpen,
    bool? isBusy,
    String? category,
    String? description,
    int? deliveryTimeMin,
    double? minOrder,
    bool? offersDelivery,
    bool? offersPickup,
    Map<String, dynamic>? openingHours,
  }) async {
    await FirebaseFirestore.instance.collection(AppEnv.col('restaurants')).doc(restaurantId).set({
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (isOpen != null) 'isOpen': isOpen,
      if (isBusy != null) 'isBusy': isBusy,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (deliveryTimeMin != null) 'deliveryTimeMin': deliveryTimeMin,
      if (minOrder != null) 'minOrder': minOrder,
      if (offersDelivery != null) 'offersDelivery': offersDelivery,
      if (offersPickup != null) 'offersPickup': offersPickup,
      if (openingHours != null) 'openingHours': openingHours,
    }, SetOptions(merge: true));
  }

  /// Save/refresh this restaurant's FCM token so the customer app can notify it
  /// of new orders. Uses arrayUnion so multiple devices signed into the SAME
  /// restaurant account coexist — a single `fcmToken` field meant each new
  /// device login / token rotation overwrote the previous device, so only the
  /// last writer received new-order alerts.
  Future<void> saveRestaurantFcmToken(String restaurantId, String token) async {
    if (restaurantId.isEmpty || token.isEmpty) return;
    await FirebaseFirestore.instance
        .collection(AppEnv.col('restaurants'))
        .doc(restaurantId)
        .set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Swap a rotated-away token for the new one so the restaurant's `fcmTokens`
  /// array doesn't grow unbounded as FCM rotates this device's token.
  /// (arrayUnion + arrayRemove can't touch the same field in one write.)
  Future<void> replaceRestaurantFcmToken(String restaurantId,
      {String? oldToken, required String newToken}) async {
    if (restaurantId.isEmpty || newToken.isEmpty) return;
    final doc = FirebaseFirestore.instance.collection(AppEnv.col('restaurants')).doc(restaurantId);
    if (oldToken != null && oldToken.isNotEmpty && oldToken != newToken) {
      await doc.set({'fcmTokens': FieldValue.arrayRemove([oldToken])}, SetOptions(merge: true));
    }
    await doc.set({'fcmTokens': FieldValue.arrayUnion([newToken])}, SetOptions(merge: true));
  }

  /// The customer's FCM tokens for [orderId] — read from the token set the
  /// customer app snapshots onto the ORDER doc at creation. Reading users/{uid}
  /// directly is denied for the vendor (that collection is self/admin-read
  /// only — see firestore.rules), so the order doc carries the tokens instead.
  Future<List<String>> fetchCustomerFcmTokensForOrder(String orderId) async {
    final orderSnap = await _col.doc(orderId).get();
    final embedded = orderSnap.data()?['customerFcmTokens'];
    final set = <String>{};
    if (embedded is List) {
      for (final t in embedded) {
        if (t is String && t.isNotEmpty) set.add(t);
      }
    }
    return set.toList();
  }

  /// FCM tokens of all genuinely-online drivers (isOnline + fresh heartbeat),
  /// so the vendor can alert them when a delivery order is accepted. Each
  /// driver contributes ALL their device tokens.
  Future<List<String>> fetchAvailableDriverTokens() async {
    final snap = await FirebaseFirestore.instance
        .collection(AppEnv.col('drivers'))
        .where('isOnline', isEqualTo: true)
        .get();
    final now = DateTime.now();
    final tokens = <String>{};
    for (final d in snap.docs) {
      final data = d.data();
      final ts = data['lastActiveAt'];
      if (ts is! Timestamp) continue; // no heartbeat → treat as offline/ghost
      if (now.difference(ts.toDate()) >= _kDriverStaleAfter) continue;
      tokens.addAll(_tokensOf(data));
    }
    return tokens.toList();
  }

  /// Extracts the device-token set from an entity doc — the `fcmTokens` array
  /// plus any legacy single `fcmToken`, deduped.
  static List<String> _tokensOf(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final set = <String>{};
    final arr = data['fcmTokens'];
    if (arr is List) {
      for (final t in arr) {
        if (t is String && t.isNotEmpty) set.add(t);
      }
    }
    final single = data['fcmToken'];
    if (single is String && single.isNotEmpty) set.add(single);
    return set.toList();
  }

  CollectionReference<Map<String, dynamic>> get _nameChangeRequestsCol =>
      FirebaseFirestore.instance.collection(AppEnv.col('nameChangeRequests'));

  /// Submits a name change for admin approval — restaurants/{id}.name is no
  /// longer vendor-writable directly (see firestore.rules), so this opens a
  /// request doc instead. Returns the new request's doc ID.
  Future<String> submitNameChangeRequest({
    required String restaurantId,
    required String requestedName,
    required String requestedBy,
  }) async {
    final doc = _nameChangeRequestsCol.doc();
    await doc.set({
      'restaurantId': restaurantId,
      'requestedName': requestedName,
      'requestedBy': requestedBy,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Live stream of this restaurant's name-change requests, newest first —
  /// used to show "pending approval" / "rejected" state in the profile UI.
  Stream<List<Map<String, dynamic>>> streamNameChangeRequests(String restaurantId) {
    return _nameChangeRequestsCol.where('restaurantId', isEqualTo: restaurantId).snapshots().map(
        (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList()
          ..sort((a, b) {
            final at = a['createdAt'] as Timestamp?;
            final bt = b['createdAt'] as Timestamp?;
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          }));
  }

  CollectionReference<Map<String, dynamic>> get _vouchersCol =>
      FirebaseFirestore.instance.collection(AppEnv.col('vouchers'));

  /// Live stream of this restaurant's own voucher codes — the customer
  /// checkout reads the same root `vouchers/{code}` collection, scoped by
  /// restaurantId, so an edit here is the actual edit the customer sees
  /// (no more separate in-memory list that never left this app).
  Stream<List<Voucher>> streamVouchers(String restaurantId) {
    return _vouchersCol
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Voucher.fromMap(d.id, d.data())).toList());
  }

  /// Create or overwrite a voucher. Doc ID is the code itself, uppercased to
  /// match what checkout_screen.dart looks up on the customer side.
  Future<void> upsertVoucher(Voucher voucher) async {
    await _vouchersCol.doc(voucher.code.trim().toUpperCase()).set(voucher.toMap());
  }

  Future<void> deleteVoucherDoc(String code) async {
    await _vouchersCol.doc(code.trim().toUpperCase()).delete();
  }

  CollectionReference<Map<String, dynamic>> _menuItemsCol(String restaurantId) =>
      FirebaseFirestore.instance.collection(AppEnv.col('menus')).doc(restaurantId).collection('items');

  /// One-time fetch of persisted menu items for [restaurantId].
  /// Returns an empty list if nothing has ever been written for this restaurant.
  Future<List<Map<String, dynamic>>> fetchMenuItems(String restaurantId) async {
    final snap = await _menuItemsCol(restaurantId).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Create or overwrite a single menu item document.
  Future<void> upsertMenuItem(String restaurantId, Map<String, dynamic> data) async {
    await _menuItemsCol(restaurantId).doc(data['id'] as String).set(data);
  }

  /// Remove a menu item document permanently.
  Future<void> deleteMenuItemDoc(String restaurantId, String itemId) async {
    await _menuItemsCol(restaurantId).doc(itemId).delete();
  }

  static VendorOrder _fromFirestore(Map<String, dynamic> d) {
    OrderType orderType;
    switch (d['orderType'] as String? ?? 'delivery') {
      case 'pickup':
        orderType = OrderType.pickup;
      default:
        orderType = OrderType.delivery;
    }

    OrderStatus status;
    final firestoreStatus = d['status'] as String? ?? 'placed';
    switch (firestoreStatus) {
      case 'awaitingDriver':
        status = OrderStatus.awaitingDriver;
      case 'preparing':
        status = OrderStatus.preparing;
      case 'ready':
        status = OrderStatus.ready;
      case 'pickedUp':
        // For pickup orders 'pickedUp' means the customer collected = done.
        // For delivery orders 'pickedUp' means the driver collected it from
        // the restaurant and is now en route — on the way to the customer.
        status = (orderType == OrderType.pickup || orderType == OrderType.scheduledPickup)
            ? OrderStatus.delivered
            : OrderStatus.onTheWay;
      case 'assigned':
        // Driver matched but hasn't arrived at the restaurant yet — still
        // sits with the vendor as "ready".
        status = OrderStatus.ready;
      case 'enRoute':
        status = OrderStatus.onTheWay;
      case 'arrivedAtCustomer':
        // Driver is handing off to the customer — still nothing for the
        // vendor to do, same bucket as the rest of the "out" phase.
        status = OrderStatus.onTheWay;
      case 'delivered':
        status = OrderStatus.delivered;
      case 'cancelled':
        status = OrderStatus.cancelled;
      default:
        status = OrderStatus.newOrder;
    }

    final rawItems = d['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return OrderItem(
        name: m['name'] as String? ?? '',
        qty: (m['qty'] as num?)?.toInt() ?? 1,
        price: (m['price'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    final itemsSubtotal = items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final rawDiscount = (d['discount'] as num?)?.toDouble() ?? 0;
    final discount = rawDiscount.clamp(0.0, itemsSubtotal);

    return VendorOrder(
      id: d['id'] as String,
      orderNumber: d['orderNumber'] as String? ?? '#${d['id']}',
      customerName: d['customerName'] as String? ?? 'Customer',
      customerPhone: d['customerPhone'] as String? ?? '',
      items: items,
      status: status,
      placedAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedMinutes: 15,
      orderType: orderType,
      deliveryAddress: d['deliveryAddress'] as String?,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0,
      discount: discount,
      cancelReason: d['cancelReason'] as String?,
      cancelledBy: d['cancelledBy'] as String?,
      driverAtRestaurant: d['driverAtRestaurant'] as bool? ?? false,
      driverCancelReason: d['driverCancelReason'] as String?,
      noDriversAvailable: d['noDriversAvailable'] as bool? ?? false,
      customerUnreachable: d['customerUnreachable'] as bool? ?? false,
      customerUnreachableAt: (d['customerUnreachableAt'] as Timestamp?)?.toDate(),
      driverIncident: d['driverIncident'] as bool? ?? false,
      driverIncidentReason: d['driverIncidentReason'] as String?,
      driverIncidentAt: (d['driverIncidentAt'] as Timestamp?)?.toDate(),
    );
  }

}
