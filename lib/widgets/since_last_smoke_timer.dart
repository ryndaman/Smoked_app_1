// lib/widgets/since_last_smoke_timer.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class SinceLastSmokeTimer extends StatefulWidget {
  const SinceLastSmokeTimer({super.key});

  @override
  State<SinceLastSmokeTimer> createState() => _SinceLastSmokeTimerState();
}

class _SinceLastSmokeTimerState extends State<SinceLastSmokeTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        // FIXED: Use the new, reliable getter for the latest event.
        final lastSmokeEvent = dataProvider.latestSmokeEvent;

        final startTime = lastSmokeEvent?.timestamp ?? DateTime.now();
        final duration = DateTime.now().difference(startTime);

        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final days = twoDigits(duration.inDays);
        final hours = twoDigits(duration.inHours.remainder(24));
        final minutes = twoDigits(duration.inMinutes.remainder(60));
        final seconds = twoDigits(duration.inSeconds.remainder(60));
        final formattedTime = "$days : $hours : $minutes : $seconds";
        final subtitle = lastSmokeEvent != null
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
