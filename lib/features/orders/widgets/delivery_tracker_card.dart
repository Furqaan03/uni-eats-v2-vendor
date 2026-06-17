import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';

// Simulates a driver moving toward the restaurant for delivery orders.
// In a real app this would subscribe to a driver location stream.
class DeliveryTrackerCard extends StatefulWidget {
  const DeliveryTrackerCard({
    super.key,
    required this.order,
    this.compact = false,
  });
  final VendorOrder order;
  final bool compact; // true = no outer container (embedded in OrderCard)

  @override
  State<DeliveryTrackerCard> createState() => _DeliveryTrackerCardState();
}

class _DeliveryTrackerCardState extends State<DeliveryTrackerCard>
    with SingleTickerProviderStateMixin {
  // Mock: driver starts at 0% and moves to 100% over ~2 minutes
  static const _mockDriver = 'Mohammed Al-Rashid';
  static const _mockVehicle = 'Honda PCX · QB 4421';
  static const _totalSeconds = 120;

  late Timer _timer;
  int _elapsed = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _elapsed < _totalSeconds) {
        setState(() => _elapsed += 2);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress => (_elapsed / _totalSeconds).clamp(0.0, 1.0);
  int get _etaSeconds => (_totalSeconds - _elapsed).clamp(0, _totalSeconds);
  bool get _arrived => _elapsed >= _totalSeconds;

  String get _etaLabel {
    if (_arrived) return 'Arrived';
    final m = _etaSeconds ~/ 60;
    final s = _etaSeconds % 60;
    return m > 0 ? '~$m min away' : '~$s sec away';
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _arrived
                        ? AppColors.accent
                        : AppColors.statusNew.withValues(
                            alpha: 0.5 + 0.5 * _pulseController.value),
                    shape: BoxShape.circle,
                    boxShadow: _arrived
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.statusNew.withValues(
                                  alpha: 0.4 * _pulseController.value),
                              blurRadius: 6,
                            )
                          ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _arrived ? 'Driver Arrived' : 'Driver On The Way',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _arrived ? AppColors.accent : AppColors.statusNew,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: (_arrived ? AppColors.accent : AppColors.statusNew)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _etaLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _arrived ? AppColors.accent : AppColors.statusNew,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress route
          _RouteProgress(progress: _progress, arrived: _arrived),
          const SizedBox(height: 14),

          // Driver info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.statusNew.withValues(alpha: 0.15),
                child: Text(
                  _mockDriver[0],
                  style: const TextStyle(
                    color: AppColors.statusNew,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mockDriver,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _mockVehicle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Call / message mock buttons
              _DriverAction(
                icon: Icons.phone_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _DriverAction(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () {},
              ),
            ],
          ),
        ],
    );

    // compact = embedded inside OrderCard, no outer decoration needed
    if (widget.compact) return content;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _arrived
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.statusNew.withValues(alpha: 0.3),
        ),
      ),
      child: content,
    );
  }
}

// ── Animated route progress bar ───────────────────────────────────────────────

class _RouteProgress extends StatelessWidget {
  const _RouteProgress({required this.progress, required this.arrived});
  final double progress;
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    final activeColor = arrived ? AppColors.accent : AppColors.statusNew;

    return Column(
      children: [
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 12, color: activeColor),
                const SizedBox(width: 4),
                Text(
                  'Driver',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Restaurant',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                Icon(Icons.storefront_rounded, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Track
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background track
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Filled track
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Driver dot
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              widthFactor: progress,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delivery_dining_rounded,
                      size: 7, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Percent label
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            arrived
                ? 'Arrived at restaurant'
                : '${(progress * 100).toInt()}% of route completed',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverAction extends StatelessWidget {
  const _DriverAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.statusNew.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.statusNew),
      ),
    );
  }
}
