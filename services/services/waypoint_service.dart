import 'package:geolocator/geolocator.dart';

class Waypoint {
  final String name;
  final double latitude;
  final double longitude;

  Waypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class WaypointService {
  // حساب المسافة المتبقية بال أمتار بين نقطتين
  static double calculateDistance(
    double startLat,
    double startLon,
    double destLat,
    double destLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, destLat, destLon);
  }

  // حساب الاتجاه المطلوب للوصول للنقطة (Bearing)
  static double calculateBearing(
    double startLat,
    double startLon,
    double destLat,
    double destLon,
  ) {
    return Geolocator.bearingBetween(startLat, startLon, destLat, destLon);
  }
}
