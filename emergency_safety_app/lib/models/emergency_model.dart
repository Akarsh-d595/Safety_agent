/// Represents the danger level detected from user input
enum DangerLevel { none, low, medium, high }

/// Represents the current app state
enum AppState { idle, listening, processing, safe, warning, emergency }

/// Result from the emergency detection engine (local or backend)
class EmergencyAnalysis {
  final bool danger;
  final DangerLevel level;
  final String reason;
  final bool trigger;

  const EmergencyAnalysis({
    required this.danger,
    required this.level,
    required this.reason,
    this.trigger = false,
  });

  factory EmergencyAnalysis.safe() => const EmergencyAnalysis(
        danger: false,
        level: DangerLevel.none,
        reason: 'No danger signals detected.',
        trigger: false,
      );

  factory EmergencyAnalysis.fromJson(Map<String, dynamic> json) {
    return EmergencyAnalysis(
      danger:  json['danger']  as bool,
      level:   DangerLevel.values.firstWhere(
                 (e) => e.name == (json['level'] as String),
                 orElse: () => DangerLevel.none,
               ),
      reason:  json['reason']  as String,
      trigger: json['trigger'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'danger':  danger,
        'level':   level.name,
        'reason':  reason,
        'trigger': trigger,
      };

  @override
  String toString() =>
      'EmergencyAnalysis(danger: $danger, level: ${level.name}, trigger: $trigger)';
}

/// Holds GPS coordinates and a shareable Google Maps link
class LocationData {
  final double latitude;
  final double longitude;

  const LocationData({required this.latitude, required this.longitude});

  String get googleMapsLink =>
      'https://www.google.com/maps?q=$latitude,$longitude';

  Map<String, dynamic> toJson() => {
        'latitude':  latitude,
        'longitude': longitude,
      };

  @override
  String toString() => 'LocationData($latitude, $longitude)';
}

/// A stored incident record returned from the backend
class IncidentRecord {
  final String id;
  final DateTime timestamp;
  final String? userId;
  final String text;
  final DangerLevel level;
  final double? latitude;
  final double? longitude;
  final bool triggered;

  const IncidentRecord({
    required this.id,
    required this.timestamp,
    this.userId,
    required this.text,
    required this.level,
    this.latitude,
    this.longitude,
    required this.triggered,
  });

  factory IncidentRecord.fromJson(Map<String, dynamic> json) {
    return IncidentRecord(
      id:        json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId:    json['user_id'] as String?,
      text:      json['text'] as String,
      level:     DangerLevel.values.firstWhere(
                   (e) => e.name == (json['level'] as String),
                   orElse: () => DangerLevel.none,
                 ),
      latitude:  (json['latitude']  as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      triggered: json['triggered'] as bool? ?? false,
    );
  }
}

/// User settings persisted locally
class AppSettings {
  final String backendUrl;
  final String userName;
  final List<String> emergencyContacts; // E.164 phone numbers
  final bool useBackend;

  const AppSettings({
    this.backendUrl      = 'http://10.0.2.2:8000', // Android emulator → localhost
    this.userName        = '',
    this.emergencyContacts = const [],
    this.useBackend      = true,
  });

  AppSettings copyWith({
    String? backendUrl,
    String? userName,
    List<String>? emergencyContacts,
    bool? useBackend,
  }) {
    return AppSettings(
      backendUrl:         backendUrl         ?? this.backendUrl,
      userName:           userName           ?? this.userName,
      emergencyContacts:  emergencyContacts  ?? this.emergencyContacts,
      useBackend:         useBackend         ?? this.useBackend,
    );
  }

  Map<String, dynamic> toJson() => {
        'backendUrl':        backendUrl,
        'userName':          userName,
        'emergencyContacts': emergencyContacts,
        'useBackend':        useBackend,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      backendUrl:        json['backendUrl']  as String?  ?? 'http://10.0.2.2:8000',
      userName:          json['userName']    as String?  ?? '',
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
                             ?.map((e) => e as String)
                             .toList() ??
                         [],
      useBackend:        json['useBackend']  as bool?    ?? true,
    );
  }
}
