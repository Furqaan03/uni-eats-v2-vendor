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
  });

  final String id;
  String code;
  VoucherType type;
  // For percentage: 0–100. For flat: amount in QAR.
  double value;
  double minOrderAmount;
  bool isActive;
  int usageCount;
  int? maxUsage;

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
      );
}
