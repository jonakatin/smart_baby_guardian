import 'dart:ui';

import 'package:flutter/material.dart';

class AlarmOverlay extends StatelessWidget {
  const AlarmOverlay({super.key, required this.onAcknowledge});

  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.red.withValues(alpha: 0.45),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AlertDialog(
                title: const Text('⚠️ DANGER!'),
                content: const Text('Move away from heat source!'),
                actions: [
                  FilledButton(
                    onPressed: onAcknowledge,
                    child: const Text('ACKNOWLEDGE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
