import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Wraps the speech_to_text plugin with a clean, testable API.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Initialises the speech engine. Returns true on success.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) => _onError(error.errorMsg),
      onStatus: (status) {
        // 'done' or 'notListening' signals the session ended
        if ((status == 'done' || status == 'notListening') && _onDoneCallback != null) {
          _onDoneCallback!();
          _onDoneCallback = null;
        }
      },
    );
    return _initialized;
  }

  void Function()? _onDoneCallback;

  bool get isAvailable => _initialized;
  bool get isListening => _speech.isListening;

  // ── Listening ──────────────────────────────────────────────────────────────

  /// Starts listening and calls [onResult] with each partial / final result.
  /// Calls [onDone] when the session ends.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) throw Exception('Speech recognition not available on this device.');
    }

    _onDoneCallback = onDone;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stops the current listening session.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancels the current listening session without a result.
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _onError(String message) {
    // Errors are surfaced via the UI controller; log here if needed.
  }
}
