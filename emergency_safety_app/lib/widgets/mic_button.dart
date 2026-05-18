import 'package:flutter/material.dart';
import '../models/emergency_model.dart';

/// Large animated microphone button for the home screen.
class MicButton extends StatefulWidget {
  final AppState appState;
  final VoidCallback onTap;

  const MicButton({super.key, required this.appState, required this.onTap});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appState == AppState.listening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.appState == AppState.listening;
    final isProcessing = widget.appState == AppState.processing;

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _buttonColor,
            boxShadow: [
              BoxShadow(
                color: _buttonColor.withOpacity(0.4),
                blurRadius: isListening ? 30 : 12,
                spreadRadius: isListening ? 8 : 2,
              ),
            ],
          ),
          child: isProcessing
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 52,
                ),
        ),
      ),
    );
  }

  Color get _buttonColor {
    switch (widget.appState) {
      case AppState.listening:
        return Colors.blue.shade600;
      case AppState.processing:
        return Colors.purple.shade600;
      case AppState.emergency:
        return Colors.red.shade700;
      case AppState.warning:
        return Colors.orange.shade700;
      case AppState.safe:
        return Colors.green.shade600;
      case AppState.idle:
        return Colors.blueGrey.shade700;
    }
  }
}
