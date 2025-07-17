// lib/services/savings_service.dart

// This service is created to adhere to the "leaning" architecture principle.
// Its sole responsibility is to perform complex calculations related to savings and metrics,
// keeping the SmokeDataProvider clean and focused on state management.

import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';

class SavingsService {
  // Calculates the rate of savings per second based on user's baseline habit.
  double calculateSavingsRatePerSecond(UserSettings settings) {
    if (settings.baselineCigsPerDay <= 0) {
      return 0.0;
    }
    final double costPerDay =
        settings.baselineCigsPerDay * settings.pricePerStickInBaseCurrency;
    return costPerDay / (24 * 60 * 60);
  }

  // Processes a list of smoke events to determine how many occurred on a specific day.
  int getSmokesOnDay(DateTime day, List<SmokeEvent> allEvents) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return allEvents
        .where((event) =>
            event.timestamp.isAfter(startOfDay) &&
            event.timestamp.isBefore(endOfDay))
        .length;
  }
}
