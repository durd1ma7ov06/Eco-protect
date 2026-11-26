import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrVerificationResult {
  final bool isValid;
  final String message;
  final String? sessionId;
  final String? machineId;
  final int bottles;
  final int cans;
  final int amount;

  QrVerificationResult({
    required this.isValid,
    required this.message,
    this.sessionId,
    this.machineId,
    this.bottles = 0,
    this.cans = 0,
    this.amount = 0,
  });
}

class QrSecurityVerifier {
  // Python RVM stansiyasidagi SECRET_KEY bilan bir xil bo'lishi kerak
  static const String secretKey = "super_secret_rvm_hmac_key_2026_change_in_prod";
  
  // Bir martalik ishlatilgan sessiyalarni xotirada saqlash (Anti-Double Spend)
  static final Set<String> _claimedSessions = {};

  static QrVerificationResult verifyAndParse(String qrRawString) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrRawString);
      
      final String sessionId = data['sid'] ?? '';
      final String machineId = data['mid'] ?? '';
      final int bottles = data['b'] ?? 0;
      final int cans = data['c'] ?? 0;
      final int amount = data['amt'] ?? 0;
      final int timestamp = data['ts'] ?? 0;
      final int expiresAt = data['exp'] ?? 0;
      final String claimedSig = data['sig'] ?? '';

      if (sessionId.isEmpty || claimedSig.isEmpty) {
        return QrVerificationResult(
          isValid: false,
          message: "Noto'g'ri QR kod formati!",
        );
      }

      // 1. Bir martalik ishlatilganlikni tekshirish
      if (_claimedSessions.contains(sessionId)) {
        return QrVerificationResult(
          isValid: false,
          message: "Ushbu QR koddan oldin foydalanilgan (Bir martalik)!",
        );
      }

      // 2. Muddatni tekshirish (Unix timestamp)
      final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSec > expiresAt) {
        return QrVerificationResult(
          isValid: false,
          message: "QR kod muddati tugagan (90 soniyadan oshgan)!",
        );
      }

      // 3. HMAC-SHA256 raqamli imzoni tekshirish
      final String rawData = "$sessionId:$machineId:$bottles:$cans:$amount:$timestamp:$expiresAt";
      final Hmac hmac = Hmac(sha256, utf8.encode(secretKey));
      final Digest expectedDigest = hmac.convert(utf8.encode(rawData));
      final String expectedSig = expectedDigest.toString();

      if (expectedSig.toLowerCase() != claimedSig.toLowerCase()) {
        return QrVerificationResult(
          isValid: false,
          message: "Soxta QR kod! Raqamli imzo mos kelmadi.",
        );
      }

      // Barcha tekshiruvlar muvaffaqiyatli
      _claimedSessions.add(sessionId);

      return QrVerificationResult(
        isValid: true,
        message: "Muvaffaqiyatli tasdiqlandi!",
        sessionId: sessionId,
        machineId: machineId,
        bottles: bottles,
        cans: cans,
        amount: amount,
      );
    } catch (e) {
      return QrVerificationResult(
        isValid: false,
        message: "QR kodni o'qishda xatolik: ${e.toString()}",
      );
    }
  }
}
