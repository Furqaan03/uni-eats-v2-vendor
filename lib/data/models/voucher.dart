enum VoucherType { percentage, flat }

class Voucher {
  Voucher({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderAmount = 0,
    this.isActive = true,
    this.usageCount = 0,
    this.maxUsage,
    this.restaurantId,
  });

  // Mirrors `code` — Firestore's doc ID for this voucher is the code itself
  // (vouchers/{code}, per firestore.rules), so the two are always equal for
  // any voucher that's actually been persisted.
  final String id;
  String code;
  VoucherType type;
  // For percentage: 0–100. For flat: amount in QAR.
  double value;
  double minOrderAmount;
  bool isActive;
  int usageCount;
  int? maxUsage;
  // Which restaurant this code applies to — null only for a voucher that
  // hasn't been saved yet. firestore.rules pins this to the vendor's own
  // restaurantId and makes it immutable after creation.
  String? restaurantId;

  bool get isExpired => maxUsage != null && usageCount >= maxUsage!;

  /// Returns discount amount for a given order subtotal. 0 if not applicable.
  double discountFor(double subtotal) {
    if (!isActive || isExpired) return 0;
    if (subtotal < minOrderAmount) return 0;
    if (type == VoucherType.percentage) {
      return (subtotal * value / 100).clamp(0, subtotal);
    }
    return value.clamp(0, subtotal);
  }

  String get displayValue =>
      type == VoucherType.percentage ? '${value.toInt()}% OFF' : 'QAR ${value.toStringAsFixed(0)} OFF';

  Voucher copyWith({
    String? code,
    VoucherType? type,
    double? value,
    double? minOrderAmount,
    bool? isActive,
    int? usageCount,
    int? maxUsage,
    String? restaurantId,
  }) =>
      Voucher(
        id: id,
        code: code ?? this.code,
        type: type ?? this.type,
        value: value ?? this.value,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        isActive: isActive ?? this.isActive,
        usageCount: usageCount ?? this.usageCount,
        maxUsage: maxUsage ?? this.maxUsage,
        restaurantId: restaurantId ?? this.restaurantId,
      );

  /// Maps to the schema firestore.rules `isValidVoucherDiscount` reads:
  /// type as 'percent'|'flat', minOrderAmount as `min`.
  Map<String, dynamic> toMap() => {
        'type': type == VoucherType.percentage ? 'percent' : 'flat',
        'value': value,
        'min': minOrderAmount,
        'active': isActive,
        'restaurantId': restaurantId,
      };

  factory Voucher.fromMap(String code, Map<String, dynamic> d) => Voucher(
        id: code,
        code: code,
        type: d['type'] == 'percent' ? VoucherType.percentage : VoucherType.flat,
        value: (d['value'] as num?)?.toDouble() ?? 0,
        minOrderAmount: (d['min'] as num?)?.toDouble() ?? 0,
        isActive: d['active'] as bool? ?? true,
        restaurantId: d['restaurantId'] as String?,
      );
}
