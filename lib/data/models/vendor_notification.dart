enum NotificationType {
  newOrder,
  orderAccepted,
  orderReady,
  driverArrived,
  orderOnTheWay,
  orderDelivered,
  orderCancelled,
  orderOverdue,
  restaurantOpened,
  restaurantClosed,
  busyModeOn,
  busyModeOff,
  customerUnreachable,
  driverIncident,
}

class VendorNotification {
  VendorNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? orderId;
  bool isRead;

  VendorNotification markRead() {
    isRead = true;
    return this;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'orderId': orderId,
        'isRead': isRead,
      };

  factory VendorNotification.fromJson(Map<String, dynamic> j) => VendorNotification(
        id: j['id'] as String? ?? '',
        type: NotificationType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => NotificationType.newOrder,
        ),
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        orderId: j['orderId'] as String?,
        isRead: j['isRead'] as bool? ?? false,
      );
}
