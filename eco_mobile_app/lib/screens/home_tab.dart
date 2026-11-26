import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_item.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenWallet;

  const HomeTab({
    super.key,
    required this.onOpenScanner,
    required this.onOpenMap,
    required this.onOpenWallet,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###", "uz_UZ");
    final wallet = WalletService();

    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.creamBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: AppTheme.primaryEmerald,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Xush kelibsiz! 👋",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "EcoProject Talaba",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textDark),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Balance Card (Luxury Emerald Gradient)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Keshbek Balansingiz",
                              style: TextStyle(
                                color: Color(0xFFE6FFFA),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "Faol",
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currencyFormat.format(wallet.balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "so'm",
                              style: TextStyle(
                                color: Color(0xFFA7F3D0),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Topshirilgan idishlar: ${wallet.totalItems} dona",
                              style: const TextStyle(color: Color(0xFFE6FFFA), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            InkWell(
                              onTap: onOpenWallet,
                              child: const Row(
                                children: [
                                  Text(
                                    "Yechib olish",
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.qr_code_scanner_rounded,
                          title: "QR Skaner",
                          subtitle: "Keshbek olish",
                          color: AppTheme.primaryEmerald,
                          onTap: onOpenScanner,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.location_on_rounded,
                          title: "UrDU Xaritasi",
                          subtitle: "Bosh bino oldida",
                          color: AppTheme.accentBlue,
                          onTap: onOpenMap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Eco-Impact Stats
                  const Text(
                    "Sizning Eko-Hissangiz 🌍",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ImpactCard(
                          icon: Icons.cloud_done_rounded,
                          value: "${wallet.co2SavedKg.toStringAsFixed(1)} kg",
                          label: "Tejalgan CO2",
                          iconColor: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ImpactCard(
                          icon: Icons.park_rounded,
                          value: "${wallet.treesSaved.toStringAsFixed(1)} ta",
                          label: "Asralgan daraxt",
                          iconColor: AppTheme.primaryEmerald,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ImpactCard(
                          icon: Icons.delete_sweep_rounded,
                          value: "${wallet.totalBottles} dona",
                          label: "Tozalangan plastik",
                          iconColor: AppTheme.accentAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Oxirgi Harakatlar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenWallet,
                        child: const Text(
                          "Barchasi",
                          style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...wallet.transactions.take(3).map(
                        (tx) => _TransactionRow(tx: tx),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _ImpactCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionItem tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###", "uz_UZ");
    final isDeposit = tx.type == TransactionType.deposit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDeposit ? AppTheme.primaryEmerald.withValues(alpha: 0.12) : AppTheme.accentRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDeposit ? Icons.add_circle_outline_rounded : Icons.north_east_rounded,
              color: isDeposit ? AppTheme.primaryEmerald : AppTheme.accentRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(tx.subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(
            "${isDeposit ? '+' : ''}${currencyFormat.format(tx.amount)} so'm",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDeposit ? AppTheme.primaryEmerald : AppTheme.accentRose,
            ),
          ),
        ],
      ),
    );
  }
}
