import 'package:geolocator/geolocator.dart';
import '../models/emergency_model.dart';

/// Handles GPS location fetching with full permission management.
class LocationService {
  /// Requests permissions if needed, then returns the current [LocationData].
  /// Throws a descriptive [Exception] on failure.
  Future<LocationData> getCurrentLocation() async {
    // 1. Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS in device settings.',
      );
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied by user.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
        'Please enable it in app settings.',
      );
    }

    // 3. Fetch position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
