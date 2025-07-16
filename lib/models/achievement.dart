// lib/models/achievement.dart

// Enum to categorize the different types of achievements
enum AchievementType {
  time, // Based on duration since last smoke
  savings, // Based on total money saved
  count, // Based on total number of cigarettes logged
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
