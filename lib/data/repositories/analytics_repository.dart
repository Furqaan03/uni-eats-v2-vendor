import '../models/analytics_data.dart';
import '../models/order.dart';

class AnalyticsRepository {
  /// Computes real analytics from the vendor's actual order history, scoped
  /// to [period] — or, if both [customStart] and [customEnd] are given, to
  /// that explicit "By Date" range instead (period is then only used for
  /// the chart series granularity and comparison-window math doesn't apply,
  /// since an arbitrary historical range has no natural "previous window").
  /// [avgRating] is passed in separately since there's no customer rating
  /// submission system yet — it's the one field this repo can't derive from
  /// order data alone.
  AnalyticsSummary getSummary(
    List<VendorOrder> orders, {
    AnalyticsPeriod period = AnalyticsPeriod.weekly,
    double avgRating = 0,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    final isCustomRange = customStart != null && customEnd != null;
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();
    final cancelled = orders.where((o) => o.status == OrderStatus.cancelled).toList();

    final (periodStart, prevWindowStart) = _windowBounds(period, now);
    final windowStart = isCustomRange ? customStart : periodStart;
    // Custom end is inclusive of the whole selected day.
    final windowEnd = isCustomRange ? customEnd.add(const Duration(days: 1)) : now;

    bool inWindow(VendorOrder o) =>
        o.placedAt.isAfter(windowStart) && o.placedAt.isBefore(windowEnd);

    final windowOrders = delivered.where(inWindow).toList();
    final prevWindowOrders = isCustomRange
        ? const <VendorOrder>[]
        : delivered
            .where((o) => o.placedAt.isAfter(prevWindowStart) && o.placedAt.isBefore(windowStart))
            .toList();
    final windowCancelled = cancelled.where(inWindow).toList();
    final windowAllOrders = orders.where(inWindow).toList();

    final totalRevenue = windowOrders.fold(0.0, (sum, o) => sum + o.total);
    final totalOrders = windowOrders.length;
    final avgOrderValue = totalOrders == 0 ? 0.0 : totalRevenue / totalOrders;

    final prevRevenue = prevWindowOrders.fold(0.0, (sum, o) => sum + o.total);
    final revenueChange = prevRevenue == 0
        ? (totalRevenue > 0 ? 100.0 : 0.0)
        : ((totalRevenue - prevRevenue) / prevRevenue) * 100;
    final ordersChange = prevWindowOrders.isEmpty
        ? (windowOrders.isNotEmpty ? 100.0 : 0.0)
        : ((totalOrders - prevWindowOrders.length) / prevWindowOrders.length) * 100;

    // Best-selling items within the window, by quantity sold.
    final itemStats = <String, (int qty, double revenue)>{};
    for (final o in windowOrders) {
      for (final item in o.items) {
        final existing = itemStats[item.name] ?? (0, 0.0);
        itemStats[item.name] = (existing.$1 + item.qty, existing.$2 + item.subtotal);
      }
    }
    final topItems = itemStats.entries
        .map((e) => TopItemStat(name: e.key, qty: e.value.$1, revenue: e.value.$2))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    final topItem = topItems.isEmpty ? '—' : topItems.first.name;

    // Discount vs full-price split within the window.
    final discountedOrders = windowOrders.where((o) => o.discount > 0).toList();
    final fullPriceOrders = windowOrders.where((o) => o.discount <= 0).toList();
    final discountStats = DiscountStats(
      discountedOrders: discountedOrders.length,
      discountedRevenue: discountedOrders.fold(0.0, (sum, o) => sum + o.total),
      totalDiscountGiven: discountedOrders.fold(0.0, (sum, o) => sum + o.discount),
      fullPriceOrders: fullPriceOrders.length,
      fullPriceRevenue: fullPriceOrders.fold(0.0, (sum, o) => sum + o.total),
    );

    // Pickup vs delivery split within the window.
    final pickup = windowOrders.where((o) => !o.isDelivery).toList();
    final delivery = windowOrders.where((o) => o.isDelivery).toList();
    final orderTypeStats = OrderTypeStats(
      pickupOrders: pickup.length,
      pickupRevenue: pickup.fold(0.0, (sum, o) => sum + o.total),
      deliveryOrders: delivery.length,
      deliveryRevenue: delivery.fold(0.0, (sum, o) => sum + o.total),
    );

    final cancellationRate =
        windowAllOrders.isEmpty ? 0.0 : windowCancelled.length / windowAllOrders.length * 100;

    // 'Rejected' = this restaurant declined before ever accepting it.
    // 'Cancelled' = the customer cancelled it themselves. Both share
    // VendorOrder.status == cancelled — cancelledBy is what tells them
    // apart (see firestore.rules / order history Rejected/Cancelled split).
    final outcomeStats = OutcomeStats(
      completed: windowOrders.length,
      cancelledByCustomer: windowCancelled.where((o) => !o.wasRejectedByVendor).length,
      rejectedByVendor: windowCancelled.where((o) => o.wasRejectedByVendor).length,
    );

    return AnalyticsSummary(
      period: period,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      avgOrderValue: avgOrderValue,
      avgRating: avgRating,
      topItem: topItem,
      revenueChange: revenueChange,
      ordersChange: ordersChange,
      weeklyRevenue: isCustomRange
          ? _buildCustomSeries(customStart, customEnd, delivered)
          : _buildSeries(period, delivered, now),
      topItems: topItems.take(5).toList(),
      discountStats: discountStats,
      orderTypeStats: orderTypeStats,
      cancelledOrders: windowCancelled.length,
      cancellationRate: cancellationRate,
      outcomeStats: outcomeStats,
    );
  }

  /// One bar per day for a "By Date" range of up to 31 days; beyond that,
  /// one bar per 7-day bucket so a multi-month range doesn't render
  /// hundreds of slivers.
  List<DailyRevenue> _buildCustomSeries(
    DateTime start, DateTime end, List<VendorOrder> delivered,
  ) {
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 31) {
      return List.generate(totalDays, (i) {
        final day = start.add(Duration(days: i));
        final dayOrders = delivered.where((o) =>
            o.placedAt.year == day.year && o.placedAt.month == day.month && o.placedAt.day == day.day);
        return DailyRevenue(
          label: '${day.day}/${day.month}',
          amount: dayOrders.fold(0.0, (sum, o) => sum + o.total),
          orders: dayOrders.length,
        );
      });
    }
    final buckets = (totalDays / 7).ceil();
    return List.generate(buckets, (i) {
      final bucketStart = start.add(Duration(days: 7 * i));
      final bucketEnd = bucketStart.add(const Duration(days: 7));
      final bucketOrders =
          delivered.where((o) => o.placedAt.isAfter(bucketStart) && o.placedAt.isBefore(bucketEnd));
      return DailyRevenue(
        label: '${bucketStart.day}/${bucketStart.month}',
        amount: bucketOrders.fold(0.0, (sum, o) => sum + o.total),
        orders: bucketOrders.length,
      );
    });
  }

  /// Returns (currentWindowStart, previousWindowStart) for the comparison
  /// used by the % change indicators.
  (DateTime, DateTime) _windowBounds(AnalyticsPeriod period, DateTime now) {
    switch (period) {
      case AnalyticsPeriod.daily:
        final today = DateTime(now.year, now.month, now.day);
        return (today, today.subtract(const Duration(days: 1)));
      case AnalyticsPeriod.weekly:
        return (now.subtract(const Duration(days: 7)), now.subtract(const Duration(days: 14)));
      case AnalyticsPeriod.monthly:
        return (now.subtract(const Duration(days: 30)), now.subtract(const Duration(days: 60)));
    }
  }

  /// Builds the chart series at the granularity matching [period]:
  /// daily -> last 14 days, weekly -> last 8 weeks, monthly -> last 6 months.
  List<DailyRevenue> _buildSeries(AnalyticsPeriod period, List<VendorOrder> delivered, DateTime now) {
    switch (period) {
      case AnalyticsPeriod.daily:
        const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return List.generate(14, (i) {
          final day = now.subtract(Duration(days: 13 - i));
          final dayOrders = delivered.where((o) =>
              o.placedAt.year == day.year && o.placedAt.month == day.month && o.placedAt.day == day.day);
          return DailyRevenue(
            label: dayLabels[day.weekday - 1],
            amount: dayOrders.fold(0.0, (sum, o) => sum + o.total),
            orders: dayOrders.length,
          );
        });
      case AnalyticsPeriod.weekly:
        return List.generate(8, (i) {
          final weekEnd = now.subtract(Duration(days: 7 * (7 - i)));
          final weekStart = weekEnd.subtract(const Duration(days: 7));
          final weekOrders =
              delivered.where((o) => o.placedAt.isAfter(weekStart) && o.placedAt.isBefore(weekEnd));
          return DailyRevenue(
            label: 'W${i + 1}',
            amount: weekOrders.fold(0.0, (sum, o) => sum + o.total),
            orders: weekOrders.length,
          );
        });
      case AnalyticsPeriod.monthly:
        const monthLabels = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return List.generate(6, (i) {
          final monthsAgo = 5 - i;
          final month = DateTime(now.year, now.month - monthsAgo);
          final monthOrders = delivered.where(
              (o) => o.placedAt.year == month.year && o.placedAt.month == month.month);
          return DailyRevenue(
            label: monthLabels[month.month - 1],
            amount: monthOrders.fold(0.0, (sum, o) => sum + o.total),
            orders: monthOrders.length,
          );
        });
    }
  }
}
