import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/qr_verifier.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final TextEditingController _testInputController = TextEditingController();
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    _testInputController.dispose();
    super.dispose();
  }

  void _handleQrData(String rawData) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Keshbekni tekshirish va hamyonga qo'shish
    final wallet = WalletService();
    final result = wallet.claimQrCode(rawData);

    if (result.isValid) {
      _showSuccessDialog(result);
    } else {
      _showErrorDialog(result.message);
    }
  }

  void _showSuccessDialog(QrVerificationResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryEmerald, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                "Keshbek Hisobingizga Qo'shildi! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "+${result.amount} so'm",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald),
              ),
              const SizedBox(height: 12),
              Text(
                "${result.bottles} ta plastik baklashka\n${result.cans} ta alyuminiy banka\nStansiya: ${result.machineId ?? 'RVM-001'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Scanner ekranini yopish
                  },
                  child: const Text("Hamyonga O'tish"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.accentRose),
              SizedBox(width: 8),
              Text("Xatolik", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(error, style: const TextStyle(color: AppTheme.textMuted)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isProcessing = false);
              },
              child: const Text("Qayta urinish", style: TextStyle(color: AppTheme.primaryEmerald)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RVM Jonli QR Skaner"),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: _isTorchOn ? Colors.amber : Colors.white),
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Haqiqiy jonli kamera skaneri
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessing) return;
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleQrData(rawValue);
                  break;
                }
              }
            },
          ),

          // 2. Qoraytirilgan overlay va lazer ramka
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryEmerald, width: 3),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryEmerald.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 3. Harakatlanuvchi lazer nuri
          Center(
            child: AnimatedBuilder(
              animation: _laserController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -110 + (_laserController.value * 220)),
                  child: Container(
                    width: 240,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withOpacity(0.9),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Pastki ko'rsatma va qo'lda kiritish tugmasi
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "RVM ekranidagi QR kodni ramka ichiga keltiring",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard_rounded, color: Colors.white70),
                  label: const Text("Kodni qo'lda kiritish / Sinov", style: TextStyle(color: Colors.white70)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "QR Kod Matnini Kiriting",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _testInputController,
                decoration: const InputDecoration(
                  hintText: '{"v":1,"sid":"SES-...","amt":500,...}',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (_testInputController.text.isNotEmpty) {
                      _handleQrData(_testInputController.text.trim());
                    }
                  },
                  child: const Text("Tasdiqlash"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
