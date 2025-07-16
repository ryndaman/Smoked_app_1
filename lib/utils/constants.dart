// lib/utils/constants.dart

// This file contains constant values used throughout the application.
// Using constants helps prevent typos and makes maintenance easier.

class AppConstants {
  // Keys for SharedPreferences
  static const String settingsKey = 'user_settings';
  static const String eventsKey = 'smoke_events';
  static const String resistedEventsKey = 'resisted_events'; // ADDED
  static const String hasOnboardedKey = 'has_onboarded';

  // Default User Settings
  static const int defaultPricePerPack = 35000;
  static const int defaultCigsPerPack = 16;
  static const String defaultCurrency = 'IDR';
}
