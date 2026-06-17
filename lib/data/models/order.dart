enum OrderStatus { newOrder, preparing, ready, delivered, cancelled }

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
    required this.rawNumber,
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
  });

  final String id;
  final int rawNumber;
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

  String get orderNumber {
    final prefix = switch (orderType) {
      OrderType.pickup => 'P',
      OrderType.delivery => 'D',
      OrderType.scheduledPickup => 'SP',
      OrderType.scheduledDelivery => 'SD',
    };
    return '#$prefix$rawNumber';
  }

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

  VendorOrder copyWith({OrderStatus? status, int? estimatedMinutes}) =>
      VendorOrder(
        id: id,
        rawNumber: rawNumber,
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
      );
}
