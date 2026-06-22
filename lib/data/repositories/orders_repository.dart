import '../models/order.dart';

class OrdersRepository {
  static final _now = DateTime.now();

  static final List<VendorOrder> _orders = [
    VendorOrder(
      id: 'o1',
      orderNumber: '#P4821',
      customerName: 'Sara M.',
      customerPhone: '+974 5511 2233',
      orderType: OrderType.pickup,
      status: OrderStatus.newOrder,
      placedAt: _now.subtract(const Duration(minutes: 1)),
      estimatedMinutes: 20,
      paymentMethod: PaymentMethod.card,
      items: const [
        OrderItem(name: 'Crispy Chicken Meal', qty: 2, price: 29.00),
        OrderItem(name: 'Large Cola', qty: 1, price: 5.00,
            cookingInstructions: ['No ice']),
      ],
    ),
    VendorOrder(
      id: 'o2',
      orderNumber: '#D4820',
      customerName: 'Ahmed K.',
      customerPhone: '+974 5522 4411',
      orderType: OrderType.delivery,
      status: OrderStatus.newOrder,
      placedAt: _now.subtract(const Duration(minutes: 4)),
      estimatedMinutes: 15,
      deliveryAddress: 'Building 12, Al Rayyan Road, Doha',
      deliveryFee: 8.00,
      discount: 5.00,
      paymentMethod: PaymentMethod.wallet,
      items: const [
        OrderItem(name: 'Shawarma Wrap', qty: 1, price: 28.00,
            cookingInstructions: ['Extra garlic sauce', 'No pickles']),
        OrderItem(name: 'Fries (Large)', qty: 1, price: 12.00),
      ],
    ),
    VendorOrder(
      id: 'o3',
      orderNumber: '#P4819',
      customerName: 'Khalid H.',
      customerPhone: '+974 5533 6655',
      orderType: OrderType.pickup,
      status: OrderStatus.preparing,
      placedAt: _now.subtract(const Duration(minutes: 14)),
      estimatedMinutes: 8,
      paymentMethod: PaymentMethod.cash,
      specialInstructions: 'Please make it extra crispy.',
      items: const [
        OrderItem(name: 'Beef Burger Combo', qty: 1, price: 35.00,
            cookingInstructions: ['No onions', 'Extra cheese']),
        OrderItem(name: 'Onion Rings', qty: 1, price: 14.00),
      ],
    ),
    VendorOrder(
      id: 'o4',
      orderNumber: '#SP4818',
      customerName: 'Fatima Z.',
      customerPhone: '+974 5544 8877',
      orderType: OrderType.scheduledPickup,
      status: OrderStatus.preparing,
      placedAt: _now.subtract(const Duration(minutes: 5)),
      estimatedMinutes: 10,
      scheduledFor: _now.add(const Duration(minutes: 30)),
      discount: 10.00,
      paymentMethod: PaymentMethod.card,
      items: const [
        OrderItem(name: 'Grilled Chicken Plate', qty: 1, price: 32.00),
        OrderItem(name: 'Mixed Salad', qty: 1, price: 16.00,
            cookingInstructions: ['No dressing']),
        OrderItem(name: 'Water Bottle', qty: 2, price: 4.00),
      ],
    ),
    VendorOrder(
      id: 'o5',
      orderNumber: '#D4817',
      customerName: 'Omar B.',
      customerPhone: '+974 5566 1122',
      orderType: OrderType.delivery,
      status: OrderStatus.ready,
      placedAt: _now.subtract(const Duration(minutes: 28)),
      estimatedMinutes: 0,
      deliveryAddress: 'Villa 45, West Bay, Doha',
      deliveryFee: 10.00,
      paymentMethod: PaymentMethod.card,
      items: const [
        OrderItem(name: 'Falafel Wrap', qty: 3, price: 18.00),
        OrderItem(name: 'Hummus Plate', qty: 1, price: 15.00),
      ],
    ),
    VendorOrder(
      id: 'o6',
      orderNumber: '#P4816',
      customerName: 'Noor A.',
      customerPhone: '+974 5577 3344',
      orderType: OrderType.pickup,
      status: OrderStatus.delivered,
      placedAt: _now.subtract(const Duration(hours: 1, minutes: 10)),
      estimatedMinutes: 0,
      paymentMethod: PaymentMethod.wallet,
      items: const [
        OrderItem(name: 'Chicken Shawarma Wrap', qty: 1, price: 28.00),
        OrderItem(name: 'Pepsi Can', qty: 1, price: 5.00),
      ],
    ),
    VendorOrder(
      id: 'o7',
      orderNumber: '#SD4815',
      customerName: 'Yusuf I.',
      customerPhone: '+974 5588 9900',
      orderType: OrderType.scheduledDelivery,
      status: OrderStatus.delivered,
      placedAt: _now.subtract(const Duration(hours: 1, minutes: 45)),
      estimatedMinutes: 0,
      scheduledFor: _now.subtract(const Duration(hours: 1, minutes: 15)),
      deliveryAddress: 'Apartment 3B, Lusail City',
      deliveryFee: 12.00,
      discount: 15.00,
      paymentMethod: PaymentMethod.card,
      items: const [
        OrderItem(name: 'Beef Burger Combo', qty: 2, price: 35.00,
            cookingInstructions: ['Well done']),
        OrderItem(name: 'Large Fries', qty: 2, price: 12.00),
        OrderItem(name: 'Milkshake', qty: 2, price: 18.00,
            cookingInstructions: ['Chocolate']),
      ],
    ),
    VendorOrder(
      id: 'o8',
      orderNumber: '#P4814',
      customerName: 'Layla S.',
      customerPhone: '+974 5599 0011',
      orderType: OrderType.pickup,
      status: OrderStatus.cancelled,
      placedAt: _now.subtract(const Duration(hours: 2, minutes: 5)),
      estimatedMinutes: 0,
      paymentMethod: PaymentMethod.card,
      items: const [
        OrderItem(name: 'Veggie Wrap', qty: 1, price: 22.00),
        OrderItem(name: 'Fresh Juice', qty: 1, price: 12.00),
      ],
    ),
  ];

  List<VendorOrder> getAll() => List.from(_orders);
  List<VendorOrder> getByStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).toList();
  VendorOrder? getById(String id) =>
      _orders.firstWhere((o) => o.id == id, orElse: () => _orders.first);
}
