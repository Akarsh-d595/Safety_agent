import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_model.dart';

/// Handles outbound emergency actions:
///  - Composing the alert message
///  - Simulating / sending WhatsApp alert
///  - Initiating a phone call to 112
class AlertService {
  static const String _emergencyNumber = '112';

  // ── Message builder ────────────────────────────────────────────────────────

  /// Builds the standard emergency alert message.
  String buildAlertMessage(LocationData location, {String? userName}) {
    final namePrefix = userName != null ? 'This is $userName. ' : '';
    return '🚨 EMERGENCY ALERT 🚨\n'
        '${namePrefix}I may be in danger. '
        'Track my location:\n'
        '${location.googleMapsLink}';
  }

  // ── WhatsApp alert (simulated / API-ready) ─────────────────────────────────

  /// Opens WhatsApp with a pre-filled emergency message to [phoneNumber].
  /// [phoneNumber] must be in international format without '+' (e.g. 919876543210).
  ///
  /// In production replace this with your backend API call so the message
  /// is sent silently without user interaction.
  Future<bool> sendWhatsAppAlert({
    required String phoneNumber,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ── Phone call ─────────────────────────────────────────────────────────────

  /// Initiates a direct phone call to [_emergencyNumber] (112).
  Future<bool> callEmergencyServices() async {
    final uri = Uri.parse('tel:$_emergencyNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  // ── SMS fallback ───────────────────────────────────────────────────────────

  /// Opens the SMS app with a pre-filled message to [phoneNumber].
  Future<bool> sendSmsAlert({
    required String phoneNumber,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phoneNumber?body=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }
}
