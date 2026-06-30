import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import 'help_content.dart';
import 'policies.dart';
import 'policy_viewer_screen.dart';

/// Vendor Help & Support center: contact channels, a structured "report a
/// problem" path (composed into a pre-filled email), and a grouped FAQ. All
/// content is offline; only the contact actions need connectivity.
class HelpSupportScreen extends StatefulWidget {
  /// Identifying context pre-filled into support emails so ops can triage
  /// without a back-and-forth. Any may be empty if not yet loaded.
  final String restaurantName;
  final String vendorId;
  final String appVersion;

  const HelpSupportScreen({
    super.key,
    required this.restaurantName,
    required this.vendorId,
    required this.appVersion,
  });

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _scroll = ScrollController();
  bool _showCompactTitle = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > 40;
      if (show != _showCompactTitle) setState(() => _showCompactTitle = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ---- Actions -------------------------------------------------------------

  Future<void> _launch(Uri uri, String failMsg) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast(failMsg);
    } catch (_) {
      if (mounted) _toast(failMsg);
    }
  }

  void _call(String tel, String failMsg) =>
      _launch(Uri(scheme: 'tel', path: tel), failMsg);

  /// Footer appended to every support email so ops can identify the vendor.
  String _contextFooter() => (StringBuffer()
        ..writeln('———')
        ..writeln('Restaurant: ${widget.restaurantName.isEmpty ? "—" : widget.restaurantName}')
        ..writeln('Vendor ID: ${widget.vendorId.isEmpty ? "—" : widget.vendorId}')
        ..writeln('App version: ${widget.appVersion.isEmpty ? "—" : widget.appVersion}')
        ..writeln('Platform: ${Platform.operatingSystem}'))
      .toString();

  /// Opens the mail client with vendor/app context pre-filled in the body.
  void _emailSupport({required String subject, String? leadingBody}) {
    final body = StringBuffer();
    if (leadingBody != null && leadingBody.trim().isNotEmpty) {
      body
        ..writeln(leadingBody.trim())
        ..writeln();
    } else {
      body
        ..writeln()
        ..writeln('Please describe your issue above this line.')
        ..writeln();
    }
    body.write(_contextFooter());
    _launch(
      Uri(
        scheme: 'mailto',
        path: kOpsEmail,
        queryParameters: {'subject': subject, 'body': body.toString()},
      ),
      'No email app found. Reach us at $kOpsEmail',
    );
  }

  void _whatsApp() => _launch(
        Uri.parse('https://wa.me/$kOpsWhatsApp'),
        'Could not open WhatsApp. Call us at $kOpsPhoneDisplay',
      );

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));

  Future<void> _copyVendorId() async {
    await Clipboard.setData(ClipboardData(text: widget.vendorId));
    if (mounted) _toast('Vendor ID copied');
  }

  void _openReportSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(
        onSubmit: (category, orderId, message) {
          Navigator.pop(context);
          final lead = StringBuffer()..writeln('Category: ${category.label}');
          if (orderId.trim().isNotEmpty) lead.writeln('Order ID: ${orderId.trim()}');
          lead
            ..writeln()
            ..writeln(message.trim());
          _emailSupport(
            subject: 'Vendor app — ${category.label} issue',
            leadingBody: lead.toString(),
          );
        },
      ),
    );
  }

  void _openPoliciesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PoliciesSheet(
        onSelect: (policy) {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => PolicyViewerScreen(policy: policy)),
          );
        },
      ),
    );
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar — back + title that fades in on scroll.
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              decoration: BoxDecoration(
                color: bg,
                border: Border(
                  bottom: BorderSide(
                    color: _showCompactTitle ? border : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: text),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _showCompactTitle ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        'Help & Support',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                        color: text,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 20),
                    child: Text(
                      'Reach the Uni Eats team, report an issue, or browse common '
                      'questions.',
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: sub),
                    ),
                  ),

                  // ---- Support hours banner ----
                  _HoursBanner(accent: accent, text: text, sub: sub, isDark: isDark),
                  const SizedBox(height: 24),

                  // ---- Contact us ----
                  _SectionLabel('Contact us', sub),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Email support',
                    subtitle: kOpsEmail,
                    surface: surface,
                    border: border,
                    text: text,
                    sub: sub,
                    accent: accent,
                    onTap: () => _emailSupport(subject: 'Vendor app support'),
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.call_outlined,
                    title: 'Call operations',
                    subtitle: kOpsPhoneDisplay,
                    surface: surface,
                    border: border,
                    text: text,
                    sub: sub,
                    accent: accent,
                    onTap: () => _call(kOpsTel, 'Could not start the call. Dial $kOpsPhoneDisplay.'),
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    subtitle: kOpsPhoneDisplay,
                    surface: surface,
                    border: border,
                    text: text,
                    sub: sub,
                    accent: accent,
                    onTap: _whatsApp,
                  ),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    icon: Icons.support_agent_rounded,
                    label: 'Report a problem',
                    accent: accent,
                    onTap: _openReportSheet,
                  ),
                  const SizedBox(height: 26),

                  // ---- FAQ ----
                  _SectionLabel('Frequently asked', sub),
                  const SizedBox(height: 4),
                  for (final group in kVendorFaq)
                    _FaqGroupView(
                      group: group,
                      surface: surface,
                      border: border,
                      text: text,
                      sub: sub,
                      accent: accent,
                    ),
                  const SizedBox(height: 18),

                  // ---- Legal ----
                  _SectionLabel('More', sub),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.gavel_outlined,
                    title: 'Terms & Policies',
                    subtitle: 'Privacy, food safety, payments, and more',
                    surface: surface,
                    border: border,
                    text: text,
                    sub: sub,
                    accent: accent,
                    onTap: _openPoliciesSheet,
                  ),
                  const SizedBox(height: 22),

                  // ---- Diagnostics ----
                  _DiagnosticsFooter(
                    vendorId: widget.vendorId,
                    appVersion: widget.appVersion,
                    sub: sub,
                    onCopyId: widget.vendorId.isEmpty ? null : _copyVendorId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Support hours banner
// =============================================================================
class _HoursBanner extends StatelessWidget {
  final Color accent;
  final Color text;
  final Color sub;
  final bool isDark;
  const _HoursBanner({
    required this.accent,
    required this.text,
    required this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 19, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kSupportHours,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: text)),
                const SizedBox(height: 2),
                Text(kSupportResponse,
                    style: TextStyle(fontSize: 12, height: 1.35, color: sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared pieces
// =============================================================================
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color surface;
  final Color border;
  final Color text;
  final Color sub;
  final Color accent;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.surface,
    required this.border,
    required this.text,
    required this.sub,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: sub)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqGroupView extends StatelessWidget {
  final FaqGroup group;
  final Color surface;
  final Color border;
  final Color text;
  final Color sub;
  final Color accent;
  const _FaqGroupView({
    required this.group,
    required this.surface,
    required this.border,
    required this.text,
    required this.sub,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            group.title,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: text),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: border, indent: 16, endIndent: 16),
                _FaqTile(item: group.items[i], text: text, sub: sub, accent: accent),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  final Color text;
  final Color sub;
  final Color accent;
  const _FaqTile({required this.item, required this.text, required this.sub, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: accent,
        collapsedIconColor: sub,
        title: Text(
          item.question,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.3, color: text),
        ),
        children: [
          Text(item.answer, style: TextStyle(fontSize: 13, height: 1.55, color: sub)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsFooter extends StatelessWidget {
  final String vendorId;
  final String appVersion;
  final Color sub;
  final VoidCallback? onCopyId;
  const _DiagnosticsFooter({
    required this.vendorId,
    required this.appVersion,
    required this.sub,
    required this.onCopyId,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = vendorId.isEmpty
        ? '—'
        : (vendorId.length > 10 ? '${vendorId.substring(0, 10)}…' : vendorId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: onCopyId,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Vendor ID: $shortId', style: TextStyle(fontSize: 11.5, color: sub)),
                if (onCopyId != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.copy_rounded, size: 13, color: sub),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          appVersion.isEmpty ? 'Uni Eats Vendor' : 'Uni Eats Vendor · v$appVersion',
          style: TextStyle(fontSize: 11.5, color: sub),
        ),
      ],
    );
  }
}

// =============================================================================
// Report-a-problem bottom sheet
// =============================================================================
class _ReportSheet extends StatefulWidget {
  final void Function(ReportCategory category, String orderId, String message) onSubmit;
  const _ReportSheet({required this.onSubmit});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportCategory _category = kReportCategories.first;
  final _orderCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _msgEmpty = true;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final empty = _msgCtrl.text.trim().isEmpty;
      if (empty != _msgEmpty) setState(() => _msgEmpty = empty);
    });
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final field = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: sub.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Report a problem',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: text)),
              const SizedBox(height: 4),
              Text("We'll open your email app with the details filled in.",
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: sub)),
              const SizedBox(height: 18),

              // Category chips
              Text('CATEGORY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: sub)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in kReportCategories)
                    _CategoryChip(
                      label: c.label,
                      selected: c == _category,
                      accent: accent,
                      text: text,
                      sub: sub,
                      border: border,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Optional order ID
              Text('ORDER ID (OPTIONAL)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: sub)),
              const SizedBox(height: 8),
              _Field(
                controller: _orderCtrl,
                hint: 'e.g. #A1B2C3',
                fill: field,
                text: text,
                sub: sub,
                border: border,
                accent: accent,
              ),
              const SizedBox(height: 16),

              // Message
              Text('WHAT HAPPENED?',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: sub)),
              const SizedBox(height: 8),
              _Field(
                controller: _msgCtrl,
                hint: 'Describe the issue in a sentence or two…',
                fill: field,
                text: text,
                sub: sub,
                border: border,
                accent: accent,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accent.withValues(alpha: 0.4),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _msgEmpty
                      ? null
                      : () => widget.onSubmit(_category, _orderCtrl.text, _msgCtrl.text),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_outline_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Continue in email',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color text;
  final Color sub;
  final Color border;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.text,
    required this.sub,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent : border, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? accent : sub,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color fill;
  final Color text;
  final Color sub;
  final Color border;
  final Color accent;
  final int minLines;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.hint,
    required this.fill,
    required this.text,
    required this.sub,
    required this.border,
    required this.accent,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: sub.withValues(alpha: 0.8)),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }
}

// =============================================================================
// Terms & Policies picker sheet
// =============================================================================
class _PoliciesSheet extends StatelessWidget {
  final void Function(PolicyDoc policy) onSelect;
  const _PoliciesSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: sub.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text('Terms & Policies',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: text)),
            ),
            for (final policy in kVendorPolicies)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.description_outlined, size: 20, color: accent),
                title: Text(policy.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sub),
                onTap: () => onSelect(policy),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
