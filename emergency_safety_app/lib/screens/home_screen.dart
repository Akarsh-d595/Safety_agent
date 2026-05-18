import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/safety_controller.dart';
import '../models/emergency_model.dart';
import '../widgets/mic_button.dart';
import '../widgets/status_indicator.dart';
import '../widgets/warning_dialog.dart';
import 'emergency_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _warningDialogShown = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── State change listener ──────────────────────────────────────────────────

  void _onStateChanged(SafetyController controller) {
    if (!mounted) return;
    final state = controller.appState;

    // Navigate to emergency screen (guard against duplicate pushes)
    if (state == AppState.emergency) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmergencyScreen()),
        );
      }
      return;
    }

    // Show warning dialog once per warning event
    if (state == AppState.warning && !_warningDialogShown) {
      _warningDialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WarningDialog(
          onConfirm: () {
            Navigator.of(context).pop();
            controller.confirmEmergency();
          },
          onDismiss: () {
            Navigator.of(context).pop();
            _warningDialogShown = false;
            controller.dismissWarning();
          },
        ),
      );
    }

    if (state != AppState.warning) {
      _warningDialogShown = false;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetyController>(
      builder: (context, controller, _) {
        // React to state changes after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onStateChanged(controller);
        });

        return Scaffold(
          backgroundColor: _backgroundFor(controller.appState),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              '🛡️ Safety System',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              // Backend status dot
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: controller.backendOnline
                      ? 'Backend connected'
                      : 'Backend offline — using local detection',
                  child: Icon(
                    Icons.circle,
                    size: 12,
                    color: controller.backendOnline
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
              ),
              // History
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Incident History',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              // Settings
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              // Reset
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Reset',
                onPressed: controller.reset,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Status indicator ───────────────────────────────────────
                  StatusIndicator(state: controller.appState),
                  const SizedBox(height: 12),

                  // ── Status message ─────────────────────────────────────────
                  Text(
                    controller.statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Microphone button ──────────────────────────────────────
                  MicButton(
                    appState: controller.appState,
                    onTap: () {
                      if (controller.isListening) {
                        controller.stopListening();
                      } else {
                        controller.startListening();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.isListening ? 'Tap to stop' : 'Tap to speak',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 36),

                  // ── Recognised speech display ──────────────────────────────
                  if (controller.recognizedText.isNotEmpty)
                    _SpeechBubble(text: controller.recognizedText),

                  const SizedBox(height: 24),

                  // ── Text input ─────────────────────────────────────────────
                  _TextInputSection(
                    controller: _textController,
                    onSubmit: (text) {
                      controller.processTextInput(text);
                      _textController.clear();
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Error banner ───────────────────────────────────────────
                  if (controller.errorMessage != null)
                    _ErrorBanner(
                      message: controller.errorMessage!,
                      onDismiss: controller.reset,
                    ),

                  const SizedBox(height: 24),

                  // ── Location info ──────────────────────────────────────────
                  if (controller.lastLocation != null)
                    _LocationCard(location: controller.lastLocation!),

                  const SizedBox(height: 24),

                  // ── Quick nav row ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickNavButton(
                          icon: Icons.history,
                          label: 'History',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HistoryScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickNavButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _backgroundFor(AppState state) {
    switch (state) {
      case AppState.emergency:
        return Colors.red.shade900;
      case AppState.warning:
        return Colors.orange.shade900;
      case AppState.safe:
        return Colors.green.shade900;
      case AppState.listening:
        return Colors.blue.shade900;
      default:
        return const Color(0xFF1A1A2E);
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎤 Recognised Speech',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _TextInputSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmit;

  const _TextInputSection({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Or type your message here...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: onSubmit,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              onSubmit(controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Icon(Icons.send, color: Colors.white),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final LocationData location;
  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.greenAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'Last Known Location',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${location.latitude.toStringAsFixed(6)}, '
            '${location.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
