import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

const _kPresetReasons = [
  'Out of stock',
  'Restaurant too busy',
  'Closing soon',
  'Unable to fulfil order',
];

/// Shows a dialog asking the vendor why they're rejecting/cancelling an order.
/// Returns the chosen reason, or null if the vendor backed out without
/// confirming (the caller should treat null as "do not cancel").
Future<String?> showRejectReasonDialog(BuildContext context) {
  final ctrl = TextEditingController();
  String? selectedPreset;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final reason = (selectedPreset ?? ctrl.text).trim();
        return AlertDialog(
          title: Text('Reject Order', style: GoogleFonts.fredoka(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Let the customer know why — this will be shown to them.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kPresetReasons.map((preset) {
                    final selected = selectedPreset == preset;
                    return ChoiceChip(
                      label: Text(preset, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      selected: selected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      onSelected: (v) => setState(() {
                        selectedPreset = v ? preset : null;
                        if (v) ctrl.clear();
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Or write a custom reason',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() {
                    if (v.isNotEmpty) selectedPreset = null;
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: reason.isEmpty ? null : () => Navigator.pop(ctx, reason),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Reject Order'),
            ),
          ],
        );
      },
    ),
  );
}
