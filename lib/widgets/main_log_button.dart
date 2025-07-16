// lib/widgets/main_log_button.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class MainLogButton extends StatefulWidget {
  const MainLogButton({super.key});

  @override
  State<MainLogButton> createState() => _MainLogButtonState();
}

class _MainLogButtonState extends State<MainLogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Gradient _getButtonGradient(
      BuildContext context, SmokeDataProvider dataProvider) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color hotColor = Colors.red.shade800;

    if (dataProvider.events.isEmpty) {
      return LinearGradient(colors: [primaryColor, primaryColor]);
    }

    final SmokeEvent lastEvent = dataProvider.events.last;
    final Duration timeSinceLastSmoke =
        DateTime.now().difference(lastEvent.timestamp);

    const int periodInMinutes = 7;
    const int fullCycleMinutes = periodInMinutes * 4;

    if (timeSinceLastSmoke.inMinutes >= fullCycleMinutes) {
      return LinearGradient(colors: [primaryColor, primaryColor]);
    }

    double t = timeSinceLastSmoke.inMinutes / fullCycleMinutes;
    t = t.clamp(0.0, 1.0);

    final Color interpolatedColor = Color.lerp(hotColor, primaryColor, t)!;

    return LinearGradient(
      colors: [
        interpolatedColor,
        Color.lerp(interpolatedColor, Colors.black, 0.2)!
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _getButtonChild(SmokeDataProvider dataProvider) {
    String timerText = "00:00:00";

    if (dataProvider.events.isNotEmpty) {
      final SmokeEvent lastEvent = dataProvider.events.last;
      final Duration timeSinceLastSmoke =
          DateTime.now().difference(lastEvent.timestamp);

      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(timeSinceLastSmoke.inHours);
      final minutes = twoDigits(timeSinceLastSmoke.inMinutes.remainder(60));
      final seconds = twoDigits(timeSinceLastSmoke.inSeconds.remainder(60));
      timerText = "$hours:$minutes:$seconds";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "I Smoked One",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          timerText,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "Since your last smoke",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<SmokeDataProvider>(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final sineValue = sin(4 * pi * _animationController.value);
        return Transform.translate(
          offset: Offset(sineValue * 15, 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          gradient: _getButtonGradient(context, dataProvider),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            _animationController.forward(from: 0.0);
            await dataProvider.logSmokeEvent();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(60),
          ),
          child: _getButtonChild(dataProvider),
        ),
      ),
    );
  }
}
