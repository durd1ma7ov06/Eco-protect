import 'package:flutter/foundation.dart';
import '../models/transaction_item.dart';
import '../models/rvm_station.dart';
import '../core/utils/qr_verifier.dart';

class WalletService extends ChangeNotifier {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal() {
    _initInitialData();
  }

  int _balance = 8500;
  int _totalBottles = 65;
  int _totalCans = 14;

  int get balance => _balance;
  int get totalBottles => _totalBottles;
  int get totalCans => _totalCans;
  int get totalItems => _totalBottles + _totalCans;

  double get co2SavedKg => (_totalBottles * 0.085) + (_totalCans * 0.12);
  double get treesSaved => (_totalBottles + _totalCans) / 100.0;

  final List<TransactionItem> _transactions = [];
  List<TransactionItem> get transactions => List.unmodifiable(_transactions);

  final List<RvmStation> _stations = [];
  List<RvmStation> get stations => List.unmodifiable(_stations);

  void _initInitialData() {
    // Dastlabki UrDU tranzaksiyalari
    _transactions.addAll([
      TransactionItem(
        id: "TX-101",
        title: "UrDU Bosh Binosi Stansiyasi",
        subtitle: "3 ta baklashka, 1 ta banka",
        bottles: 3,
        cans: 1,
        amount: 450,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.deposit,
      ),
      TransactionItem(
        id: "TX-100",
        title: "UrDU Eko-Stansiyasi",
        subtitle: "5 ta baklashka",
        bottles: 5,
        cans: 0,
        amount: 500,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.deposit,
      ),
    ]);

    // Hozircha faqat 1 ta stansiya: UrDU (Urganch Davlat Universiteti) oldida
    _stations.add(
      const RvmStation(
        id: "ECOPROJECT-URDU-001",
        name: "UrDU Bosh Binosi Eko-Stansiyasi",
        address: "Urganch shahri, Al-Xorazmiy ko'chasi, UrDU bosh binosi oldida",
        latitude: 41.5545,
        longitude: 60.6315,
        status: StationStatus.active,
        fillPercent: 28,
        distanceKm: 0.1,
        totalAcceptedBottles: 1240,
      ),
    );
  }

  // QR Kodni skaner qilib hisobga keshbek yozish
  QrVerificationResult claimQrCode(String rawQrData) {
    final result = QrSecurityVerifier.verifyAndParse(rawQrData);
    if (result.isValid) {
      _balance += result.amount;
      _totalBottles += result.bottles;
      _totalCans += result.cans;

      _transactions.insert(
        0,
        TransactionItem(
          id: "TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
          sessionId: result.sessionId,
          title: "UrDU Eko-Stansiyasi",
          subtitle: "${result.bottles} ta baklashka, ${result.cans} ta banka",
          bottles: result.bottles,
          cans: result.cans,
          amount: result.amount,
          date: DateTime.now(),
          type: TransactionType.deposit,
        ),
      );
      notifyListeners();
    }
    return result;
  }

  // Mablag'ni kartaga chiqarish (Click / Payme / Uzum)
  bool withdraw(int amount, String destination) {
    if (amount <= 0 || amount > _balance) return false;
    _balance -= amount;
    _transactions.insert(
      0,
      TransactionItem(
        id: "TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
        title: "$destination hisobiga yechildi",
        subtitle: "Keshbek o'tkazmasi",
        amount: -amount,
        date: DateTime.now(),
        type: TransactionType.withdraw,
      ),
    );
    notifyListeners();
    return true;
  }
}
