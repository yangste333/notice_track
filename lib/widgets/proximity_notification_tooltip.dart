import 'package:flutter/material.dart';

class ProximityNotificationTooltip extends StatelessWidget {
  final int nearbyEventCount;

  const ProximityNotificationTooltip({super.key, required this.nearbyEventCount});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 140,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red[900]!.withOpacity(0.6),
        child: SingleChildScrollView(
          child: Text(
            "There are $nearbyEventCount events within 5km",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
