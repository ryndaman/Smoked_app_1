// lib/services/achievement_service.dart

import 'package:smoked_1/data/achievement_data.dart';
import 'package:smoked_1/models/achievement.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';

class AchievementService {
  List<Achievement> checkAchievements({
    required SmokeDataProvider dataProvider,
    required Set<String> previouslyUnlockedIds,
  }) {
    final List<Achievement> newlyUnlocked = [];

    final timeSinceLastSmokeInHours = dataProvider.events.isNotEmpty
        ? DateTime.now()
            .difference(dataProvider.events.last.timestamp)
            .inHours
            .toDouble()
        : 0.0;

    final totalSavings = dataProvider.dailySavings +
        dataProvider.weeklyNetSavings +
        dataProvider.monthlyNetSavings;

    for (final achievement in AchievementData.allAchievements) {
      if (previouslyUnlockedIds.contains(achievement.id)) {
        continue;
      }

      bool isUnlocked = false;
      // FIXED: Switch statement is now exhaustive and uses the correct enum types.
      switch (achievement.type) {
        case AchievementType.time:
          if (timeSinceLastSmokeInHours >= achievement.threshold) {
            isUnlocked = true;
          }
          break;
        case AchievementType.savings:
          if (totalSavings >= achievement.threshold) {
            isUnlocked = true;
          }
          break;
        case AchievementType.count:
          if (dataProvider.totalSticks >= achievement.threshold) {
            isUnlocked = true;
          }
          break;
        case AchievementType.reduction:
          // Placeholder for future implementation
          break;
      }

      if (isUnlocked) {
        newlyUnlocked.add(achievement);
      }
    }

    return newlyUnlocked;
  }
}
