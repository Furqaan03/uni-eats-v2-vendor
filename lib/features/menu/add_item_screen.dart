import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vendor_provider.dart';
import '../../data/models/menu_item.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _calsCtrl = TextEditingController();
  String _category = 'Mains';
  int _prepMinutes = 10;
  String? _imagePath;
  bool _picking = false;
  final List<String> _tags = [];

  static const _categories = [
    'Starters', 'Mains', 'Food', 'Bowls', 'Noodles', 'Healthy',
    'Coffee', 'Cold Drinks', 'Drinks', 'Bakery', 'Desserts', 'Snacks',
  ];

  static const _allTags = [
    'Featured', 'Top Rated', 'Best Seller', "Chef's Special", 'New',
    'Spicy', 'Vegetarian', 'Vegan', 'Gluten Free', 'Halal',
  ];

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
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imagePath = picked.path);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryTintLight,
                child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: Text('Choose from gallery',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final vendor = context.read<VendorProvider>();
    final item = MenuItem(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      category: _category,
      prepMinutes: _prepMinutes,
      calories: _calsCtrl.text.isEmpty ? null : int.tryParse(_calsCtrl.text),
      imagePath: _imagePath,
      tags: _tags,
    );
    vendor.addMenuItem(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Menu Item'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                )),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenInsets.copyWith(top: 16, bottom: 40),
          children: [
            // ── Photo picker ──────────────────────────────────────────
            GestureDetector(
              onTap: _showPickerSheet,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: _imagePath == null ? 1.5 : 0,
                    style: _imagePath == null ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: _picking
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2))
                    : _imagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
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
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(height: 10),
                              Text('Add Item Photo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  )),
                              const SizedBox(height: 4),
                              Text('Tap to take a photo or pick from gallery',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: theme.colorScheme.outline,
                                  )),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Item name ─────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── Description ───────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),

            // ── Price + Calories ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Price *', prefixText: 'QAR '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    decoration:
                        const InputDecoration(labelText: 'Calories', suffixText: 'kcal'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Category ──────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),

            // ── Tags ─────────────────────────────────────────────────
            Text('Tags',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Select all that apply',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.grey)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
            const SizedBox(height: 20),

            // ── Prep time ─────────────────────────────────────────────
            Row(
              children: [
                Text('Prep Time',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$_prepMinutes min',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
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

            // ── Submit ────────────────────────────────────────────────
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submit,
              child: Text('Add Item',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
