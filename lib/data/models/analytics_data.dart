enum AnalyticsPeriod { daily, weekly, monthly }

extension AnalyticsPeriodLabel on AnalyticsPeriod {
  String get label => switch (this) {
        AnalyticsPeriod.daily => 'Daily',
        AnalyticsPeriod.weekly => 'Weekly',
        AnalyticsPeriod.monthly => 'Monthly',
      };

  /// Human label for the summary window this period covers, e.g. "Today".
  String get windowLabel => switch (this) {
        AnalyticsPeriod.daily => 'Today',
        AnalyticsPeriod.weekly => 'This Week',
        AnalyticsPeriod.monthly => 'This Month',
      };
}

class DailyRevenue {
  const DailyRevenue({required this.label, required this.amount, required this.orders});
  final String label;
  final double amount;
  final int orders;
}

class TopItemStat {
  const TopItemStat({required this.name, required this.qty, required this.revenue});
  final String name;
  final int qty;
  final double revenue;
}

/// Breaks down orders into those that had a discount applied vs. full price.
class DiscountStats {
  const DiscountStats({
    required this.discountedOrders,
    required this.discountedRevenue,
    required this.totalDiscountGiven,
    required this.fullPriceOrders,
    required this.fullPriceRevenue,
  });

  final int discountedOrders;
  final double discountedRevenue; // revenue actually collected on discounted orders
  final double totalDiscountGiven; // sum of discount amounts given away
  final int fullPriceOrders;
  final double fullPriceRevenue;

  int get totalOrders => discountedOrders + fullPriceOrders;
  double get totalRevenue => discountedRevenue + fullPriceRevenue;
  double get discountedShare => totalOrders == 0 ? 0 : discountedOrders / totalOrders;
}

/// Breaks down every order in the window by how it ended — delivered,
/// cancelled by the customer, or rejected by this restaurant before
/// acceptance. Backs the order-outcome pie chart.
class OutcomeStats {
  const OutcomeStats({
    required this.completed,
    required this.cancelledByCustomer,
    required this.rejectedByVendor,
  });

  final int completed;
  final int cancelledByCustomer;
  final int rejectedByVendor;

  int get total => completed + cancelledByCustomer + rejectedByVendor;
}

/// Breaks down orders by pickup vs. delivery.
class OrderTypeStats {
  const OrderTypeStats({
    required this.pickupOrders,
    required this.pickupRevenue,
    required this.deliveryOrders,
    required this.deliveryRevenue,
  });

  final int pickupOrders;
  final double pickupRevenue;
  final int deliveryOrders;
  final double deliveryRevenue;

  int get totalOrders => pickupOrders + deliveryOrders;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.period,
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.avgRating,
    required this.topItem,
    required this.weeklyRevenue,
    required this.revenueChange,
    required this.ordersChange,
    required this.topItems,
    required this.discountStats,
    required this.orderTypeStats,
    required this.cancelledOrders,
    required this.cancellationRate,
    required this.outcomeStats,
  });

  final AnalyticsPeriod period;
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final double avgRating;
  final String topItem;
  final List<DailyRevenue> weeklyRevenue;
  final double revenueChange;
  final double ordersChange;
  final List<TopItemStat> topItems;
  final DiscountStats discountStats;
  final OrderTypeStats orderTypeStats;
  final int cancelledOrders;
  final double cancellationRate;
  final OutcomeStats outcomeStats;
}
