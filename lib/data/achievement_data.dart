// lib/data/achievement_data.dart

import 'package:smoked_1/models/achievement.dart';

class AchievementData {
  static final List<Achievement> allAchievements = [
    const Achievement(
      id: 'time_24h',
      title: 'Day One Done',
      description: 'You made it through the first 24 hours!',
      iconIdentifier: 'hourglass.start',
      type: AchievementType.time,
      threshold: 24,
    ),
    const Achievement(
      id: 'time_1w',
      title: 'One Week Strong',
      description: 'You have been smoke-free for a full week.',
      iconIdentifier: 'calendar.week',
      type: AchievementType.time,
      threshold: 168,
    ),
    const Achievement(
      id: 'count_1',
      title: 'The First Step',
      description: 'You logged your first cigarette. The journey begins.',
      iconIdentifier: 'shoe.prints',
      type: AchievementType.count,
      threshold: 1,
    ),
    const Achievement(
      id: 'count_100',
      title: 'Century Mark',
      description: 'You have logged 100 cigarettes.',
      iconIdentifier: 'list.ol',
      type: AchievementType.count,
      threshold: 100,
    ),
    // FIXED: Corrected enum usage
    const Achievement(
      id: 'savings_5',
      title: 'Coffee Money',
      description: 'You\'ve saved enough for a fancy coffee!',
      iconIdentifier: 'mug.saucer',
      type: AchievementType.savings,
      threshold: 3.5,
    ),
    const Achievement(
      id: 'savings_50',
      title: 'New Game',
      description: 'You\'ve saved enough for a new video game.',
      iconIdentifier: 'gamepad',
      type: AchievementType.savings,
      threshold: 50,
    ),
    const Achievement(
      id: 'reduction_1_day',
      title: 'A Better Day',
      description:
          'You smoked less than your daily average for the first time!',
      iconIdentifier: 'sun',
      type: AchievementType.reduction,
      threshold: 1,
    ),
    const Achievement(
      id: 'reduction_7_days',
      title: 'Consistent Improvement',
      description:
          'You smoked less than your daily average for 7 days in a row!',
      iconIdentifier: 'calendar.check',
      type: AchievementType.reduction,
      threshold: 7,
    ),
    const Achievement(
      id: 'savings_25_total',
      title: 'Smart Savings',
      description:
          'You have saved over \$25 by smoking less than your baseline.',
      iconIdentifier: 'piggy.bank',
      type: AchievementType.savings,
      threshold: 25,
    ),
  ];
}
