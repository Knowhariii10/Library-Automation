import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_colors.dart';

class PremiumScannerScreen extends StatefulWidget {
  const PremiumScannerScreen({super.key});

  @override
  State<PremiumScannerScreen> createState() => _PremiumScannerScreenState();
}

class _PremiumScannerScreenState extends State<PremiumScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasResult) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _hasResult = true);

        try {
          // Stop camera before navigation to prevent native crashes
          await _scannerController.stop();
        } catch (e) {
          debugPrint('Error stopping scanner: $e');
        }

        if (mounted) {
          Navigator.pop(context, code.trim());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // Dark overlay with transparent center (cutout)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner Area Decorations (Corner lines and animation)
          // Centered absolutely in the screen to match the overlay hole
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // Corner decorations (Rounded Yellow)
                  ...List.generate(4, (index) {
                    final isTop = index < 2;
                    final isLeft = index % 2 == 0;
                    return Positioned(
                      top: isTop ? 0 : null,
                      bottom: !isTop ? 0 : null,
                      left: isLeft ? 0 : null,
                      right: !isLeft ? 0 : null,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border(
                            top: isTop
                                ? BorderSide(color: accentColor, width: 6)
                                : BorderSide.none,
                            bottom: !isTop
                                ? BorderSide(color: accentColor, width: 6)
                                : BorderSide.none,
                            left: isLeft
                                ? BorderSide(color: accentColor, width: 6)
                                : BorderSide.none,
                            right: !isLeft
                                ? BorderSide(color: accentColor, width: 6)
                                : BorderSide.none,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: isTop && isLeft
                                ? const Radius.circular(20)
                                : Radius.zero,
                            topRight: isTop && !isLeft
                                ? const Radius.circular(20)
                                : Radius.zero,
                            bottomLeft: !isTop && isLeft
                                ? const Radius.circular(20)
                                : Radius.zero,
                            bottomRight: !isTop && !isLeft
                                ? const Radius.circular(20)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Scanning animation line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * 240 + 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Scanner overlay UI (Interactive buttons and labels)
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildCircleButton(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context),
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Text(
                        'Scan Book Barcode',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildCircleButton(
                        icon: Icons.flash_on,
                        onTap: () => _scannerController.toggleTorch(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Placeholder to reserve space for the absolutely centered scanner
                const SizedBox(width: 280, height: 280),

                const SizedBox(height: 32),

                // Instructions (Pill Style from Image)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.explore,
                          color: accentColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Align barcode within frame',
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom bar for camera switch
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircleButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => _scannerController.switchCamera(),
                        isDark: isDark,
                        size: 56,
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    double size = 44,
    double iconSize = 22,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
