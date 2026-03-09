import 'dart:math';

/// Utilitaires pour les calculs de localisation GPS
class LocationUtils {
  /// Rayon de la Terre en mètres
  static const double earthRadius = 6371000;

  /// Calcule la distance entre deux points GPS en utilisant la formule Haversine
  /// Retourne la distance en mètres
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convertit des degrés en radians
  static double _toRadians(double degrees) => degrees * (pi / 180);

  /// Vérifie si un point GPS est dans le rayon d'un lieu
  /// Retourne true si la distance est inférieure ou égale au rayon
  static bool isWithinRadius({
    required double pointLat,
    required double pointLon,
    required double locationLat,
    required double locationLon,
    required double radius,
  }) {
    final distance = calculateDistance(
      pointLat,
      pointLon,
      locationLat,
      locationLon,
    );
    return distance <= radius;
  }

  /// Formate la distance en mètres en texte lisible
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }
}
