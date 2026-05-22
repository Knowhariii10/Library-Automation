import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import '../screens/cart/cart_screen.dart';

class IntegratedScanner extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const IntegratedScanner({super.key, required this.onBarcodeScanned});

  @override
  State<IntegratedScanner> createState() => _IntegratedScannerState();
}

class _IntegratedScannerState extends State<IntegratedScanner> {
  final TextEditingController _controller = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isFlashOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 450,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan Book Barcode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Scanner View
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MobileScanner(
                          controller: _scannerController,
                          errorBuilder: (context, error) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Camera Error or Denied',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (kIsWeb)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Please allow camera access and ensure HTTPS',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final String code = barcodes.first.rawValue ?? '';
                              if (code.isNotEmpty) {
                                widget.onBarcodeScanned(code.trim());
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 180,
                          height: 90,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (!kIsWeb)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              iconSize: 18,
                              icon: Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _scannerController.toggleTorch();
                                setState(() => _isFlashOn = !_isFlashOn);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'OR ENTER MANUALLY',
                    style: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'e.g., 9781234567890',
                    labelText: 'Book Barcode',
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text(
                    'VIEW CART',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
