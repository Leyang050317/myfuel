import 'package:flutter/material.dart';

class TripInformationCard extends StatelessWidget {
  final double distance;
  final double fuelUsed;
  final double fuelCost;
  final double co2;
  final String status;
  final String? destination;
  final double? estimatedDistance;
  final int? etaMinutes;
  final Widget Function(String title, String value) buildInfoRow;
  final double remainingDistance;
  final Duration remainingDuration;
  final double progress;
  final double plannedDistance;


  const TripInformationCard({
    super.key,
    required this.distance,
    required this.fuelUsed,
    required this.fuelCost,
    required this.co2,
    required this.status,
    required this.buildInfoRow,
    this.destination,
    this.estimatedDistance,
    this.etaMinutes, required this.remainingDistance, required this.remainingDuration, required this.progress, required this.plannedDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Trip Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            buildInfoRow(
              "Travelled",
              "${distance.toStringAsFixed(2)} km",
            ),

            buildInfoRow(
              "Remaining",
              "${remainingDistance.toStringAsFixed(2)} km",
            ),

            buildInfoRow(
              "Progress",
              "${(progress * 100).toStringAsFixed(1)} %",
            ),

            if (estimatedDistance != null)
              buildInfoRow(
                "Estimated",
                "${estimatedDistance!.toStringAsFixed(2)} km",
              ),

            if (etaMinutes != null)
              buildInfoRow(
                "ETA",
                "$etaMinutes min",
              ),

            buildInfoRow(
              "ETA Left",
              "${remainingDuration.inMinutes} min",
            ),

            buildInfoRow(
              "Fuel Used",
              "${fuelUsed.toStringAsFixed(2)} L",
            ),

            buildInfoRow(
              "Fuel Cost",
              "RM ${fuelCost.toStringAsFixed(2)}",
            ),

            buildInfoRow(
              "CO₂",
              "${co2.toStringAsFixed(2)} kg",
            ),

            if (destination != null)
              buildInfoRow(
                "Destination",
                destination!,
              ),

            buildInfoRow(
              "Status",
              status,
            ),

          ],
        ),
      ),
    );
  }
}