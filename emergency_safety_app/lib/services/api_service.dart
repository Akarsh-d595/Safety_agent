import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emergency_model.dart';

/// HTTP client for the Emergency Safety FastAPI backend.
///
/// All methods throw [ApiException] on network or server errors so the
/// controller can handle them uniformly.
class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  // ── /analyze ──────────────────────────────────────────────────────────────

  /// Send [text] to the backend for danger analysis.
  Future<EmergencyAnalysis> analyze(String text, {String? userId}) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final body = jsonEncode({'text': text, 'user_id': userId});

    final response = await http
        .post(uri, headers: _headers, body: body)
        .timeout(timeout);

    _checkStatus(response, 'analyze');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return EmergencyAnalysis.fromJson(json);
  }

  // ── /alert ────────────────────────────────────────────────────────────────

  /// Dispatch SMS alerts via the backend.
  Future<Map<String, dynamic>> sendAlert({
    required String message,
    required DangerLevel level,
    double? latitude,
    double? longitude,
    String? userId,
    List<String> contacts = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/alert');
    final body = jsonEncode({
      'message':   message,
      'level':     level.name,
      'latitude':  latitude,
      'longitude': longitude,
      'user_id':   userId,
      'contacts':  contacts,
    });

    final response = await http
        .post(uri, headers: _headers, body: body)
        .timeout(timeout);

    _checkStatus(response, 'alert');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── /incidents ────────────────────────────────────────────────────────────

  /// Log an incident to the backend.
  Future<String> logIncident({
    required String text,
    required DangerLevel level,
    double? latitude,
    double? longitude,
    String? userId,
    bool triggered = false,
  }) async {
    final uri = Uri.parse('$baseUrl/incidents');
    final body = jsonEncode({
      'text':      text,
      'level':     level.name,
      'latitude':  latitude,
      'longitude': longitude,
      'user_id':   userId,
      'triggered': triggered,
    });

    final response = await http
        .post(uri, headers: _headers, body: body)
        .timeout(timeout);

    _checkStatus(response, 'log incident');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['incident_id'] as String;
  }

  /// Fetch incident history from the backend.
  Future<List<IncidentRecord>> fetchIncidents({String? userId}) async {
    final uri = Uri.parse(
      userId != null
          ? '$baseUrl/incidents?user_id=${Uri.encodeComponent(userId)}'
          : '$baseUrl/incidents',
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(timeout);

    _checkStatus(response, 'fetch incidents');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => IncidentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── /health ───────────────────────────────────────────────────────────────

  /// Returns true if the backend is reachable and healthy.
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  void _checkStatus(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Backend $operation failed '
        '(HTTP ${response.statusCode}): ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}

/// Thrown when the backend returns a non-2xx response or is unreachable.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
