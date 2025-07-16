// lib/screens/health_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Timer to rebuild the screen every second to update progress
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

  // Helper to map string identifiers to actual FontAwesome icons
  IconData _getIconForIdentifier(String identifier) {
    switch (identifier) {
      case 'heart.pulse':
        return FontAwesomeIcons.heartPulse;
      case 'leaf':
        return FontAwesomeIcons.leaf;
      case 'lungs':
        return FontAwesomeIcons.lungs;
      case 'activity':
        return FontAwesomeIcons.personRunning; // Using a more active icon
      case 'nose':
        return FontAwesomeIcons.wineGlass; // Creative icon for senses
      case 'wind':
        return FontAwesomeIcons.wind;
      case 'person.running':
        return FontAwesomeIcons.personRunning;
      case 'shield.heart':
        return FontAwesomeIcons.shieldHeart;
      case 'brain':
        return FontAwesomeIcons.brain;
      case 'ribbon':
        return FontAwesomeIcons.ribbon;
      case 'award':
        return FontAwesomeIcons.award;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health Recovery'),
      ),
      body: Consumer<SmokeDataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataProvider.events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Your health recovery timeline will appear here once you start your journey by logging your first smoke.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final lastSmokeEvent = dataProvider.events.last;
          final timeSinceLastSmoke =
              DateTime.now().difference(lastSmokeEvent.timestamp);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dataProvider.healthMilestones.length,
            itemBuilder: (context, index) {
              final milestone = dataProvider.healthMilestones[index];
              final bool isAchieved = timeSinceLastSmoke >= milestone.duration;

              double progress = 0;
              if (!isAchieved) {
                // Find the previous milestone's duration to calculate progress from that point
                final Duration previousMilestoneDuration = index == 0
                    ? Duration.zero
                    : dataProvider.healthMilestones[index - 1].duration;

                final Duration totalDurationForThisMilestone =
                    milestone.duration - previousMilestoneDuration;
                final Duration timeIntoThisMilestone =
                    timeSinceLastSmoke - previousMilestoneDuration;

                if (totalDurationForThisMilestone.inSeconds > 0) {
                  progress = timeIntoThisMilestone.inSeconds /
                      totalDurationForThisMilestone.inSeconds;
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color:
                    isAchieved ? Colors.green[50] : Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FaIcon(
                            _getIconForIdentifier(milestone.iconIdentifier),
                            color: isAchieved
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              milestone.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isAchieved
                                    ? Colors.green[800]
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          if (isAchieved)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 28),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        milestone.description,
                        style: TextStyle(
                            fontSize: 15,
                            color: isAchieved
                                ? Colors.green[700]
                                : Theme.of(context).colorScheme.onSurface),
                      ),
                      if (!isAchieved) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(progress * 100).clamp(0, 100).toStringAsFixed(1)}% complete',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
