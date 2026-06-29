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
}
