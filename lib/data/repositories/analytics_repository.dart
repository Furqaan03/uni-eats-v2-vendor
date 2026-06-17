import '../models/analytics_data.dart';

class AnalyticsRepository {
  AnalyticsSummary getSummary() => const AnalyticsSummary(
        totalRevenue: 4820.50,
        totalOrders: 142,
        avgOrderValue: 33.95,
        avgRating: 4.7,
        topItem: 'Chicken Shawarma Wrap',
        revenueChange: 12.4,
        ordersChange: 8.2,
        weeklyRevenue: [
          DailyRevenue(label: 'Mon', amount: 620, orders: 18),
          DailyRevenue(label: 'Tue', amount: 740, orders: 22),
          DailyRevenue(label: 'Wed', amount: 810, orders: 24),
          DailyRevenue(label: 'Thu', amount: 695, orders: 20),
          DailyRevenue(label: 'Fri', amount: 920, orders: 27),
          DailyRevenue(label: 'Sat', amount: 635, orders: 19),
          DailyRevenue(label: 'Sun', amount: 400, orders: 12),
        ],
      );
}
