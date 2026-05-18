import 'package:flutter/material.dart';

/// Confirmation dialog shown when medium danger is detected.
class WarningDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const WarningDialog({
    super.key,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 10),
          const Text(
            'Potential Danger',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'I sense that you might be in danger.\n\n'
        'Do you want me to activate emergency support?',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'I\'m Safe',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.emergency, color: Colors.white),
          label: const Text(
            'Yes, Get Help',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
