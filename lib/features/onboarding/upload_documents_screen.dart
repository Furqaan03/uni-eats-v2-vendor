import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/registration.dart';
import 'onboarding_widgets.dart';

/// Required onboarding documents. Confirm the exact list with admin; these are
/// the sensible defaults for a campus food vendor.
class _RequiredDoc {
  final String kind;
  final String label;
  const _RequiredDoc(this.kind, this.label);
}

const _requiredDocs = [
  _RequiredDoc('trade_licence', 'Trade Licence / CR'),
  _RequiredDoc('owner_id', 'Owner ID'),
];

/// Screen 5.4 — upload required documents. Client-side type/size checks mirror
/// the Storage rules (which enforce them regardless). Shown for a first
/// submission and for a needs_changes re-upload.
class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key, required this.registration});
  final Registration registration;

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final _picker = ImagePicker();
  final Map<String, RegistrationDocument> _uploaded = {};
  final Set<String> _busy = {};
  bool _submitting = false;
  String? _error;

  bool get _allUploaded => _requiredDocs.every((d) => _uploaded.containsKey(d.kind));

  Future<void> _pick(_RequiredDoc doc) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final prov = context.read<OnboardingProvider>();
    setState(() {
      _busy.add(doc.kind);
      _error = null;
    });
    final result = await prov.uploadDocument(kind: doc.kind, file: File(picked.path));
    if (!mounted) return;
    setState(() {
      _busy.remove(doc.kind);
      if (result != null) {
        _uploaded[doc.kind] = result;
      } else {
        _error = prov.error;
      }
    });
  }

  Future<void> _submit() async {
    if (!_allUploaded) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err =
        await context.read<OnboardingProvider>().submitDocuments(_uploaded.values.toList());
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    final needsChanges = widget.registration.status == RegistrationStatus.needsChanges;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepHeader(
                step: 3,
                total: 4,
                title: 'Upload your documents',
                subtitle: 'A clear photo of each document. JPG, PNG or PDF, up to 5 MB.',
              ),
              if (needsChanges && widget.registration.adminNote.isNotEmpty) ...[
                const SizedBox(height: 20),
                _NoteBanner(note: widget.registration.adminNote),
              ],
              const SizedBox(height: 24),
              ..._requiredDocs.map((d) => _DocTile(
                    label: d.label,
                    uploaded: _uploaded.containsKey(d.kind),
                    busy: _busy.contains(d.kind),
                    onTap: () => _pick(d),
                  )),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 28),
              OnboardingPrimaryButton(
                label: 'Submit for review',
                loading: _submitting,
                onPressed: _allUploaded ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.label,
    required this.uploaded,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final bool uploaded;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: uploaded ? AppColors.success : c.border),
          ),
          child: Row(
            children: [
              Icon(
                uploaded ? Icons.check_circle : Icons.upload_file_outlined,
                color: uploaded ? AppColors.success : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (busy)
                const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Text(uploaded ? 'Replace' : 'Upload',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Action needed',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: OnboardingColors.of(context).textPrimary)),
        ],
      ),
    );
  }
}
