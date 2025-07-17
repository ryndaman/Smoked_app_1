// lib/screens/health_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/models/health_milestone.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

// MODIFIED: Converted to a StatelessWidget as the timer logic is now in the card.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

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
        return FontAwesomeIcons.personRunning;
      case 'nose':
        return FontAwesomeIcons.wineGlass;
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
                  "Your health recovery timeline will appear here once you start your journey.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dataProvider.healthMilestones.length,
            itemBuilder: (context, index) {
              final milestone = dataProvider.healthMilestones[index];
              final Duration previousMilestoneDuration = index == 0
                  ? Duration.zero
                  : dataProvider.healthMilestones[index - 1].duration;

              // Each card is now an independent, stateful widget.
              return _HealthMilestoneCard(
                milestone: milestone,
                getIconForIdentifier: _getIconForIdentifier,
                previousMilestoneDuration: previousMilestoneDuration,
              );
            },
          );
        },
      ),
    );
  }
}

// NEW WIDGET: A dedicated StatefulWidget for each milestone card.
class _HealthMilestoneCard extends StatefulWidget {
  final HealthMilestone milestone;
  final Duration previousMilestoneDuration;
  final IconData Function(String) getIconForIdentifier;

  const _HealthMilestoneCard({
    required this.milestone,
    required this.previousMilestoneDuration,
    required this.getIconForIdentifier,
  });

  @override
  State<_HealthMilestoneCard> createState() => _HealthMilestoneCardState();
}

class _HealthMilestoneCardState extends State<_HealthMilestoneCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // This timer will only rebuild this specific card.
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
    // We only need to listen for the last smoke event here.
    final dataProvider = Provider.of<SmokeDataProvider>(context, listen: false);
    final lastSmokeEvent = dataProvider.events.last;
    final timeSinceLastSmoke =
        DateTime.now().difference(lastSmokeEvent.timestamp);

    final bool isAchieved = timeSinceLastSmoke >= widget.milestone.duration;
    double progress = 0.0;

    if (isAchieved) {
      progress = 1.0;
      // If the milestone is achieved, we can cancel the timer for this card.
      _timer?.cancel();
    } else {
      final Duration totalDurationForThisMilestone =
          widget.milestone.duration - widget.previousMilestoneDuration;
      final Duration timeIntoThisMilestone =
          timeSinceLastSmoke - widget.previousMilestoneDuration;

      if (totalDurationForThisMilestone.inSeconds > 0) {
        progress = timeIntoThisMilestone.inSeconds /
            totalDurationForThisMilestone.inSeconds;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isAchieved ? Colors.green[50] : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  widget.getIconForIdentifier(widget.milestone.iconIdentifier),
                  color: isAchieved
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.milestone.title,
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
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.milestone.description,
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
