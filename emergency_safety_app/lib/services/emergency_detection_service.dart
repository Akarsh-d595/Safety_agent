import '../models/emergency_model.dart';

/// Analyses text input and returns an [EmergencyAnalysis].
/// This is the local AI detection engine — swap the body of [analyze]
/// with an HTTP call to your backend when ready.
class EmergencyDetectionService {
  // ── Signal dictionaries ────────────────────────────────────────────────────

  static const List<String> _highSignals = [
    'save me',
    'help me',
    'i\'m being attacked',
    'i\'m being hurt',
    'someone is hurting me',
    'call 911',
    'call the police',
    'i\'m going to die',
    'he has a weapon',
    'she has a weapon',
    'they have a gun',
    'they have a knife',
    'he has a knife',
    'he has a gun',
    'i am in danger',
    'i\'m in danger',
  ];

  static const List<String> _mediumSignals = [
    'help',
    'emergency',
    'i need help',
    'someone is following me',
    'i\'m being followed',
    'i am being followed',
    'i think someone is following me',
    'i feel unsafe',
    'i\'m scared',
    'i am scared',
    'i\'m not safe',
    'i am not safe',
  ];

  static const List<String> _lowSignals = [
    'i\'m a little worried',
    'i am a little worried',
    'something feels wrong',
    'this seems suspicious',
    'i\'m not sure if i\'m safe',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Analyse [input] and return an [EmergencyAnalysis].
  EmergencyAnalysis analyze(String input) {
    final text = input.toLowerCase().trim();

    for (final signal in _highSignals) {
      if (text.contains(signal)) {
        return EmergencyAnalysis(
          danger: true,
          level: DangerLevel.high,
          reason: 'High-danger phrase detected: "$signal"',
        );
      }
    }

    for (final signal in _mediumSignals) {
      if (text.contains(signal)) {
        return EmergencyAnalysis(
          danger: true,
          level: DangerLevel.medium,
          reason: 'Danger phrase detected: "$signal"',
        );
      }
    }

    for (final signal in _lowSignals) {
      if (text.contains(signal)) {
        return EmergencyAnalysis(
          danger: true,
          level: DangerLevel.low,
          reason: 'Potential concern detected: "$signal"',
        );
      }
    }

    return EmergencyAnalysis.safe();
  }
}
