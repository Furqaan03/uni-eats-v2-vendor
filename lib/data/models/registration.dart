import 'package:cloud_firestore/cloud_firestore.dart';

/// Application status — mirrored as the `vendorStatus` custom claim on approval.
enum RegistrationStatus { pending, needsChanges, approved, rejected }

extension RegistrationStatusX on RegistrationStatus {
  /// The wire value stored on the doc / claim (snake_case, matches functions).
  String get wire => switch (this) {
        RegistrationStatus.pending => 'pending',
        RegistrationStatus.needsChanges => 'needs_changes',
        RegistrationStatus.approved => 'approved',
        RegistrationStatus.rejected => 'rejected',
      };

  static RegistrationStatus fromWire(String? v) => switch (v) {
        'needs_changes' => RegistrationStatus.needsChanges,
        'approved' => RegistrationStatus.approved,
        'rejected' => RegistrationStatus.rejected,
        _ => RegistrationStatus.pending,
      };
}

/// Fixed vendor role — replaces the old free-text role. Maps to the
/// `vendorRole` claim and the multi-branch RBAC model.
enum VendorRole { vendorAdmin, branchManager, staff }

extension VendorRoleX on VendorRole {
  String get wire => switch (this) {
        VendorRole.vendorAdmin => 'vendor_admin',
        VendorRole.branchManager => 'branch_manager',
        VendorRole.staff => 'staff',
      };

  String get label => switch (this) {
        VendorRole.vendorAdmin => 'Owner / Vendor Admin',
        VendorRole.branchManager => 'Branch Manager',
        VendorRole.staff => 'Staff',
      };

  static VendorRole fromWire(String? v) => switch (v) {
        'branch_manager' => VendorRole.branchManager,
        'staff' => VendorRole.staff,
        _ => VendorRole.vendorAdmin,
      };
}

/// One uploaded onboarding document (trade licence / CR, etc.).
class RegistrationDocument {
  const RegistrationDocument({
    required this.kind,
    required this.storagePath,
    this.uploadedAt,
  });

  final String kind;
  final String storagePath;
  final DateTime? uploadedAt;

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'storagePath': storagePath,
        'uploadedAt': uploadedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(uploadedAt!),
      };

  factory RegistrationDocument.fromMap(Map<String, dynamic> m) => RegistrationDocument(
        kind: m['kind'] as String? ?? '',
        storagePath: m['storagePath'] as String? ?? '',
        uploadedAt: (m['uploadedAt'] as Timestamp?)?.toDate(),
      );
}

/// A vendor onboarding application (`registrations/{docId}`). Read-only mirror
/// of the Firestore doc — claim state is the source of truth for access; this
/// drives the onboarding UI (confirm details, upload, status).
class Registration {
  const Registration({
    required this.id,
    required this.status,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.outletId,
    required this.outletName,
    required this.location,
    required this.role,
    required this.documents,
    required this.detailsConfirmed,
    required this.passwordSet,
    this.branchId,
    this.uid,
    this.invitedByRepId,
    this.adminNote = '',
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final RegistrationStatus status;
  final String contactName;
  final String email;
  final String phone;
  final String outletId;
  final String outletName;
  final String? branchId;
  final String location;
  final VendorRole role;
  final List<RegistrationDocument> documents;
  final bool detailsConfirmed;
  final bool passwordSet;
  final String? uid;
  final String? invitedByRepId;
  final String adminNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  bool get isRepInvited => (invitedByRepId ?? '').isNotEmpty;

  factory Registration.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Registration(
      id: doc.id,
      status: RegistrationStatusX.fromWire(d['status'] as String?),
      contactName: d['contactName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      outletId: d['outletId'] as String? ?? '',
      outletName: d['outletName'] as String? ?? '',
      branchId: d['branchId'] as String?,
      location: d['location'] as String? ?? '',
      role: VendorRoleX.fromWire(d['role'] as String?),
      documents: (d['documents'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RegistrationDocument.fromMap)
              .toList() ??
          const [],
      detailsConfirmed: d['detailsConfirmed'] as bool? ?? false,
      passwordSet: d['passwordSet'] as bool? ?? false,
      uid: d['uid'] as String?,
      invitedByRepId: d['invitedByRepId'] as String?,
      adminNote: d['adminNote'] as String? ?? '',
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }
}
