import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.risk,
    required this.status,
    this.message,
  });

  final int risk;
  final String status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.statusColor(risk);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ??
                  switch (status) {
                    'DANGER' => '⚠️ DANGER! Move away from heat source!',
                    'CAUTION' =>
                      'Caution: Be alert and maintain safe distance.',
                    _ => 'All clear. Environment is safe.',
                  },
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
