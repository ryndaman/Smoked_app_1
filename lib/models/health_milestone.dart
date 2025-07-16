// lib/models/health_milestone.dart

class HealthMilestone {
  final Duration duration; // Time after quitting to achieve the milestone.
  final String
      title; // The title of the milestone (e.g., "Blood Pressure Drops").
  final String
      description; // A user-friendly description of the health benefit.
  final String iconIdentifier; // An icon identifier for visual representation.

  const HealthMilestone({
    required this.duration,
    required this.title,
    required this.description,
    required this.iconIdentifier,
  });
}
