import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_item.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = WalletService();
    final currencyFormat = NumberFormat("#,###", "uz_UZ");

    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.creamBg,
          appBar: AppBar(
            title: const Text("Keshbek Hamyoni"),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detailed Balance Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Jami Yig'ilgan Keshbek",
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${currencyFormat.format(wallet.balance)} so'm",
                        style: const TextStyle(
                          color: AppTheme.primaryEmerald,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showWithdrawDialog(context, wallet),
                              icon: const Icon(Icons.credit_card_rounded),
                              label: const Text("Kartaga Yechib Olish"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Supported Payment Systems
                const Text(
                  "To'lov Tizimlari",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _PaymentBadge(name: "Click", color: Colors.blue),
                    _PaymentBadge(name: "Payme", color: Colors.teal),
                    _PaymentBadge(name: "Uzum Bank", color: Colors.deepPurple),
                    _PaymentBadge(name: "Xayriya", color: Colors.green),
                  ],
                ),
                const SizedBox(height: 28),

                // Full Transaction History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tranzaksiyalar Tarixi",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textDark),
                    ),
                    Text(
                      "${wallet.transactions.length} ta operatsiya",
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...wallet.transactions.map((tx) {
                  final isDeposit = tx.type == TransactionType.deposit;
                  final dateFormat = DateFormat("dd.MM.yyyy, HH:mm");

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDeposit ? AppTheme.primaryEmerald.withValues(alpha: 0.12) : AppTheme.accentRose.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isDeposit ? AppTheme.primaryEmerald : AppTheme.accentRose,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                              const SizedBox(height: 3),
                              Text(dateFormat.format(tx.date), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        Text(
                          "${isDeposit ? '+' : ''}${currencyFormat.format(tx.amount)} so'm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDeposit ? AppTheme.primaryEmerald : AppTheme.accentRose,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWithdrawDialog(BuildContext context, WalletService wallet) {
    int selectedAmount = 5000;
    String selectedSystem = "Uzum Bank";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mablag'ni Kartaga Yechib Olish",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),

                  // System Selector
                  Row(
                    children: ["Uzum Bank", "Click", "Payme"].map((sys) {
                      final isSel = selectedSystem == sys;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedSystem = sys),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primaryEmerald : AppTheme.creamBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isSel ? AppTheme.primaryEmerald : AppTheme.borderLight),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              sys,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : AppTheme.textDark,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Card Number Input
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Karta raqami (8600 yoki 9860)",
                      hintText: "8600 •••• •••• ••••",
                      filled: true,
                      fillColor: AppTheme.creamBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Amount Chips
                  const Text("Summani tanlang:", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [5000, 10000, 20000].map((amt) {
                      final isSel = selectedAmount == amt;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedAmount = amt),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primaryEmerald.withValues(alpha: 0.15) : AppTheme.creamBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? AppTheme.primaryEmerald : AppTheme.borderLight),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$amt so'm",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSel ? AppTheme.primaryEmerald : AppTheme.textDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final ok = wallet.withdraw(selectedAmount, selectedSystem);
                        Navigator.pop(ctx);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$selectedAmount so'm $selectedSystem hisobiga o'tkazildi! ✅")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Balansingizda mablag' yetarli emas!")),
                          );
                        }
                      },
                      child: const Text("O'tkazmani Tasdiqlash"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String name;
  final MaterialColor color;

  const _PaymentBadge({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color[700])),
    );
  }
}
