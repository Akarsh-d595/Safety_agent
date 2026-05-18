import 'package:flutter/material.dart';
import '../models/emergency_model.dart';

/// Animated status pill that reflects the current [AppState].
class StatusIndicator extends StatelessWidget {
  final AppState state;

  const StatusIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(state);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        border: Border.all(color: config.color, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          _PulsingDot(color: config.color, animate: config.animate),
          const SizedBox(width: 10),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _configFor(AppState state) {
    switch (state) {
      case AppState.emergency:
        return _StatusConfig(Colors.red, '🚨 EMERGENCY', animate: true);
      case AppState.warning:
        return _StatusConfig(Colors.orange, '⚠️ WARNING', animate: true);
      case AppState.safe:
        return _StatusConfig(Colors.green, '✅ SAFE', animate: false);
      case AppState.listening:
        return _StatusConfig(Colors.blue, '🎤 LISTENING', animate: true);
      case AppState.processing:
        return _StatusConfig(Colors.purple, '⚙️ PROCESSING', animate: true);
      case AppState.idle:
        return _StatusConfig(Colors.grey, '● IDLE', animate: false);
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;
  final bool animate;
  const _StatusConfig(this.color, this.label, {required this.animate});
}

/// A small dot that pulses when [animate] is true.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool animate;

  const _PulsingDot({required this.color, required this.animate});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
