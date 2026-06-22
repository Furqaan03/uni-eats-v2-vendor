import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/order.dart';

// Set to true after Firebase setup. See PLAN.md.
const kUseFirebase = true;

/// Vendor ID for this restaurant instance.
/// Change this to match whichever restaurant this device represents.
/// Must match the restaurant ID in the User app's mock_data_service.dart.
///   r001 = Tim Hortons      r002 = Oakberry
///   r003 = Edge Cafe        r004 = Caribou Coffee
///   r005 = JamKai           r006 = Bold Café
///   r007 = L'Hardy          r008 = Ennabi 92
const kVendorId = 'r001';

/// Restaurant metadata keyed by vendor ID — mirrors the User app's restaurant list.
const _kRestaurantInfo = <String, (String name, String location)>{
  'r001': ('Tim Hortons', 'Building B3'),
  'r002': ('Oakberry', 'Building B3'),
  'r003': ('Edge Cafe', 'Building B9'),
  'r004': ('Caribou Coffee', 'Building E4'),
  'r005': ('JamKai', 'Building B20'),
  'r006': ('Bold Café', 'Atrium 5'),
  'r007': ("L'Hardy", 'Building B12'),
  'r008': ('Ennabi 92', 'Building B4'),
};

String get kVendorName =>
    _kRestaurantInfo[kVendorId]?.$1 ?? 'Vendor';
String get kVendorLocation =>
    _kRestaurantInfo[kVendorId]?.$2 ?? 'UDST Campus';

// Mirrors the driver app's `_kMaxOrders` — how many concurrent deliveries
// one driver can realistically carry.
const _kMaxOrdersPerDriver = 3;
const _kInFlightDeliveryStatuses = {'ready', 'assigned', 'driverArrived', 'pickedUp', 'enRoute'};

class FirestoreOrderService {
  FirestoreOrderService._();
  static final FirestoreOrderService instance = FirestoreOrderService._();

  /// One-time check of real delivery capacity — used at Accept/Mark-Ready
  /// time to warn the vendor (not block them) when drivers are scarce.
  /// Filters status client-side rather than adding a second `where` clause,
  /// to avoid needing a composite index for a small, campus-scale dataset.
  Future<bool> hasDeliveryCapacity() async {
    final driversSnap = await FirebaseFirestore.instance
        .collection('drivers')
        .where('isOnline', isEqualTo: true)
        .get();
    final onlineDrivers = driversSnap.docs.length;
    if (onlineDrivers == 0) return false;

    final ordersSnap =
        await FirebaseFirestore.instance.collection('orders').where('orderType', isEqualTo: 'delivery').get();
    final inFlight = ordersSnap.docs
        .where((d) => _kInFlightDeliveryStatuses.contains(d.data()['status'] as String?))
        .length;
    return (onlineDrivers * _kMaxOrdersPerDriver) - inFlight > 0;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('orders');

  /// Real-time stream of orders for this vendor, sorted newest first.
  /// Filters and sorts client-side to avoid requiring a Firestore composite index.
  Stream<List<VendorOrder>> streamVendorOrders(String vendorId) {
    return _col
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs
              .map((d) => _fromFirestore(d.data()))
              .where((o) => o.status != OrderStatus.cancelled)
              .toList()
            ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
          return orders;
        });
  }

  /// Push a status update for an order.
  Future<void> updateOrderStatus(String orderId, String status, {String? cancelReason}) async {
    await _col.doc(orderId).update({
      'status': status,
      if (cancelReason != null) 'cancelReason': cancelReason,
    });
  }

  /// Write a single item's availability to Firestore.
  /// Document path: menuAvailability/{restaurantId}
  /// Structure: { itemId: isAvailable, ... }
  Future<void> updateItemAvailability(
      String restaurantId, String itemId, bool isAvailable) async {
    await FirebaseFirestore.instance
        .collection('menuAvailability')
        .doc(restaurantId)
        .set({itemId: isAvailable}, SetOptions(merge: true));
  }

  /// Fetch a persisted name/location override for [restaurantId], if any.
  Future<Map<String, dynamic>?> fetchRestaurantInfo(String restaurantId) async {
    final snap = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get();
    return snap.data();
  }

  /// Persist a name/location/open/busy edit for [restaurantId].
  Future<void> updateRestaurantInfo(
    String restaurantId, {
    String? name,
    String? location,
    bool? isOpen,
    bool? isBusy,
  }) async {
    await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).set({
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (isOpen != null) 'isOpen': isOpen,
      if (isBusy != null) 'isBusy': isBusy,
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> _menuItemsCol(String restaurantId) =>
      FirebaseFirestore.instance.collection('menus').doc(restaurantId).collection('items');

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
      customerPhone: '',
      items: items,
      status: status,
      placedAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedMinutes: 15,
      orderType: orderType,
      deliveryAddress: d['deliveryAddress'] as String?,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0,
      discount: discount,
      cancelReason: d['cancelReason'] as String?,
      driverAtRestaurant: d['driverAtRestaurant'] as bool? ?? false,
    );
  }

}
