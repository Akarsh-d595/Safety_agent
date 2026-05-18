import 'package:flutter/foundation.dart';
import '../models/emergency_model.dart';
import '../services/emergency_detection_service.dart';
import '../services/location_service.dart';
import '../services/alert_service.dart';
import '../services/speech_service.dart';
import '../services/permission_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';

/// Central controller — drives the entire safety pipeline.
/// Extends [ChangeNotifier] so the UI rebuilds on state changes.
class SafetyController extends ChangeNotifier {
  // ── Services ───────────────────────────────────────────────────────────────
  final EmergencyDetectionService _localDetector = EmergencyDetectionService();
  final LocationService           _locationService  = LocationService();
  final AlertService              _alertService     = AlertService();
  final SpeechService             _speechService    = SpeechService();
  final PermissionService         _permissionService = PermissionService();
  final SettingsService           _settingsService  = SettingsService();

  late ApiService _apiService;

  /// Exposed so screens can call alert actions directly (e.g. call 112).
  AlertService get alertService => _alertService;

  // ── State ──────────────────────────────────────────────────────────────────
  AppState          _appState       = AppState.idle;
  String            _recognizedText = '';
  String            _statusMessage  = 'Tap the microphone to start';
  EmergencyAnalysis? _lastAnalysis;
  LocationData?     _lastLocation;
  String?           _errorMessage;
  bool              _isProcessing   = false;
  AppSettings       _settings       = const AppSettings();
  bool              _backendOnline  = false;
  List<IncidentRecord> _incidents   = [];

  // ── Getters ────────────────────────────────────────────────────────────────
  AppState          get appState       => _appState;
  String            get recognizedText => _recognizedText;
  String            get statusMessage  => _statusMessage;
  EmergencyAnalysis? get lastAnalysis  => _lastAnalysis;
  LocationData?     get lastLocation   => _lastLocation;
  String?           get errorMessage   => _errorMessage;
  bool              get isProcessing   => _isProcessing;
  bool              get isListening    => _speechService.isListening;
  AppSettings       get settings       => _settings;
  bool              get backendOnline  => _backendOnline;
  List<IncidentRecord> get incidents   => List.unmodifiable(_incidents);

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Load persisted settings first
    _settings = await _settingsService.load();
    _apiService = ApiService(baseUrl: _settings.backendUrl);

    // Request permissions
    final permMsg = await _permissionService.getMissingPermissionMessage();
    if (permMsg != null) _setError(permMsg);

    // Init speech
    await _speechService.initialize();

    // Probe backend
    _backendOnline = await _apiService.checkHealth();

    notifyListeners();
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    _apiService = ApiService(baseUrl: newSettings.backendUrl);
    await _settingsService.save(newSettings);
    _backendOnline = await _apiService.checkHealth();
    notifyListeners();
  }

  // ── Voice input ────────────────────────────────────────────────────────────

  Future<void> startListening() async {
    _clearError();
    _recognizedText = '';
    _setState(AppState.listening, 'Listening...');

    try {
      await _speechService.startListening(
        onResult: (text, isFinal) {
          _recognizedText = text;
          notifyListeners();
          if (isFinal && text.isNotEmpty) {
            _processInput(text);
          }
        },
        onDone: () {
          if (_appState == AppState.listening) {
            _setState(AppState.idle, 'Tap the microphone to start');
          }
        },
      );
    } catch (e) {
      _setError('Speech recognition failed: ${e.toString()}');
      _setState(AppState.idle, 'Tap the microphone to start');
    }
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    if (_appState == AppState.listening) {
      _setState(AppState.idle, 'Tap the microphone to start');
    }
  }

  // ── Text input ─────────────────────────────────────────────────────────────

  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;
    _recognizedText = text;
    notifyListeners();
    await _processInput(text);
  }

  // ── Core pipeline ──────────────────────────────────────────────────────────

  Future<void> _processInput(String input) async {
    if (_isProcessing) return;

    _setState(AppState.processing, 'Analysing...');
    _isProcessing = true;
    notifyListeners();

    try {
      // Step 1: Detect danger — backend preferred, local fallback
      final EmergencyAnalysis analysis;
      if (_settings.useBackend && _backendOnline) {
        try {
          analysis = await _apiService.analyze(
            input,
            userId: _settings.userName.isNotEmpty ? _settings.userName : null,
          );
        } catch (e) {
          // Backend unreachable — fall back to local
          _backendOnline = false;
          analysis = _localDetector.analyze(input);
        }
      } else {
        analysis = _localDetector.analyze(input);
      }

      _lastAnalysis = analysis;

      // Step 2: Route by danger level
      switch (analysis.level) {
        case DangerLevel.high:
          await _handleHighDanger(analysis, input);
          break;
        case DangerLevel.medium:
          _handleMediumDanger(analysis);
          break;
        case DangerLevel.low:
        case DangerLevel.none:
          _handleSafe();
          break;
      }
    } catch (e) {
      _setError('Processing error: ${e.toString()}');
      _setState(AppState.idle, 'Tap the microphone to start');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ── Danger handlers ────────────────────────────────────────────────────────

  Future<void> _handleHighDanger(EmergencyAnalysis analysis, String input) async {
    _setState(AppState.emergency, 'Emergency detected! Activating protocol...');

    // Fetch GPS
    try {
      _lastLocation = await _locationService.getCurrentLocation();
    } catch (e) {
      _setError('Location unavailable: ${e.toString()}');
    }

    // Build alert message
    final message = _alertService.buildAlertMessage(
      _lastLocation ?? const LocationData(latitude: 0.0, longitude: 0.0),
      userName: _settings.userName.isNotEmpty ? _settings.userName : null,
    );

    // Send alerts via backend (SMS) if online
    if (_settings.useBackend && _backendOnline) {
      try {
        await _apiService.sendAlert(
          message:   message,
          level:     DangerLevel.high,
          latitude:  _lastLocation?.latitude,
          longitude: _lastLocation?.longitude,
          userId:    _settings.userName.isNotEmpty ? _settings.userName : null,
          contacts:  _settings.emergencyContacts,
        );
      } catch (e) {
        // Fall back to WhatsApp/SMS via url_launcher
        await _sendLocalAlerts(message);
      }
    } else {
      await _sendLocalAlerts(message);
    }

    // Log incident to backend
    if (_settings.useBackend && _backendOnline) {
      try {
        await _apiService.logIncident(
          text:      input,
          level:     DangerLevel.high,
          latitude:  _lastLocation?.latitude,
          longitude: _lastLocation?.longitude,
          userId:    _settings.userName.isNotEmpty ? _settings.userName : null,
          triggered: true,
        );
      } catch (_) {/* non-critical */}
    }

    // Initiate call to 112
    final called = await _alertService.callEmergencyServices();
    if (!called) {
      _setError('Could not initiate call to 112. Please call manually.');
    }

    _setState(AppState.emergency, 'Emergency Activated. Help is being contacted.');
  }

  Future<void> _sendLocalAlerts(String message) async {
    for (final contact in _settings.emergencyContacts) {
      await _alertService.sendWhatsAppAlert(
        phoneNumber: contact.replaceAll('+', ''),
        message: message,
      );
    }
    // If no contacts configured, open WhatsApp with a placeholder
    if (_settings.emergencyContacts.isEmpty) {
      await _alertService.sendWhatsAppAlert(
        phoneNumber: '911234567890',
        message: message,
      );
    }
  }

  void _handleMediumDanger(EmergencyAnalysis analysis) {
    _setState(AppState.warning, 'Potential danger detected. Please confirm.');
  }

  void _handleSafe() {
    _setState(AppState.safe, 'You appear safe. Say "I am in danger" if you need help.');
  }

  // ── Manual emergency trigger ───────────────────────────────────────────────

  Future<void> confirmEmergency() async {
    final analysis = EmergencyAnalysis(
      danger:  true,
      level:   DangerLevel.high,
      reason:  'User manually confirmed emergency.',
      trigger: true,
    );
    _lastAnalysis = analysis;
    await _handleHighDanger(analysis, 'User manually confirmed emergency.');
  }

  void dismissWarning() {
    _setState(AppState.safe, 'Dismissed. Stay safe.');
  }

  // ── Incident history ───────────────────────────────────────────────────────

  Future<void> loadIncidents() async {
    if (!_settings.useBackend || !_backendOnline) return;
    try {
      _incidents = await _apiService.fetchIncidents(
        userId: _settings.userName.isNotEmpty ? _settings.userName : null,
      );
      notifyListeners();
    } catch (_) {/* non-critical */}
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void reset() {
    _appState       = AppState.idle;
    _recognizedText = '';
    _statusMessage  = 'Tap the microphone to start';
    _lastAnalysis   = null;
    _lastLocation   = null;
    _errorMessage   = null;
    _isProcessing   = false;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(AppState state, String message) {
    _appState      = state;
    _statusMessage = message;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
