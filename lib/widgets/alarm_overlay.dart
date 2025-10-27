// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';

class AlarmOverlay extends StatelessWidget {
  final VoidCallback onAcknowledge;
  const AlarmOverlay({super.key, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.red.withOpacity(0.45),
            child: Center(
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
