import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../widgets/app_logo.dart';
import '../auth/login_screen.dart';
import 'policies.dart';
import 'policy_viewer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarPath;
  String _language = 'English';

  // Per-day hours
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late Map<String, _DayHours> _hours = {
    for (final d in _days)
      d: _DayHours(
        isOpen: d != 'Sun',
        open: const TimeOfDay(hour: 8, minute: 0),
        close: const TimeOfDay(hour: 21, minute: 0),
      ),
  };

  // Notification toggles
  bool _notifOrders = true;
  bool _notifReady = true;
  bool _notifOverdue = true;
  bool _notifPromos = false;

  bool _hoursSyncedFromFirestore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // One-time sync once persisted hours actually arrive — without this the
    // "Open · 8:00 AM - 9:00 PM" subtitle below would always show this
    // screen's hardcoded default, even after the vendor saved real hours in
    // a previous session.
    if (_hoursSyncedFromFirestore) return;
    final vendor = context.read<VendorProvider>();
    final persisted = _hoursFromFirestore(vendor.openingHours, _days);
    if (persisted != null) {
      _hoursSyncedFromFirestore = true;
      setState(() => _hours = persisted);
    }
  }

  String get _hoursLabel {
    final openCount = _hours.values.where((h) => h.isOpen).length;
    if (openCount == 0) return 'Closed all days';
    if (openCount == 7) {
      final h = _hours['Mon']!;
      return 'Daily ${h.open.format(context)} – ${h.close.format(context)}';
    }
    return '$openCount days open';
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _editText({
    required String title,
    required String current,
    required void Function(String) onSave,
  }) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.fredoka(fontSize: 20)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: title),
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) onSave(v);
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _editNumber({
    required String title,
    required num current,
    required void Function(num) onSave,
  }) {
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.fredoka(fontSize: 20)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: title),
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = num.tryParse(ctrl.text.trim());
              if (v != null && v >= 0) onSave(v);
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _editHours() {
    final vendor = context.read<VendorProvider>();
    // Persisted hours (if the vendor's ever saved before) take precedence
    // over whatever this screen instance happened to default to locally —
    // otherwise re-opening the sheet after a fresh app launch would show
    // the hardcoded 8am-9pm default instead of what was actually saved.
    final persisted = _hoursFromFirestore(vendor.openingHours, _days);
    if (persisted != null) _hours = persisted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HoursSheet(
        hours: Map.of(_hours),
        days: _days,
        onSave: (updated) {
          setState(() => _hours = updated);
          context.read<VendorProvider>().updateOpeningHours(_hoursToFirestore(updated));
        },
      ),
    );
  }

  void _editNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Notifications',
                    style: GoogleFonts.fredoka(fontSize: 20)),
              ),
              _NotifToggle(
                label: 'New Orders',
                subtitle: 'Alert when a new order arrives',
                value: _notifOrders,
                onChanged: (v) { setLocal(() => _notifOrders = v); setState(() => _notifOrders = v); },
              ),
              _NotifToggle(
                label: 'Order Ready',
                subtitle: 'Alert when prep is done',
                value: _notifReady,
                onChanged: (v) { setLocal(() => _notifReady = v); setState(() => _notifReady = v); },
              ),
              _NotifToggle(
                label: 'Overdue Orders',
                subtitle: 'Alert for unanswered orders after 3 min',
                value: _notifOverdue,
                onChanged: (v) { setLocal(() => _notifOverdue = v); setState(() => _notifOverdue = v); },
              ),
              _NotifToggle(
                label: 'Promotions & Updates',
                subtitle: 'Platform news and offers',
                value: _notifPromos,
                onChanged: (v) { setLocal(() => _notifPromos = v); setState(() => _notifPromos = v); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _editLanguage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Language', style: GoogleFonts.fredoka(fontSize: 20)),
              ),
              for (final lang in ['English', 'العربية'])
                RadioListTile<String>(
                  value: lang,
                  groupValue: _language,
                  activeColor: AppColors.primary,
                  title: Text(lang, style: GoogleFonts.plusJakartaSans(fontSize: 15)),
                  onChanged: (v) {
                    setLocal(() => _language = v!);
                    setState(() => _language = v!);
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpCenter() {
    final faqs = [
      ('How do I accept an order?', 'Tap the order card and press "Accept Order". The customer is notified immediately.'),
      ('How do I mark an order ready?', 'From the order detail screen, press "Mark as Ready" once preparation is complete.'),
      ('Can I pause new orders?', 'Yes — toggle "Busy Mode" or close your restaurant from the dashboard status banner.'),
      ('How do I edit a menu item?', 'Go to Menu, tap any item, then tap "Edit Item" at the bottom of the detail screen.'),
      ('How is revenue calculated?', 'Only delivered orders count toward today\'s revenue. Cancelled orders are excluded.'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Help Center', style: GoogleFonts.fredoka(fontSize: 20)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: faqs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(faqs[i].$1,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Text(faqs[i].$2,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, height: 1.5, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendFeedback() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Send Feedback', style: GoogleFonts.fredoka(fontSize: 20)),
            const SizedBox(height: 4),
            Text('Your feedback helps us improve the app.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thanks for your feedback!',
                          style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text('Submit',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('About', style: GoogleFonts.fredoka(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 32),
            const SizedBox(height: 12),
            Text('Uni Eats Vendor',
                style: GoogleFonts.fredoka(fontSize: 18)),
            const SizedBox(height: 4),
            Text('Version 0.1.0',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Text(
              'Vendor dashboard for campus food vendors on the Uni Eats platform.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out?', style: GoogleFonts.fredoka(fontSize: 20)),
        content: Text('You will be returned to the login screen.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              final nav = Navigator.of(context);
              final auth = context.read<VendorAuthProvider>();
              Navigator.pop(ctx);
              auth.signOut();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const VendorLoginScreen()),
                (_) => false,
              );
            },
            child: Text('Sign Out',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _avatarPath = picked.path);
  }

  /// Maps a policy document reference to a representative icon for its row.
  IconData _policyIcon(String ref) {
    switch (ref) {
      case 'UE-POL-PRIV-001':
        return Icons.lock_outline; // Data Protection & Privacy
      case 'UE-POL-FOOD-001':
        return Icons.restaurant_outlined; // Food Safety & Handling
      case 'UE-POL-AUP-001':
        return Icons.gavel_outlined; // Acceptable Use
      case 'UE-POL-REF-001':
        return Icons.receipt_long_outlined; // Refund & Cancellation
      case 'UE-POL-PAY-001':
        return Icons.payments_outlined; // Payment Security
      case 'UE-POL-DR-001':
        return Icons.history_toggle_off_outlined; // Data Retention & Deletion
      default:
        return Icons.description_outlined;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vendor = context.watch<VendorProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final enabledNotifCount = [_notifOrders, _notifReady, _notifOverdue, _notifPromos]
        .where((v) => v).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 32),
        child: Column(
          children: [
            _ProfileHeader(
              vendor: vendor,
              isDark: isDark,
              theme: theme,
              avatarPath: _avatarPath,
              onAvatarTap: _pickAvatar,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Restaurant',
              children: [
                _SettingTile(
                  icon: Icons.store_outlined,
                  label: 'Restaurant Name',
                  subtitle: vendor.pendingNameChangeRequest?['status'] == 'pending'
                      ? '${vendor.restaurantName} · pending approval: "${vendor.pendingNameChangeRequest!['requestedName']}"'
                      : vendor.pendingNameChangeRequest?['status'] == 'rejected'
                          ? '${vendor.restaurantName} · last request rejected'
                          : vendor.restaurantName,
                  // Name changes now go through admin approval (see
                  // firestore.rules) — this opens a request instead of
                  // writing the name directly.
                  onTap: () => _editText(
                    title: 'Request Restaurant Name Change',
                    current: vendor.restaurantName,
                    onSave: (v) async {
                      final error = await vendor.requestNameChange(v);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error ?? 'Name change submitted for admin approval.'),
                      ));
                    },
                  ),
                ),
                _SettingTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  subtitle: vendor.restaurantLocation,
                  onTap: () => _editText(
                    title: 'Location',
                    current: vendor.restaurantLocation,
                    onSave: (v) => vendor.updateRestaurantLocation(v),
                  ),
                ),
                _SettingTile(
                  icon: Icons.schedule_outlined,
                  label: 'Opening Hours',
                  subtitle: _hoursLabel,
                  onTap: _editHours,
                ),
                _SettingTile(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  subtitle: vendor.category.isEmpty ? 'Not set' : vendor.category,
                  onTap: () => _editText(
                    title: 'Category',
                    current: vendor.category,
                    onSave: (v) => vendor.updateCategory(v),
                  ),
                ),
                _SettingTile(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  subtitle: vendor.description.isEmpty ? 'Not set' : vendor.description,
                  onTap: () => _editText(
                    title: 'Description',
                    current: vendor.description,
                    onSave: (v) => vendor.updateDescription(v),
                  ),
                ),
                _SettingTile(
                  icon: Icons.timer_outlined,
                  label: 'Delivery Time Estimate',
                  subtitle: '${vendor.deliveryTimeMin} min',
                  onTap: () => _editNumber(
                    title: 'Delivery Time (minutes)',
                    current: vendor.deliveryTimeMin,
                    onSave: (v) => vendor.updateDeliveryTimeMin(v.toInt()),
                  ),
                ),
                _SettingTile(
                  icon: Icons.payments_outlined,
                  label: 'Minimum Order',
                  subtitle: 'QAR ${vendor.minOrder.toStringAsFixed(2)}',
                  onTap: () => _editNumber(
                    title: 'Minimum Order (QAR)',
                    current: vendor.minOrder,
                    onSave: (v) => vendor.updateMinOrder(v.toDouble()),
                  ),
                ),
                _ToggleTile(
                  icon: Icons.delivery_dining_outlined,
                  label: 'Offers Delivery',
                  value: vendor.offersDelivery,
                  onChanged: (v) => vendor.setOffersDelivery(v),
                ),
                _ToggleTile(
                  icon: Icons.storefront_outlined,
                  label: 'Offers Pickup',
                  value: vendor.offersPickup,
                  onChanged: (v) => vendor.setOffersPickup(v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'App',
              children: [
                _ToggleTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggle(),
                ),
                _SettingTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  subtitle: '$enabledNotifCount of 4 alerts enabled',
                  onTap: _editNotifications,
                ),
                _SettingTile(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  subtitle: _language,
                  onTap: _editLanguage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Support',
              children: [
                _SettingTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help Center',
                  onTap: _showHelpCenter,
                ),
                _SettingTile(
                  icon: Icons.feedback_outlined,
                  label: 'Send Feedback',
                  onTap: _sendFeedback,
                ),
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  subtitle: 'v0.1.0',
                  onTap: _showAbout,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Legal & Policies — official Uni Eats policy documents, readable
            // offline (see policies.dart / PolicyViewerScreen).
            _Section(
              title: 'Legal & Policies',
              children: [
                for (final policy in kVendorPolicies)
                  _SettingTile(
                    icon: _policyIcon(policy.ref),
                    label: policy.title,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PolicyViewerScreen(policy: policy),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _confirmSignOut,
                child: Text('Sign Out',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            const AppLogo(size: 20),
            const SizedBox(height: 8),
            Text('Uni Eats Vendor v0.1.0',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.vendor,
    required this.isDark,
    required this.theme,
    required this.avatarPath,
    required this.onAvatarTap,
  });
  final VendorProvider vendor;
  final bool isDark;
  final ThemeData theme;
  final String? avatarPath;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: avatarPath != null
                      ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                      : const Icon(Icons.restaurant_rounded, size: 38, color: Colors.white),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(vendor.restaurantName,
              style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 3),
              Text(vendor.restaurantLocation,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(label: 'Orders', value: '${vendor.todayOrderCount}'),
              const SizedBox(width: 16),
              const _StatPill(label: 'Rating', value: '4.7★'),
              const SizedBox(width: 16),
              _StatPill(label: 'Items', value: '${vendor.menuItems.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
      ],
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 8),
        Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Tiles ──────────────────────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.primary),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall)
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          size: 18, color: theme.colorScheme.outline),
      onTap: onTap,
      dense: true,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primary),
      dense: true,
    );
  }
}

// ── Notification bottom-sheet row ──────────────────────────────────────────────

// ── Opening hours data ─────────────────────────────────────────────────────────

class _DayHours {
  const _DayHours({required this.isOpen, required this.open, required this.close});
  final bool isOpen;
  final TimeOfDay open;
  final TimeOfDay close;

  _DayHours copyWith({bool? isOpen, TimeOfDay? open, TimeOfDay? close}) =>
      _DayHours(
        isOpen: isOpen ?? this.isOpen,
        open: open ?? this.open,
        close: close ?? this.close,
      );

  Map<String, dynamic> toMap() => {
        'isOpen': isOpen,
        'openMinutes': open.hour * 60 + open.minute,
        'closeMinutes': close.hour * 60 + close.minute,
      };

  static _DayHours fromMap(Map<String, dynamic> m) {
    final openMin = (m['openMinutes'] as num?)?.toInt() ?? 8 * 60;
    final closeMin = (m['closeMinutes'] as num?)?.toInt() ?? 21 * 60;
    return _DayHours(
      isOpen: m['isOpen'] as bool? ?? true,
      open: TimeOfDay(hour: openMin ~/ 60, minute: openMin % 60),
      close: TimeOfDay(hour: closeMin ~/ 60, minute: closeMin % 60),
    );
  }
}

Map<String, dynamic> _hoursToFirestore(Map<String, _DayHours> hours) =>
    hours.map((day, h) => MapEntry(day, h.toMap()));

Map<String, _DayHours>? _hoursFromFirestore(Map<String, dynamic>? data, List<String> days) {
  if (data == null) return null;
  return {
    for (final d in days)
      d: data[d] is Map
          ? _DayHours.fromMap(Map<String, dynamic>.from(data[d] as Map))
          : _DayHours(
              isOpen: d != 'Sun',
              open: const TimeOfDay(hour: 8, minute: 0),
              close: const TimeOfDay(hour: 21, minute: 0),
            ),
  };
}

// ── Opening hours bottom sheet ─────────────────────────────────────────────────

class _HoursSheet extends StatefulWidget {
  const _HoursSheet({
    required this.hours,
    required this.days,
    required this.onSave,
  });
  final Map<String, _DayHours> hours;
  final List<String> days;
  final void Function(Map<String, _DayHours>) onSave;

  @override
  State<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<_HoursSheet> {
  late Map<String, _DayHours> _hours;
  bool _sameForAll = false;

  @override
  void initState() {
    super.initState();
    _hours = Map.of(widget.hours);
    // Detect if already same for all open days
    final openDays = widget.days.where((d) => widget.hours[d]!.isOpen).toList();
    if (openDays.length > 1) {
      final first = widget.hours[openDays.first]!;
      _sameForAll = openDays.every((d) {
        final h = widget.hours[d]!;
        return h.open == first.open && h.close == first.close;
      });
    }
  }

  Future<void> _pickTimes(String day) async {
    final current = _hours[day]!;
    final open = await showTimePicker(
      context: context,
      initialTime: current.open,
      helpText: 'Opening — $day',
    );
    if (open == null || !mounted) return;
    final close = await showTimePicker(
      context: context,
      initialTime: current.close,
      helpText: 'Closing — $day',
    );
    if (close == null || !mounted) return;
    setState(() {
      if (_sameForAll) {
        // Apply to all open days
        for (final d in widget.days) {
          if (_hours[d]!.isOpen) {
            _hours[d] = _hours[d]!.copyWith(open: open, close: close);
          }
        }
      } else {
        _hours[day] = _hours[day]!.copyWith(open: open, close: close);
      }
    });
  }

  void _applyMasterToAll() {
    final master = _hours[widget.days.first]!;
    setState(() {
      for (final d in widget.days) {
        _hours[d] = _hours[d]!.copyWith(open: master.open, close: master.close);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Everything goes into one ListView with the sheet's scroll controller
    // so the drag gesture works across the handle, header, toggle, and day rows.
    final dayCount = widget.days.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (_, sc) => ListView.builder(
        controller: sc,
        padding: EdgeInsets.zero,
        // 3 fixed items (handle, header, toggle) + days
        itemCount: 3 + dayCount,
        itemBuilder: (_, i) {
          // ── Handle + header ──────────────────────────────────────
          if (i == 0) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('Opening Hours', style: GoogleFonts.fredoka(fontSize: 20)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          widget.onSave(_hours);
                          Navigator.pop(context);
                        },
                        child: Text('Save',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // ── Same for all toggle ──────────────────────────────────
          if (i == 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceAlt,
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: SwitchListTile.adaptive(
                  dense: true,
                  value: _sameForAll,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                  title: Text('Same hours for all days',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _sameForAll
                        ? 'Tap any day row to change all hours at once'
                        : 'Edit each day individually',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.grey),
                  ),
                  onChanged: (v) {
                    setState(() => _sameForAll = v);
                    if (v) _applyMasterToAll();
                  },
                ),
              ),
            );
          }

          // ── Spacer before day rows ───────────────────────────────
          if (i == 2) return const SizedBox(height: 8);

          // ── Day rows ─────────────────────────────────────────────
          final dayIndex = i - 3;
          final day = widget.days[dayIndex];
          final h = _hours[day]!;
          final isLast = dayIndex == dayCount - 1;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 24 : 6),
            child: _DayRow(
              day: day,
              hours: h,
              isDark: isDark,
              onToggleClosed: (isOpen) => setState(() {
                _hours[day] = h.copyWith(isOpen: isOpen);
              }),
              onTapTimes: () => _pickTimes(day),
            ),
          );
        },
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.hours,
    required this.isDark,
    required this.onToggleClosed,
    required this.onTapTimes,
  });
  final String day;
  final _DayHours hours;
  final bool isDark;
  final ValueChanged<bool> onToggleClosed;
  final VoidCallback onTapTimes;

  static const _dayFull = {
    'Mon': 'Monday', 'Tue': 'Tuesday', 'Wed': 'Wednesday',
    'Thu': 'Thursday', 'Fri': 'Friday', 'Sat': 'Saturday', 'Sun': 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hours.isOpen ? onTapTimes : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hours.isOpen
                ? AppColors.primary.withValues(alpha: 0.35)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            // Day name — wide enough for "Wednesday" at 14px bold
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayFull[day] ?? day,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hours.isOpen
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                          : Colors.grey,
                    ),
                  ),
                  if (!hours.isOpen)
                    Text('Closed',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: AppColors.error)),
                ],
              ),
            ),

            // Time chips — Expanded hard-clamps this section,
            // so the Switch outside is never squeezed off-screen
            Expanded(
              child: hours.isOpen
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TimeChip(time: hours.open, isDark: isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('–',
                              style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)),
                        ),
                        _TimeChip(time: hours.close, isDark: isDark),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Toggle — always rightmost, outside Expanded
            Switch.adaptive(
              value: hours.isOpen,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.error,
              inactiveTrackColor: AppColors.error.withValues(alpha: 0.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onToggleClosed,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.isDark});
  final TimeOfDay time;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time.format(context),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Notification toggle row ────────────────────────────────────────────────────

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      activeThumbColor: Colors.white,
      title: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
