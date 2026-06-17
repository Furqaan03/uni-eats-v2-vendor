import 'package:intl/intl.dart';

String formatCurrency(double amount) => 'QAR ${amount.toStringAsFixed(2)}';

String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

String formatDate(DateTime dt) => DateFormat('MMM d').format(dt);

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return formatDate(dt);
}
