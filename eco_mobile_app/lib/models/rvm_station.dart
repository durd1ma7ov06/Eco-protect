enum StationStatus {
  active,      // Faol ishlamoqda
  almostFull,  // Bunkeri deyarli to'lgan
  maintenance, // Texnik xizmatda
}

class RvmStation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final StationStatus status;
  final int fillPercent;
  final double distanceKm;
  final int totalAcceptedBottles;

  const RvmStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.fillPercent,
    required this.distanceKm,
    required this.totalAcceptedBottles,
  });

  String get statusText {
    switch (status) {
      case StationStatus.active:
        return "Faol";
      case StationStatus.almostFull:
        return "Bunkeri to'lish arafasida";
      case StationStatus.maintenance:
        return "Vaqtincha to'xtatilgan";
    }
  }
}
