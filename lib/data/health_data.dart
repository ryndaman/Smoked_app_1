// lib/data/health_data.dart

import 'package:smoked_1/models/health_milestone.dart';

class HealthData {
  static final List<HealthMilestone> milestones = [
    const HealthMilestone(
      duration: Duration(minutes: 20),
      title: "Heart Rate Recovers",
      description:
          "Your heart rate and blood pressure begin to drop back to normal levels.",
      iconIdentifier: "heart.pulse",
    ),
    const HealthMilestone(
      duration: Duration(hours: 8),
      title: "Oxygen Levels Recover",
      description:
          "The harmful carbon monoxide in your blood has reduced by half, allowing oxygen levels to return to normal. Your body's cells are getting more oxygen.",
      iconIdentifier: "leaf",
    ),
    const HealthMilestone(
      duration: Duration(hours: 12),
      title: "Carbon Monoxide Levels Normalize",
      description:
          "The toxic carbon monoxide level in your blood drops to normal, allowing for better oxygen transport.",
      iconIdentifier: "lungs",
    ),
    const HealthMilestone(
      duration: Duration(hours: 24),
      title: "Heart Attack Risk Decreases",
      description:
          "Your risk of having a heart attack begins to decrease significantly.",
      iconIdentifier: "activity",
    ),
    const HealthMilestone(
      duration: Duration(hours: 48),
      title: "Senses Sharpen",
      description:
          "Your nerve endings start to heal, and your ability to smell and taste is enhanced.",
      iconIdentifier: "nose",
    ),
    const HealthMilestone(
      duration: Duration(days: 14), // 2 Weeks
      title: "Circulation & Lung Function Improve",
      description:
          "Your circulation improves, and your lung function increases, making physical activity easier.",
      iconIdentifier: "wind",
    ),
    const HealthMilestone(
      duration: Duration(days: 30), // ~1 Month
      title: "Coughing & Shortness of Breath Reduce",
      description:
          "Cilia in the lungs start to regain normal function, reducing coughing and shortness of breath.",
      iconIdentifier: "person.running",
    ),
    const HealthMilestone(
      duration: Duration(days: 365), // 1 Year
      title: "Heart Disease Risk Halved",
      description:
          "Your excess risk of coronary heart disease is now half that of a continuing smoker's.",
      iconIdentifier: "shield.heart",
    ),
    const HealthMilestone(
      duration: Duration(days: 1825), // 5 Years
      title: "Stroke Risk Reduces",
      description:
          "Your risk of having a stroke can fall to that of a non-smoker.",
      iconIdentifier: "brain",
    ),
    const HealthMilestone(
      duration: Duration(days: 3650), // 10 Years
      title: "Lung Cancer Risk Halved",
      description:
          "Your risk of dying from lung cancer is about half that of a person who is still smoking.",
      iconIdentifier: "ribbon",
    ),
    const HealthMilestone(
      duration: Duration(days: 5475), // 15 Years
      title: "Heart Disease Risk is Normal",
      description:
          "Your risk of coronary heart disease is the same as a non-smoker's. Congratulations!",
      iconIdentifier: "award",
    ),
  ];
}
