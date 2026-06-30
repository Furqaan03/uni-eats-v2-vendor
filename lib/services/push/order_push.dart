import '../firestore_order_service.dart';
import 'send_notification.dart';

/// High-level order push events fired by the vendor app. Fire-and-forget.
class OrderPush {
  OrderPush._();

  /// Alert every available driver that an accepted delivery order needs pickup
  /// (loud orders channel). Sent only for delivery orders.
  static Future<void> notifyDriversNewDelivery({
    required String orderId,
    required String orderNumber,
    required String restaurantName,
  }) async {
    final tokens = await FirestoreOrderService.instance.fetchAvailableDriverTokens();
    if (tokens.isEmpty) return;
    await SendNotification.toTokens(
      tokens: tokens,
      title: 'New delivery available 🛵',
      body: 'Order $orderNumber from $restaurantName is ready for a driver.',
      loud: true,
      data: {'orderId': orderId, 'type': 'new_delivery'},
    );
  }

  /// Push an order update to the customer (default channel) — e.g. rejected, or
  /// ready for pickup.
  static Future<void> notifyCustomer({
    required String orderId,
    required String title,
    required String body,
  }) async {
    final token = await FirestoreOrderService.instance.fetchCustomerFcmTokenForOrder(orderId);
    if (token == null) return;
    await SendNotification.toToken(
      token: token,
      title: title,
      body: body,
      data: {'orderId': orderId, 'type': 'order_status'},
    );
  }
}
