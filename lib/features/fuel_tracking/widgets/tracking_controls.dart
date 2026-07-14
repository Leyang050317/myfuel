import 'package:flutter/material.dart';

class TrackingControls extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onStop;

  const TrackingControls({
    super.key,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          child: ElevatedButton(
            onPressed: onStart,
            child: const Text("Start Trip"),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton(
            onPressed: onStop,
            child: const Text("Stop Trip"),
          ),
        ),

      ],
    );
  }
}