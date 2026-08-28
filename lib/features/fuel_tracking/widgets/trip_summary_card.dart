import 'package:flutter/material.dart';

class TripSummaryCard extends StatelessWidget {
  final String? destination;
  final double remainingDistance;
  final Duration remainingDuration;
  final bool isTracking;
  final bool hasDestination;
  final bool hasAssignedVehicle;
  final bool isCheckingVehicle;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;
  final Future<bool> Function() onRefreshVehicle;

  const TripSummaryCard({
    super.key,
    required this.destination,
    required this.remainingDistance,
    required this.remainingDuration,
    required this.isTracking,
    required this.onStart,
    required this.onStop,
    required this.onRefreshVehicle,
    required this.hasDestination,
    required this.hasAssignedVehicle,
    required this.isCheckingVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,

      color: Colors.transparent,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.red),

              SizedBox(width: 6),

              Text(
                "Destination",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            destination ?? "Select a destination",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.route),

              const SizedBox(width: 8),

              Text("${remainingDistance.toStringAsFixed(2)} km remaining"),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.access_time),

              const SizedBox(width: 8),

              Text("${remainingDuration.inMinutes} min left"),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: isTracking
                  ? () => onStop()
                  : hasDestination && hasAssignedVehicle && !isCheckingVehicle
                  ? () => onStart()
                  : null,

              child: Text(
                isTracking
                    ? "Stop Trip"
                    : isCheckingVehicle
                    ? "Checking Vehicle..."
                    : "Start Trip",
              ),
            ),
          ),
          if (!isTracking && !isCheckingVehicle && !hasAssignedVehicle) ...[
            const SizedBox(height: 10),
            Text(
              'A vehicle must be assigned by an admin before you can start a trip.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onRefreshVehicle(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('CHECK AGAIN'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
