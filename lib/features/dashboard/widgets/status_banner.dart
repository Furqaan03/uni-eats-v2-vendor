import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/vendor_provider.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.vendor});
  final VendorProvider vendor;

  @override
  Widget build(BuildContext context) {
    if (!vendor.isStatusLoaded) {
      return const _StatusBannerSkeleton();
    }

    final isOpen = vendor.isOpen;
    final isBusy = vendor.isBusy;
    final bg = isOpen ? AppColors.primary : const Color(0xFF3A3A3A);
    final borderColor = isOpen
        ? AppColors.primaryLight.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // ── Open / Close row ──────────────────────────────────────────────
          Row(
            children: [
              _PulsingDot(active: isOpen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.isAdminSuspended
                          ? 'Suspended by Admin'
                          : (isOpen ? 'Open for Orders' : 'Restaurant Closed'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vendor.isAdminSuspended
                          ? 'Contact support to lift this suspension'
                          : (isOpen ? 'Accepting new orders' : 'Tap to open and accept orders'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _IosToggle(
                value: isOpen,
                onChanged: vendor.isAdminSuspended ? null : (_) => _confirmOpen(context, vendor),
              ),
            ],
          ),

          // ── Divider ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.15),
              height: 1,
            ),
          ),

          // ── Busy / Not Busy row ───────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isBusy
                      ? AppColors.error
                      : Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBusy ? 'Busy Mode On' : 'Not Busy',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBusy
                          ? 'Customers see longer wait times'
                          : isOpen
                              ? 'Running at normal pace'
                              : 'Open the restaurant first',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Opacity(
                opacity: isOpen ? 1.0 : 0.4,
                child: _IosToggle(
                  value: isBusy,
                  onChanged: isOpen ? (_) => _confirmBusy(context, vendor) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOpen(BuildContext context, VendorProvider vendor) async {
    final isOpen = vendor.isOpen;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isOpen ? 'Close Restaurant?' : 'Open Restaurant?'),
        content: Text(
          isOpen
              ? 'You will stop receiving new orders. Existing orders are not affected.'
              : 'You will start receiving new orders immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isOpen ? AppColors.error : AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isOpen ? 'Yes, Close' : 'Yes, Open'),
          ),
        ],
      ),
    );
    if (ok == true) vendor.toggleOpen();
  }

  Future<void> _confirmBusy(BuildContext context, VendorProvider vendor) async {
    final isBusy = vendor.isBusy;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isBusy ? 'Resume Normal Mode?' : 'Switch to Busy Mode?'),
        content: Text(
          isBusy
              ? 'New orders will come in at normal pace.'
              : 'Orders will still be accepted but customers will see longer wait times.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isBusy ? 'Resume' : 'Go Busy'),
          ),
        ],
      ),
    );
    if (ok == true) vendor.toggleBusy();
  }
}

// ── Loading skeleton shown until the persisted open/busy status loads ───────

class _StatusBannerSkeleton extends StatelessWidget {
  const _StatusBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar({double width = double.infinity, double height = 14}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(width: 100),
                    const SizedBox(height: 6),
                    bar(width: 140, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              bar(width: 72, height: 30),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(width: 90),
                    const SizedBox(height: 6),
                    bar(width: 120, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              bar(width: 72, height: 30),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom iOS-style toggle with ON/OFF label ────────────────────────────────

class _IosToggle extends StatefulWidget {
  const _IosToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<_IosToggle> createState() => _IosToggleState();
}

class _IosToggleState extends State<_IosToggle>
    with SingleTickerProviderStateMixin {
  // Track width is wider to fit label text
  static const _trackW = 72.0;
  static const _trackH = 30.0;
  static const _thumbD = 24.0;
  static const _pad = 3.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.value ? 1.0 : 0.0,
  );

  late final Animation<double> _slide =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  // Green when ON, red when OFF
  late final Animation<Color?> _track = ColorTween(
    begin: const Color(0xFFB71C1C), // dark red
    end: const Color(0xFF1B5E20),   // dark green
  ).animate(_slide);

  @override
  void didUpdateWidget(_IosToggle old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onChanged != null
          ? () => widget.onChanged!(!widget.value)
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          // Thumb travels from left (_pad) to right (_trackW - _pad - _thumbD)
          final travel = _trackW - _pad * 2 - _thumbD;
          final thumbLeft = _pad + _slide.value * travel;

          // Label sits on the opposite side of the thumb
          final isOn = _slide.value > 0.5;

          return Container(
            width: _trackW,
            height: _trackH,
            decoration: BoxDecoration(
              color: _track.value,
              borderRadius: BorderRadius.circular(_trackH / 2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Label — appears on the side opposite to the thumb
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  left: isOn ? _pad + 4 : null,
                  right: isOn ? null : _pad + 4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (_slide.value - 0.5).abs() > 0.2 ? 1.0 : 0.0,
                    child: Text(
                      isOn ? 'ON' : 'OFF',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: _thumbD,
                    height: _thumbD,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Pulsing status dot ───────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.active});
  final bool active;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: Colors.grey, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5 + 0.5 * _controller.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4 * _controller.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
