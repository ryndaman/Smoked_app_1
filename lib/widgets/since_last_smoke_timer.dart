// lib/widgets/since_last_smoke_timer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class SinceLastSmokeTimer extends StatelessWidget {
  const SinceLastSmokeTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        // Determine the starting point of the timer.
        // It's either the first smoke event or the app install time (approximated by first event).
        final startTime = dataProvider.events.isNotEmpty
            ? dataProvider.events.last.timestamp
            : (dataProvider.events.isNotEmpty
                ? dataProvider.events.first.timestamp
                : DateTime.now());

        final duration = DateTime.now().difference(startTime);

        // Format the duration into DD : HH : MM : SS
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final days = twoDigits(duration.inDays);
        final hours = twoDigits(duration.inHours.remainder(24));
        final minutes = twoDigits(duration.inMinutes.remainder(60));
        final seconds = twoDigits(duration.inSeconds.remainder(60));
        final formattedTime = "$days : $hours : $minutes : $seconds";
        final subtitle = dataProvider.events.isNotEmpty
            ? "since your last smoke"
            : "since you started";

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Column(
              children: [
                // Text(
                //   "DD   HH   MM   SS",
                //   style: TextStyle(
                //     color: Colors.grey[600],
                //     fontWeight: FontWeight.bold,
                //     fontSize: 14,
                //     letterSpacing: 1.0,
                //   ),
                // ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedTime,
                    style: const TextStyle(
                      letterSpacing: -2.0,
                      fontSize: 32,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
