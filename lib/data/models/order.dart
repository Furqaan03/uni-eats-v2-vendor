enum OrderStatus { newOrder, awaitingDriver, preparing, ready, onTheWay, delivered, cancelled }

enum OrderType { pickup, delivery, scheduledPickup, scheduledDelivery }

enum PaymentMethod { card, cash, wallet }

class OrderItem {
  const OrderItem({
    required this.name,
    required this.qty,
    required this.price,
    this.cookingInstructions,
  });

  final String name;
  final int qty;
  final double price;
  final List<String>? cookingInstructions;

  double get subtotal => qty * price;
}

class VendorOrder {
  const VendorOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.status,
    required this.placedAt,
    required this.estimatedMinutes,
    required this.orderType,
    this.scheduledFor,
    this.deliveryAddress,
    this.discount = 0,
    this.deliveryFee = 0,
    this.paymentMethod = PaymentMethod.card,
    this.specialInstructions,
    this.cancelReason,
    this.cancelledBy,
    this.driverAtRestaurant = false,
    this.driverCancelReason,
    this.noDriversAvailable = false,
    this.customerUnreachable = false,
    this.customerUnreachableAt,
    this.driverIncident = false,
    this.driverIncidentReason,
    this.driverIncidentAt,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime placedAt;
  final int estimatedMinutes;
  final OrderType orderType;
  final DateTime? scheduledFor;
  final String? deliveryAddress;
  final double discount;       // flat discount in QAR
  final double deliveryFee;    // 0 for pickup
  final PaymentMethod paymentMethod;
  final String? specialInstructions;
  final String? cancelReason;
  // 'vendor' when this restaurant rejected the order pre-acceptance,
  // 'customer' when the customer cancelled it themselves. Both share
  // Firestore status 'cancelled' — this is the only thing that tells them
  // apart for the History tab's Rejected/Cancelled split.
  final String? cancelledBy;
  bool get wasRejectedByVendor => cancelledBy == 'vendor';
  // Set the instant the driver taps "At Restaurant" — independent of
  // `status`, so an early arrival doesn't jump the kitchen's own
  // preparing/ready state forward. Used only to show a badge/notification.
  final bool driverAtRestaurant;
  // Set when a driver gives up the delivery before pickup (status reverts
  // to 'awaitingDriver') — distinguishes a real cancellation from the
  // order's normal initial wait for its first driver.
  final String? driverCancelReason;
  // True if, after a driver gave up (or every online driver declined), no
  // other driver is currently online with a free slot to take over.
  final bool noDriversAvailable;
  // Driver is at the customer's door getting no response. Read-only here —
  // the customer app owns clearing it; the vendor can only see it and call.
  final bool customerUnreachable;
  final DateTime? customerUnreachableAt;
  // Blocking problem the driver hit after pickup (accident, food damaged,
  // safety concern, customer refused, other). Order status is NOT rolled
  // back for this — it stays at its last status; only admin can resolve it.
  final bool driverIncident;
  final String? driverIncidentReason;
  final DateTime? driverIncidentAt;

  String get typeLabel => switch (orderType) {
        OrderType.pickup => 'Pickup',
        OrderType.delivery => 'Delivery',
        OrderType.scheduledPickup => 'Scheduled Pickup',
        OrderType.scheduledDelivery => 'Scheduled Delivery',
      };

  bool get isDelivery =>
      orderType == OrderType.delivery ||
      orderType == OrderType.scheduledDelivery;

  bool get isScheduled =>
      orderType == OrderType.scheduledPickup ||
      orderType == OrderType.scheduledDelivery;

  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get total => (subtotal - discount + deliveryFee).clamp(0, double.infinity);
  int get itemCount => items.fold(0, (sum, i) => sum + i.qty);

  VendorOrder copyWith({
    OrderStatus? status,
    int? estimatedMinutes,
    String? cancelReason,
    String? cancelledBy,
  }) =>
      VendorOrder(
        id: id,
        orderNumber: orderNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        status: status ?? this.status,
        placedAt: placedAt,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        orderType: orderType,
        scheduledFor: scheduledFor,
        deliveryAddress: deliveryAddress,
        discount: discount,
        deliveryFee: deliveryFee,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
        cancelReason: cancelReason ?? this.cancelReason,
        cancelledBy: cancelledBy ?? this.cancelledBy,
        driverAtRestaurant: driverAtRestaurant,
        driverCancelReason: driverCancelReason,
        noDriversAvailable: noDriversAvailable,
        customerUnreachable: customerUnreachable,
        customerUnreachableAt: customerUnreachableAt,
        driverIncident: driverIncident,
        driverIncidentReason: driverIncidentReason,
        driverIncidentAt: driverIncidentAt,
      );
}
