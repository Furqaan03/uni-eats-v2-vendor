import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/voucher.dart';

/// The promotions tab content (Vouchers + Item Discounts), embedded as a tab
/// inside the Menu screen rather than as its own top-level nav destination.
class PromotionsTabView extends StatelessWidget {
  const PromotionsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.offWhite.withOpacity(0.5) : Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Vouchers'),
              Tab(text: 'Item Discounts'),
            ],
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

// ── Vouchers Tab ─────────────────────────────────────────────────────────────

class _VouchersTab extends StatelessWidget {
  const _VouchersTab();

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final vouchers = vendor.vouchers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVoucherSheet(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Voucher',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: vouchers.isEmpty
          ? Center(
              child: Text('No vouchers yet.',
                  style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? AppColors.offWhite.withOpacity(0.5)
                          : Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: vouchers.length,
              itemBuilder: (context, i) =>
                  _VoucherCard(voucher: vouchers[i]),
            ),
    );
  }

  void _showVoucherSheet(BuildContext context, Voucher? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E221E) : Colors.white;
    final textPrimary = isDark ? AppColors.offWhite : AppColors.charcoal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: voucher.isActive
              ? AppColors.accent.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: voucher.isActive
                    ? AppColors.accent.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                voucher.code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: voucher.isActive ? AppColors.accent : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.displayValue,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary),
                  ),
                  if (voucher.minOrderAmount > 0)
                    Text(
                      'Min order: QAR ${voucher.minOrderAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.offWhite.withOpacity(0.5)
                              : Colors.grey),
                    ),
                ],
              ),
            ),
            Switch(
              value: voucher.isActive,
              onChanged: (_) => vendor.toggleVoucher(voucher.id),
              activeColor: AppColors.accent,
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18,
                  color: isDark
                      ? AppColors.offWhite.withOpacity(0.5)
                      : Colors.grey),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _VoucherForm(existing: voucher),
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              onPressed: () => vendor.deleteVoucher(voucher.id),
            ),
          ],
        ),
      ),
    );
  }
}

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
    _valueCtrl = TextEditingController(
        text: v != null ? v.value.toStringAsFixed(0) : '');
    _minCtrl = TextEditingController(
        text: v != null ? v.minOrderAmount.toStringAsFixed(0) : '0');
    if (v != null) _type = v.type;
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
      // Code is immutable past creation (see the read-only field below) —
      // Firestore's doc ID for a voucher IS its code, so changing it here
      // would silently create a second document and leave the old code
      // active and unmanaged rather than renaming anything.
      vendor.updateVoucher(widget.existing!.copyWith(
        type: _type,
        value: value,
        minOrderAmount: min,
      ));
    } else {
      final code = _codeCtrl.text.trim().toUpperCase();
      vendor.addVoucher(Voucher(
        id: code,
        code: code,
        type: _type,
        value: value,
        minOrderAmount: min,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1E1A) : Colors.white;
    final textPrimary = isDark ? AppColors.offWhite : AppColors.charcoal;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'New Voucher' : 'Edit Voucher',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeCtrl,
              enabled: widget.existing == null,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Voucher Code',
                hintText: 'e.g. SAVE10',
                helperText: widget.existing != null ? "Can't be changed after creation" : null,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<VoucherType>(
              segments: const [
                ButtonSegment(
                    value: VoucherType.percentage, label: Text('% Off')),
                ButtonSegment(
                    value: VoucherType.flat, label: Text('QAR Off')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valueCtrl,
                    decoration: InputDecoration(
                      labelText: 'Value',
                      suffixText:
                          _type == VoucherType.percentage ? '%' : 'QAR',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Min Order', prefixText: 'QAR '),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: Text(
                  widget.existing == null ? 'Create Voucher' : 'Save Changes',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Item Discounts Tab ────────────────────────────────────────────────────────

class _ItemDiscountsTab extends StatelessWidget {
  const _ItemDiscountsTab();

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final items = vendor.menuItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final discounted = items.where((i) => i.hasDiscount).toList();
    final rest = items.where((i) => !i.hasDiscount).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (discounted.isNotEmpty) ...[
          _SectionHeader('Active Discounts', isDark),
          const SizedBox(height: 8),
          ...discounted.map((item) => _ItemDiscountTile(item: item)),
          const SizedBox(height: 20),
        ],
        _SectionHeader('All Items', isDark),
        const SizedBox(height: 8),
        ...rest.map((item) => _ItemDiscountTile(item: item)),
      ],
    );
  }
}

Widget _SectionHeader(String text, bool isDark) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.offWhite.withOpacity(0.5)
                  : Colors.grey[600],
              letterSpacing: 0.6)),
    );

class _ItemDiscountTile extends StatelessWidget {
  final MenuItem item;
  const _ItemDiscountTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final vendor = context.read<VendorProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E221E) : Colors.white;
    final textPrimary = isDark ? AppColors.offWhite : AppColors.charcoal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.hasDiscount
              ? AppColors.accent.withOpacity(0.4)
              : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: ListTile(
        title: Text(item.name,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        subtitle: item.hasDiscount
            ? Text(
                'QAR ${item.discountedPrice.toStringAsFixed(2)}  (was ${item.price.toStringAsFixed(2)})',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColors.accent))
            : Text('QAR ${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.offWhite.withOpacity(0.5)
                        : Colors.grey)),
        trailing: item.hasDiscount
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.discountPercent!.toInt()}% OFF',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.error),
                    onPressed: () => vendor.setItemDiscount(item.id, null),
                  ),
                ],
              )
            : TextButton(
                onPressed: () => _showDiscountDialog(context, item),
                child: Text('Add %',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, MenuItem item) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Discount for ${item.name}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Discount %', suffixText: '%'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = double.tryParse(ctrl.text.trim());
              if (n != null && n > 0 && n <= 100) {
                context.read<VendorProvider>().setItemDiscount(item.id, n);
              }
              Navigator.pop(ctx);
            },
            child: Text('Apply',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
