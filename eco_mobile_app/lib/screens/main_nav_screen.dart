import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'map_tab.dart';
import 'wallet_tab.dart';
import 'qr_scanner_screen.dart';
import '../core/theme/app_theme.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        onOpenScanner: _openScanner,
        onOpenMap: () => setState(() => _currentIndex = 1),
        onOpenWallet: () => setState(() => _currentIndex = 2),
      ),
      const MapTab(),
      const WalletTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primaryEmerald.withValues(alpha: 0.15),
          onDestinationSelected: (idx) {
            setState(() => _currentIndex = idx);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryEmerald),
              label: "Bosh sahifa",
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppTheme.primaryEmerald),
              label: "UrDU Xaritasi",
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryEmerald),
              label: "Hamyon",
            ),
          ],
        ),
      ),
    );
  }
}
