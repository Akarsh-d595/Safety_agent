import 'package:permission_handler/permission_handler.dart';

/// Centralises all runtime permission requests.
class PermissionService {
  /// Requests microphone, location, and phone permissions in one call.
  /// Returns a map of [Permission] → [PermissionStatus].
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.microphone,
      Permission.location,
      Permission.phone,
    ].request();
  }

  /// Returns true if microphone permission is granted.
  Future<bool> get isMicrophoneGranted async =>
      await Permission.microphone.isGranted;

  /// Returns true if location permission is granted.
  Future<bool> get isLocationGranted async =>
      await Permission.location.isGranted;

  /// Returns true if phone permission is granted.
  Future<bool> get isPhoneGranted async => await Permission.phone.isGranted;

  /// Opens the app settings screen so the user can manually grant permissions.
  Future<void> openSettings() async => await openAppSettings();

  /// Returns a human-readable summary of which permissions are missing.
  Future<String?> getMissingPermissionMessage() async {
    final statuses = await [
      Permission.microphone,
      Permission.location,
      Permission.phone,
    ].request();

    final denied = <String>[];
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      denied.add('Microphone');
    }
    if (statuses[Permission.location] != PermissionStatus.granted) {
      denied.add('Location');
    }
    if (statuses[Permission.phone] != PermissionStatus.granted) {
      denied.add('Phone');
    }

    if (denied.isEmpty) return null;
    return '${denied.join(', ')} permission(s) denied. '
        'Some features may not work correctly.';
  }
}
