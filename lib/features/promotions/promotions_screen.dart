import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/voucher.dart';
import '../../widgets/segmented_tabs.dart';

/// The promotions tab content (Vouchers + Item Discounts), embedded as a tab
/// inside the Menu screen rather than as its own top-level nav destination.
class PromotionsTabView extends StatelessWidget {
  const PromotionsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Builder(
            builder: (context) => SegmentedTabs(
              controller: DefaultTabController.of(context),
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              tabs: const [
                SegTab('Vouchers', icon: Icons.confirmation_number_outlined),
                SegTab('Item Discounts', icon: Icons.sell_outlined),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _VouchersTab(),
                _ItemDiscountsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════ Vouchers ════════════════════════════════════

class _VouchersTab extends StatelessWidget {
  const _VouchersTab();

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final vouchers = vendor.vouchers;
    final active = vouchers.where((v) => v.isActive).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVoucherSheet(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Voucher',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: vouchers.isEmpty
          ? _PromoEmpty(
              icon: Icons.confirmation_number_outlined,
              title: 'No vouchers yet',
              subtitle: 'Create a discount code customers can apply at checkout.',
              cta: 'Create your first voucher',
              onCta: () => _showVoucherSheet(context, null),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                _PromoSummaryStrip(
                  primary: '${vouchers.length}',
                  primaryLabel: vouchers.length == 1 ? 'voucher' : 'vouchers',
                  secondary: '$active active',
                ),
                const SizedBox(height: 14),
                for (final v in vouchers) _VoucherCard(voucher: v),
              ],
            ),
    );
  }

  static void _showVoucherSheet(BuildContext context, Voucher? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherForm(existing: existing),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  const _VoucherCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final vendor = context.read<VendorProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = voucher.isActive;
    final accent = active ? AppColors.accent : theme.colorScheme.outline;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final pageBg = theme.scaffoldBackgroundColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active
            ? AppColors.accent.withValues(alpha: 0.45)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Code stub (tap to copy) ──
            InkWell(
              onTap: () => _copy(context, voucher.code),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Container(
                width: 104,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('CODE',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: accent.withValues(alpha: 0.8))),
                    const SizedBox(height: 4),
                    Text(voucher.code,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 11, color: accent.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text('Copy',
                            style: TextStyle(fontSize: 10, color: accent.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _DashedVLine(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, notchColor: pageBg),
            // ── Details ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(voucher.displayValue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(active: active),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 13, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          voucher.minOrderAmount > 0
                              ? 'Min order ${formatCurrency(voucher.minOrderAmount)}'
                              : 'No minimum order',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Controls ──
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch(
                    value: active,
                    onChanged: (_) => vendor.toggleVoucher(voucher.id),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  _VoucherMenu(
                    onEdit: () => _VouchersTab._showVoucherSheet(context, voucher),
                    onCopy: () => _copy(context, voucher.code),
                    onDelete: () => _confirmDelete(context, vendor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Code "$code" copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _confirmDelete(BuildContext context, VendorProvider vendor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete voucher?'),
        content: Text('"${voucher.code}" will stop working for customers immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) vendor.deleteVoucher(voucher.id);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(active ? 'Active' : 'Paused',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _VoucherMenu extends StatelessWidget {
  const _VoucherMenu({required this.onEdit, required this.onCopy, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sub = Theme.of(context).colorScheme.outline;
    return PopupMenuButton<String>(
      tooltip: 'Voucher actions',
      icon: Icon(Icons.more_vert_rounded, size: 20, color: sub),
      padding: EdgeInsets.zero,
      onSelected: (v) => v == 'edit' ? onEdit() : v == 'copy' ? onCopy() : onDelete(),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: _Row(icon: Icons.edit_outlined, label: 'Edit')),
        const PopupMenuItem(value: 'copy', child: _Row(icon: Icons.copy_rounded, label: 'Copy code')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: _Row(icon: Icons.delete_outline_rounded, label: 'Delete', danger: true)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : Theme.of(context).colorScheme.onSurface;
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: color, fontSize: 14)),
    ]);
  }
}

/// Vertical dashed separator with a ticket "notch" punched at each end.
class _DashedVLine extends StatelessWidget {
  const _DashedVLine({required this.color, required this.notchColor});
  final Color color;
  final Color notchColor;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: CustomPaint(painter: _DashedPainter(color, notchColor)),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.notchColor);
  final Color color;
  final Color notchColor;
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // End notches
    final notch = Paint()..color = notchColor;
    canvas.drawCircle(Offset(cx, 0), 6, notch);
    canvas.drawCircle(Offset(cx, size.height), 6, notch);
    // Dashes
    final dash = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dashH = 4.0, gap = 4.0;
    var y = 8.0;
    while (y < size.height - 8) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + dashH), dash);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.notchColor != notchColor;
}

// ── Voucher form (bottom sheet) ──────────────────────────────────────────────

class _VoucherForm extends StatefulWidget {
  final Voucher? existing;
  const _VoucherForm({this.existing});

  @override
  State<_VoucherForm> createState() => _VoucherFormState();
}

class _VoucherFormState extends State<_VoucherForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minCtrl;
  VoucherType _type = VoucherType.percentage;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _codeCtrl = TextEditingController(text: v?.code ?? '');
    _valueCtrl = TextEditingController(text: v != null ? v.value.toStringAsFixed(0) : '');
    _minCtrl = TextEditingController(text: v != null ? v.minOrderAmount.toStringAsFixed(0) : '0');
    if (v != null) _type = v.type;
    for (final c in [_codeCtrl, _valueCtrl, _minCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final vendor = context.read<VendorProvider>();
    final value = double.parse(_valueCtrl.text.trim());
    final min = double.tryParse(_minCtrl.text.trim()) ?? 0;

    if (widget.existing != null) {
      vendor.updateVoucher(widget.existing!.copyWith(type: _type, value: value, minOrderAmount: min));
    } else {
      final code = _codeCtrl.text.trim().toUpperCase();
      vendor.addVoucher(Voucher(id: code, code: code, type: _type, value: value, minOrderAmount: min));
    }
    Navigator.pop(context);
  }

  List<double> get _presets =>
      _type == VoucherType.percentage ? const [10, 15, 20, 25, 50] : const [5, 10, 15, 20, 25];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final value = double.tryParse(_valueCtrl.text.trim()) ?? 0;
    final min = double.tryParse(_minCtrl.text.trim()) ?? 0;
    final code = _codeCtrl.text.trim().isEmpty ? 'CODE' : _codeCtrl.text.trim().toUpperCase();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(22)),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.existing == null ? 'New voucher' : 'Edit voucher',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),

                // Live preview
                _CouponPreview(code: code, type: _type, value: value, min: min),
                const SizedBox(height: 18),

                _Label('Voucher code'),
                TextFormField(
                  controller: _codeCtrl,
                  enabled: widget.existing == null,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. SAVE10',
                    helperText: widget.existing != null ? "Can't be changed after creation" : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _Label('Discount type'),
                SegmentedButton<VoucherType>(
                  segments: const [
                    ButtonSegment(value: VoucherType.percentage, label: Text('% Off'), icon: Icon(Icons.percent_rounded, size: 16)),
                    ButtonSegment(value: VoucherType.flat, label: Text('QAR Off'), icon: Icon(Icons.payments_outlined, size: 16)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 14),

                _Label('Value'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in _presets)
                      _PresetChip(
                        label: _type == VoucherType.percentage ? '${p.toInt()}%' : 'QAR ${p.toInt()}',
                        selected: value == p,
                        onTap: () => setState(() => _valueCtrl.text = p.toStringAsFixed(0)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          suffixText: _type == VoucherType.percentage ? '%' : 'QAR',
                        ),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null) return 'Required';
                          if (n <= 0) return 'Must be > 0';
                          if (_type == VoucherType.percentage && n > 100) return 'Max 100%';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min order', prefixText: 'QAR '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(widget.existing == null ? 'Create voucher' : 'Save changes',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponPreview extends StatelessWidget {
  const _CouponPreview({required this.code, required this.type, required this.value, required this.min});
  final String code;
  final VoucherType type;
  final double value;
  final double min;

  @override
  Widget build(BuildContext context) {
    final display = value <= 0
        ? '—'
        : (type == VoucherType.percentage ? '${value.toInt()}% OFF' : 'QAR ${value.toInt()} OFF');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.accent.withValues(alpha: 0.18), AppColors.accent.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: AppColors.accent, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(display,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent)),
                const SizedBox(height: 2),
                Text(min > 0 ? 'on orders over QAR ${min.toInt()}' : 'no minimum order',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(code,
              style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : theme.colorScheme.outline)),
      ),
    );
  }
}

// ═══════════════════════════════ Item Discounts ══════════════════════════════

class _ItemDiscountsTab extends StatelessWidget {
  const _ItemDiscountsTab();

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final items = vendor.menuItems;
    final discounted = items.where((i) => i.hasDiscount).toList();
    final rest = items.where((i) => !i.hasDiscount).toList();

    if (items.isEmpty) {
      return const _PromoEmpty(
        icon: Icons.sell_outlined,
        title: 'No menu items',
        subtitle: 'Add items to your menu first, then put them on offer here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        _PromoSummaryStrip(
          primary: '${discounted.length}',
          primaryLabel: discounted.length == 1 ? 'item on offer' : 'items on offer',
          secondary: '${items.length} total',
        ),
        const SizedBox(height: 14),
        if (discounted.isNotEmpty) ...[
          _SectionHeader('On offer'),
          const SizedBox(height: 8),
          for (final item in discounted) _ItemDiscountTile(item: item),
          const SizedBox(height: 18),
        ],
        _SectionHeader('All items'),
        const SizedBox(height: 8),
        for (final item in rest) _ItemDiscountTile(item: item),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 2),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: Theme.of(context).colorScheme.outline)),
      );
}

class _ItemDiscountTile extends StatelessWidget {
  final MenuItem item;
  const _ItemDiscountTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final on = item.hasDiscount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on
            ? AppColors.star.withValues(alpha: 0.45)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.imagePath != null
                  ? Image.file(File(item.imagePath!), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbFallback())
                  : _thumbFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                if (on)
                  Row(
                    children: [
                      Text(formatCurrency(item.discountedPrice),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.star, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text(formatCurrency(item.price),
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.outline,
                          )),
                    ],
                  )
                else
                  Text(formatCurrency(item.price),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          if (on) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.star.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${item.discountPercent!.toInt()}% OFF',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.star)),
            ),
            IconButton(
              tooltip: 'Edit discount',
              icon: Icon(Icons.tune_rounded, size: 18, color: theme.colorScheme.outline),
              onPressed: () => _showDiscountSheet(context, item),
            ),
          ] else
            TextButton.icon(
              onPressed: () => _showDiscountSheet(context, item),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Discount'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _thumbFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.fastfood_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
      );

  void _showDiscountSheet(BuildContext context, MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscountSheet(item: item),
    );
  }
}

class _DiscountSheet extends StatefulWidget {
  const _DiscountSheet({required this.item});
  final MenuItem item;

  @override
  State<_DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<_DiscountSheet> {
  late double _percent;

  @override
  void initState() {
    super.initState();
    _percent = widget.item.discountPercent ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final item = widget.item;
    final newPrice = item.price * (1 - _percent / 100);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Discount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 16),

            // Live price preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.star.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.star.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New price', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formatCurrency(newPrice),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.star)),
                          const SizedBox(width: 8),
                          Text(formatCurrency(item.price),
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.outline,
                              )),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.star,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_percent.toInt()}% OFF',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset chips
            Wrap(
              spacing: 8,
              children: [
                for (final p in const <double>[10, 15, 20, 25, 50])
                  _PresetChip(
                    label: '${p.toInt()}%',
                    selected: _percent == p,
                    onTap: () => setState(() => _percent = p),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Slider(
              value: _percent.clamp(1, 90),
              min: 1,
              max: 90,
              divisions: 89,
              activeColor: AppColors.star,
              label: '${_percent.toInt()}%',
              onChanged: (v) => setState(() => _percent = v.roundToDouble()),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.hasDiscount)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<VendorProvider>().setItemDiscount(item.id, null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
                if (item.hasDiscount) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.read<VendorProvider>().setItemDiscount(item.id, _percent);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.star,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Apply discount',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════ Shared ══════════════════════════════════════

class _PromoSummaryStrip extends StatelessWidget {
  const _PromoSummaryStrip({required this.primary, required this.primaryLabel, required this.secondary});
  final String primary;
  final String primaryLabel;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.16), AppColors.primary.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(primary,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(width: 5),
              Text(primaryLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text(secondary,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6,
                color: Theme.of(context).colorScheme.outline)),
      );
}

class _PromoEmpty extends StatelessWidget {
  const _PromoEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cta,
    this.onCta,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            if (cta != null && onCta != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCta,
                icon: const Icon(Icons.add_rounded),
                label: Text(cta!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
