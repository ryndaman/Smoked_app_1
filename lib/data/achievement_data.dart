// lib/data/achievement_data.dart

// MODIFIED: Added a new type for reduction-based achievements
enum AchievementType {
  time, // Based on duration since last smoke
  savings, // Based on total money saved (from not smoking at all)
  count, // Based on total number of cigarettes logged
  reduction, // Based on smoking less than the baseline
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconIdentifier;
  final AchievementType type;
  final double threshold; // The value needed to unlock the achievement

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconIdentifier,
    required this.type,
    required this.threshold,
  });
}

class AchievementData {
  static final List<Achievement> allAchievements = [
    // Time-based Achievements (threshold is in hours)
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
      threshold: 168, // 7 days * 24 hours
    ),
    // Count-based Achievements
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
    // Savings-based Achievements (based on total cost in base currency - USD)
    const Achievement(
      id: 'savings_5',
      title: 'Coffee Money',
      description: 'You\'ve saved enough for a fancy coffee!',
      iconIdentifier: 'mug.saucer',
      type: AchievementType.savings,
      threshold: 3.5, // Approx. $3.50 USD
    ),
    const Achievement(
      id: 'savings_50',
      title: 'New Game',
      description: 'You\'ve saved enough for a new video game.',
      iconIdentifier: 'gamepad',
      type: AchievementType.savings,
      threshold: 50, // Approx. $50 USD
    ),

    // --- ADDED: New Reduction & Savings Achievements ---
    const Achievement(
      id: 'reduction_1_day',
      title: 'A Better Day',
      description:
          'You smoked less than your daily average for the first time!',
      iconIdentifier: 'sun',
      type: AchievementType.reduction,
      threshold: 1, // Represents 1 full day of smoking less
    ),
    const Achievement(
      id: 'reduction_7_days',
      title: 'Consistent Improvement',
      description:
          'You smoked less than your daily average for 7 days in a row!',
      iconIdentifier: 'calendar.check',
      type: AchievementType.reduction,
      threshold: 7, // Represents 7 consecutive days
    ),
    const Achievement(
      id: 'savings_25_total',
      title: 'Smart Savings',
      description:
          'You have saved over \$25 by smoking less than your baseline.',
      iconIdentifier: 'piggy.bank',
      type: AchievementType.savings, // This can reuse the savings type
      threshold:
          25, // This will be calculated from total saved, not total spent
    ),
  ];
}
