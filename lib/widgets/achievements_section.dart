// lib/widgets/achievements_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoked_1/data/achievement_data.dart';
import 'package:smoked_1/models/achievement.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  IconData _getIconForIdentifier(String identifier) {
    switch (identifier) {
      case 'hourglass.start':
        return FontAwesomeIcons.hourglassStart;
      case 'calendar.week':
        return FontAwesomeIcons.calendarWeek;
      case 'shoe.prints':
        return FontAwesomeIcons.shoePrints;
      case 'list.ol':
        return FontAwesomeIcons.listOl;
      case 'mug.saucer':
        return FontAwesomeIcons.mugSaucer;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
      case 'sun':
        return FontAwesomeIcons.sun;
      case 'calendar.check':
        return FontAwesomeIcons.calendarCheck;
      case 'piggy.bank':
        return FontAwesomeIcons.piggyBank;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmokeDataProvider>(
      builder: (context, dataProvider, child) {
        final unlockedIds = dataProvider.unlockedAchievementIds;
        if (unlockedIds.isEmpty) {
          return const SizedBox.shrink();
        }

        final unlockedAchievements = AchievementData.allAchievements
            .where((ach) => unlockedIds.contains(ach.id))
            .toList();

        final reversedList = unlockedAchievements.reversed.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Achievements",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130, // Increased height to accommodate new layout
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: reversedList.length,
                itemBuilder: (context, index) {
                  final achievement = reversedList[index];
                  return _AchievementCard(
                    achievement: achievement,
                    getIcon: _getIconForIdentifier,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// MODIFIED: The layout of the achievement card has been significantly improved.
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final IconData Function(String) getIcon;

  const _AchievementCard({required this.achievement, required this.getIcon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Increased width to better fit the new layout
      width: 220,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title is now at the top
              Text(
                achievement.title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(),
              // Row for Icon and Description
              Expanded(
                child: Row(
                  children: [
                    FaIcon(
                      getIcon(achievement.iconIdentifier),
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    // Expanded widget ensures the text wraps correctly
                    Expanded(
                      child: Text(
                        achievement.description,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontSize: 12),
                        // Max lines and overflow to meet design constraints
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
