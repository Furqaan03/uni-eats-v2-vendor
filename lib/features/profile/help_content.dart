/// Static content for the vendor Help & Support screen — contact channels and
/// a grouped FAQ. Baked in as constants so it is fully readable offline; only
/// the contact actions (email, call, WhatsApp) need connectivity.
library;

// =============================================================================
// Contacts
// =============================================================================

/// Uni Eats operations — app, orders, payouts, and incident reports.
const String kOpsEmail = 'support@unieats.qa';
const String kOpsPhoneDisplay = '+974 6684 4777';
const String kOpsTel = '+97466844777';
const String kOpsWhatsApp = '97466844777';

/// Shown as an expectation-setting line near the contact options.
const String kSupportHours = 'Daily · 9:00 AM – 11:00 PM (GMT+3)';
const String kSupportResponse = 'Email replies typically within 24 hours.';

// =============================================================================
// Report-a-problem categories
// =============================================================================

class ReportCategory {
  final String label;

  /// Folded into the support email subject so ops can route the ticket.
  final String tag;
  const ReportCategory(this.label, this.tag);
}

const List<ReportCategory> kReportCategories = [
  ReportCategory('Orders', 'orders'),
  ReportCategory('Payments & Payouts', 'payments'),
  ReportCategory('Menu', 'menu'),
  ReportCategory('Account & Login', 'account'),
  ReportCategory('App bug', 'bug'),
  ReportCategory('Other', 'other'),
];

// =============================================================================
// FAQ — grouped by topic
// =============================================================================

class FaqItem {
  final String question;
  final String answer;
  const FaqItem(this.question, this.answer);
}

class FaqGroup {
  final String title;
  final List<FaqItem> items;
  const FaqGroup(this.title, this.items);
}

const List<FaqGroup> kVendorFaq = [
  FaqGroup('Orders', [
    FaqItem(
      'How do I accept an order?',
      'Open the order from the Dashboard or Orders tab and press "Accept Order". '
          'The customer is notified immediately and the order moves into '
          'preparation. Try to accept within a few minutes — orders left '
          'unanswered are flagged as overdue.',
    ),
    FaqItem(
      'How do I mark an order ready?',
      'From the order detail screen, press "Mark as Ready" once preparation is '
          'complete. This signals the assigned driver (or the customer, for '
          'pickup) that the order can be collected.',
    ),
    FaqItem(
      'What if I can\'t fulfil an order?',
      'If an item is unavailable or you can\'t complete the order, decline or '
          'cancel it from the order screen and select a reason. The customer is '
          'notified and any payment already made is refunded automatically. '
          'Frequent cancellations can affect your standing on the platform.',
    ),
    FaqItem(
      'Can I pause new orders when I\'m slammed?',
      'Yes. Use Busy Mode or close your restaurant from the status banner on the '
          'Dashboard. While closed, customers can still browse your menu but '
          'can\'t place new orders until you reopen.',
    ),
  ]),
  FaqGroup('Menu', [
    FaqItem(
      'How do I edit a menu item?',
      'Go to the Menu tab, tap any item to open its detail, then tap "Edit Item" '
          'at the bottom. You can update the name, price, description, photo, and '
          'availability.',
    ),
    FaqItem(
      'How do I mark an item out of stock?',
      'Toggle the item\'s availability off from the Menu tab. Out-of-stock items '
          'stay listed but can\'t be ordered until you switch them back on.',
    ),
    FaqItem(
      'How do I add allergen information?',
      'Add allergen details in the item\'s description when editing it. Accurate '
          'allergen information is required under the Food Safety & Handling '
          'policy — update it within 48 hours of any recipe change.',
    ),
  ]),
  FaqGroup('Payments & Payouts', [
    FaqItem(
      'How is my revenue calculated?',
      'Only delivered orders count toward your revenue. Cancelled and rejected '
          'orders are excluded. Your daily total is shown on the Dashboard and '
          'broken down in Analytics.',
    ),
    FaqItem(
      'When and how do I get paid?',
      'Payouts are settled from completed orders, net of the agreed platform '
          'commission, to the bank details on file. Settlement is reconciled '
          'against noqoody payment records before payout. Contact support if a '
          'payout looks wrong.',
    ),
    FaqItem(
      'A customer was refunded — am I affected?',
      'You are compensated for orders you\'ve begun preparing when a cancellation '
          'isn\'t your fault. Refunds for orders cancelled before you accept them '
          'don\'t affect you. You can dispute any cancellation that hit your '
          'earnings via support — see the Refund & Cancellation policy.',
    ),
  ]),
  FaqGroup('Account & Settings', [
    FaqItem(
      'How do I change my restaurant name?',
      'Profile → Restaurant Name. Name changes go through admin approval, so '
          'you\'ll submit a request rather than changing it instantly. You\'ll see '
          'the request status (pending / rejected) on the same row.',
    ),
    FaqItem(
      'How do I update my opening hours?',
      'Profile → Opening Hours. Set each day individually, or turn on "Same hours '
          'for all days" to apply one schedule across the week. Hours are saved '
          'automatically and reflected to customers.',
    ),
    FaqItem(
      'How do I change my location, category, or delivery settings?',
      'All of these live under Profile → Restaurant: location, category, '
          'description, delivery time estimate, minimum order, and the delivery / '
          'pickup toggles. Changes take effect right away.',
    ),
    FaqItem(
      'Why does my restaurant show as closed?',
      'Your restaurant is closed to orders when Busy Mode is on, when you\'ve '
          'closed it from the status banner, or when the current time is outside '
          'your set opening hours. Check the Dashboard status banner first.',
    ),
  ]),
];
