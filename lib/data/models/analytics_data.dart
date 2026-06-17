class DailyRevenue {
  const DailyRevenue({required this.label, required this.amount, required this.orders});
  final String label;
  final double amount;
  final int orders;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.avgRating,
    required this.topItem,
    required this.weeklyRevenue,
    required this.revenueChange,
    required this.ordersChange,
  });

  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final double avgRating;
  final String topItem;
  final List<DailyRevenue> weeklyRevenue;
  final double revenueChange;
  final double ordersChange;
}
