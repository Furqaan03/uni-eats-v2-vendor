import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../data/models/menu_item.dart';

class MenuItemDetailScreen extends StatefulWidget {
  const MenuItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _calsCtrl;
  late String _category;
  late int _prepMinutes;
  late List<String> _tags;
  String? _imagePath;
  bool _picking = false;
  bool _editing = false;

  static const _categories = [
    'Starters', 'Mains', 'Burgers', 'Wraps & Sandwiches',
    'Salads', 'Sides', 'Desserts', 'Drinks',
  ];

  static const _allTags = [
    'Featured', 'Top Rated', 'Best Seller', "Chef's Special", 'New',
    'Spicy', 'Vegetarian', 'Vegan', 'Gluten Free', 'Halal',
  ];

  MenuItem _getItem() => context
      .read<VendorProvider>()
      .menuItems
      .firstWhere((m) => m.id == widget.itemId);

  @override
  void initState() {
    super.initState();
    _loadFromItem(_getItem());
  }

  void _loadFromItem(MenuItem item) {
    _nameCtrl = TextEditingController(text: item.name);
    _descCtrl = TextEditingController(text: item.description);
    _priceCtrl = TextEditingController(text: item.price.toStringAsFixed(2));
    _calsCtrl = TextEditingController(text: item.calories?.toString() ?? '');
    _category = item.category;
    _prepMinutes = item.prepMinutes;
    _imagePath = item.imagePath;
    _tags = List.of(item.tags);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _calsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _imagePath = picked.path);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryTintLight,
                child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: Text('Take a photo',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryTintLight,
                child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: Text('Choose from gallery',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFECEB),
                  child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                ),
                title: Text('Remove photo',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500, color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagePath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Save Changes?', style: GoogleFonts.fredoka(fontSize: 20)),
        content: Text(
          'Update "${_nameCtrl.text.trim()}" with the new details?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      final vendor = context.read<VendorProvider>();
      final orig = _getItem();
      final updated = MenuItem(
        id: orig.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: _category,
        prepMinutes: _prepMinutes,
        calories: _calsCtrl.text.isEmpty ? null : int.tryParse(_calsCtrl.text),
        isAvailable: orig.isAvailable,
        imagePath: _imagePath,
        tags: _tags,
      );
      vendor.updateMenuItem(updated);
      // Stay on detail screen in view mode — don't pop
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updated.name} updated',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Item', style: GoogleFonts.fredoka(fontSize: 18)),
        content: Text('Remove "${_getItem().name}" from your menu?',
            style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<VendorProvider>().removeMenuItem(widget.itemId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final item = vendor.menuItems.firstWhere(
      (m) => m.id == widget.itemId,
      orElse: () => vendor.menuItems.first,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Item' : 'Item Detail',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w500)),
        actions: [
          if (!_editing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => setState(() => _editing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Remove',
              onPressed: _confirmDelete,
            ),
          ] else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
            ),
        ],
      ),
      body: _editing ? _buildEditForm(item, isDark) : _buildView(item, isDark),
    );
  }

  // ── View mode — clean info cards, no disabled inputs ─────────────────────

  Widget _buildView(MenuItem item, bool isDark) {
    return SingleChildScrollView(
      padding: AppSpacing.screenInsets.copyWith(top: 20, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          _PhotoBox(imagePath: item.imagePath, isDark: isDark, editing: false),
          const SizedBox(height: 24),

          // Name
          Text(
            item.name,
            style: GoogleFonts.fredoka(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Badge(label: item.category, color: AppColors.info),
              _Badge(
                label: item.isAvailable ? 'Available' : 'Unavailable',
                color: item.isAvailable ? AppColors.accent : AppColors.error,
              ),
              ...item.tags.map((t) => _Badge(label: t, color: _tagColor(t))),
            ],
          ),
          const SizedBox(height: 20),

          // Description — no fixed bottom gap; expands with content
          if (item.description.isNotEmpty)
            Text(
              item.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.55,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          const SizedBox(height: 24),

          // Section label
          _ViewSectionLabel(label: 'Details', isDark: isDark),
          const SizedBox(height: 10),

          // Key info card
          _InfoCard(isDark: isDark, children: [
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Price',
              value: 'QAR ${item.price.toStringAsFixed(2)}',
              valueColor: AppColors.primary,
              isDark: isDark,
            ),
            if (item.calories != null) ...[
              _Divider(isDark: isDark),
              _InfoRow(
                icon: Icons.local_fire_department_outlined,
                label: 'Calories',
                value: '${item.calories} kcal',
                isDark: isDark,
              ),
            ],
            _Divider(isDark: isDark),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Prep Time',
              value: '${item.prepMinutes} min',
              isDark: isDark,
            ),
            _Divider(isDark: isDark),
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: item.category,
              isDark: isDark,
            ),
          ]),
          const SizedBox(height: 24),

          // Section label
          _ViewSectionLabel(label: 'Availability', isDark: isDark),
          const SizedBox(height: 10),

          // Availability toggle card
          _InfoCard(isDark: isDark, children: [
            Row(
              children: [
                Icon(
                  item.isAvailable
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 22,
                  color: item.isAvailable ? AppColors.accent : AppColors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isAvailable ? 'Available on menu' : 'Hidden from menu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.isAvailable
                            ? 'Customers can order this item'
                            : 'Item is not shown to customers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: item.isAvailable,
                  onChanged: (_) => context
                      .read<VendorProvider>()
                      .toggleItemAvailability(item.id),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                  inactiveThumbColor: AppColors.error,
                  inactiveTrackColor: AppColors.error.withValues(alpha: 0.2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ]),
          const SizedBox(height: 28),

          // Edit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('Edit Item',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              onPressed: () => setState(() => _editing = true),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit mode — form fields ───────────────────────────────────────────────

  Widget _buildEditForm(MenuItem item, bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 40),
        children: [
          GestureDetector(
            onTap: _showPickerSheet,
            child: _PhotoBox(
                imagePath: _imagePath,
                isDark: isDark,
                editing: true,
                picking: _picking),
          ),
          const SizedBox(height: 24),

          // ── Basic info ────────────────────────────────────────────
          _FormSectionLabel(label: 'Basic Info'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Item Name *'),
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.plusJakartaSans(fontSize: 15),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            minLines: 2,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(fontSize: 15),
          ),
          const SizedBox(height: 28),

          // ── Pricing ───────────────────────────────────────────────
          _FormSectionLabel(label: 'Pricing & Nutrition'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Price *', prefixText: 'QAR '),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(fontSize: 15),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _calsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Calories', suffixText: 'kcal'),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Category ──────────────────────────────────────────────
          _FormSectionLabel(label: 'Category'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 28),

          // ── Tags ─────────────────────────────────────────────────
          _FormSectionLabel(label: 'Tags'),
          const SizedBox(height: 6),
          Text(
            'Select all that apply',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) {
              final selected = _tags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _tags.remove(tag);
                  } else {
                    _tags.add(tag);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── Prep time ─────────────────────────────────────────────
          _FormSectionLabel(label: 'Prep Time'),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('How long does this take to prepare?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_prepMinutes min',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
              ),
            ],
          ),
          Slider(
            value: _prepMinutes.toDouble(),
            min: 1,
            max: 45,
            divisions: 44,
            activeColor: AppColors.primary,
            label: '$_prepMinutes min',
            onChanged: (v) => setState(() => _prepMinutes = v.round()),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    _loadFromItem(_getItem());
                    setState(() => _editing = false);
                  },
                  child: Text('Cancel',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _save,
                  child: Text('Save Changes',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared photo box ──────────────────────────────────────────────────────────

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.imagePath,
    required this.isDark,
    required this.editing,
    this.picking = false,
  });
  final String? imagePath;
  final bool isDark;
  final bool editing;
  final bool picking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: picking
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : imagePath != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(imagePath!), fit: BoxFit.cover),
                    if (editing)
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Change',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        editing
                            ? Icons.add_a_photo_rounded
                            : Icons.fastfood_rounded,
                        color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      editing ? 'Add Photo' : 'No photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: editing ? AppColors.primary : Colors.grey,
                        fontWeight: editing
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (editing) ...[
                      const SizedBox(height: 4),
                      Text('Tap to add',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ],
                ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, required this.isDark});
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              )),
          const Spacer(),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              )),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
  }
}

Color _tagColor(String tag) {
  switch (tag) {
    case 'Featured': return AppColors.primary;
    case 'Top Rated': return const Color(0xFFD97706); // amber
    case 'Best Seller': return const Color(0xFF7C3AED); // violet
    case "Chef's Special": return const Color(0xFFDB2777); // pink
    case 'New': return AppColors.info;
    case 'Spicy': return const Color(0xFFDC2626); // red
    case 'Vegetarian': return AppColors.accent;
    case 'Vegan': return const Color(0xFF16A34A); // deep green
    case 'Gluten Free': return const Color(0xFF0891B2); // cyan
    case 'Halal': return const Color(0xFF059669); // emerald
    default: return Colors.grey;
  }
}

class _ViewSectionLabel extends StatelessWidget {
  const _ViewSectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
