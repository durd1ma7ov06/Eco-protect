import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import '../models/rvm_station.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with SingleTickerProviderStateMixin {
  // Urganch Davlat Universiteti (UrDU) bosh binosi koordinatalari
  static const double urduLat = 41.55447;
  static const double urduLon = 60.63148;

  int _zoom = 16;
  Offset _panOffset = Offset.zero;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _recenter() {
    setState(() {
      _zoom = 16;
      _panOffset = Offset.zero;
    });
  }

  // Slippy Map Tile hisoblash formulasi (OpenStreetMap standarti)
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final rad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) / 2.0 * (1 << zoom)).floor();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletService();
    final urduStation = wallet.stations.first;

    final centerTileX = _lonToTileX(urduLon, _zoom);
    final centerTileY = _latToTileY(urduLat, _zoom);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: Stack(
        children: [
          // 1. REAL INTERACTIVE OPENSTREETMAP (PAN & ZOOM)
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _panOffset += details.delta;
              });
            },
            child: ClipRect(
              child: Stack(
                children: [
                  // Real OSM Map Tiles Grid (3x3 grid around UrDU)
                  Transform.translate(
                    offset: _panOffset,
                    child: Center(
                      child: SizedBox(
                        width: 256.0 * 3,
                        height: 256.0 * 3,
                        child: Stack(
                          children: [
                            for (int dx = -1; dx <= 1; dx++)
                              for (int dy = -1; dy <= 1; dy++)
                                Positioned(
                                  left: (dx + 1) * 256.0,
                                  top: (dy + 1) * 256.0,
                                  width: 256.0,
                                  height: 256.0,
                                  child: Image.network(
                                    'https://tile.openstreetmap.org/$_zoom/${centerTileX + dx}/${centerTileY + dy}.png',
                                    fit: BoxFit.cover,
                                    headers: const {'User-Agent': 'EcoProjectMobile/1.0'},
                                    errorBuilder: (ctx, err, stack) => Container(
                                      color: const Color(0xFFE2E8F0),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.map_outlined, color: Colors.black26),
                                    ),
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: const Color(0xFFF1F5F0),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryEmerald),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // UrDU Station Live Pulsing Marker at the Center of the Map
                  Transform.translate(
                    offset: _panOffset,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _showStationModal(context, urduStation),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Station Label Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    "UrDU Eko-Stansiyasi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Pulsing Ring & Marker Icon
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryEmerald.withValues(
                                          alpha: 0.3 + (_pulseController.value * 0.4),
                                        ),
                                        blurRadius: 12 + (_pulseController.value * 12),
                                        spreadRadius: 2 + (_pulseController.value * 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.recycling_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. TOP BAR OVERLAY
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryEmerald, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Urganch Davlat Universiteti",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.textDark),
                        ),
                        Text(
                          "Al-Xorazmiy ko'chasi, UrDU bosh binosi",
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.primaryEmerald, size: 12),
                        SizedBox(width: 4),
                        Text(
                          "Faol",
                          style: TextStyle(fontSize: 11, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. RIGHT FLOATING CONTROLS (Zoom & Recenter)
          Positioned(
            right: 20,
            bottom: 230,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    if (_zoom < 18) {
                      setState(() {
                        _zoom++;
                        _panOffset = Offset.zero;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_zoom > 14) {
                      setState(() {
                        _zoom--;
                        _panOffset = Offset.zero;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location_rounded,
                  iconColor: AppTheme.primaryEmerald,
                  onTap: _recenter,
                ),
              ],
            ),
          ),

          // 4. BOTTOM FLOATING STATION CARD
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF047857)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              urduStation.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Urganch shahar, UrDU bosh bino oldida",
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.near_me_rounded, size: 12, color: AppTheme.accentBlue),
                            SizedBox(width: 4),
                            Text(
                              "120 m",
                              style: TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fill Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bunker to'lganligi:",
                        style: TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${urduStation.fillPercent}% (Bo'sh joy yetarli)",
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: urduStation.fillPercent / 100.0,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("UrDU Eko-Stansiyasiga marshrut ochildi!")),
                            );
                          },
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text("Marshrut"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showStationModal(context, urduStation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textDark,
                          side: const BorderSide(color: AppTheme.borderLight),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        label: const Text("Tafsilot"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStationModal(BuildContext context, RvmStation st) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      st.name,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "24/7 Ochiq",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(st.address, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 18),
              const Divider(color: AppTheme.borderLight, height: 1),
              const SizedBox(height: 16),

              const Text("Qabul Qilinadigan Idishlar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: const [
                  _PriceChip(icon: Icons.local_drink_rounded, name: "Plastik Baklashka", price: "100 so'm"),
                  SizedBox(width: 10),
                  _PriceChip(icon: Icons.crop_square_rounded, name: "Alyuminiy Banka", price: "150 so'm"),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tushunarli"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MapButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: iconColor ?? AppTheme.textDark, size: 22),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final String price;

  const _PriceChip({required this.icon, required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.creamBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primaryEmerald),
                const SizedBox(width: 6),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 6),
            Text(price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
          ],
        ),
      ),
    );
  }
}
