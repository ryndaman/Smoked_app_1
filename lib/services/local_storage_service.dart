// lib/services/local_storage_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smoked_1/models/resisted_event.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class LocalStorageService {
  // --- Settings Methods ---
  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.settingsKey, jsonEncode(settings.toJson()));
  }

  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(AppConstants.settingsKey);
    if (settingsString != null) {
      return UserSettings.fromJson(jsonDecode(settingsString));
    }
    return UserSettings();
  }

  // --- Onboarding Flag ---
  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasOnboardedKey, true);
  }

  Future<bool> hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.hasOnboardedKey) ?? false;
  }

  // --- Smoke Event Methods ---
  Future<List<SmokeEvent>> getSmokeEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStringList = prefs.getStringList(AppConstants.eventsKey) ?? [];
    return eventsStringList
        .map((str) => SmokeEvent.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<void> saveEvents(List<SmokeEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStringList =
        events.map((event) => jsonEncode(event.toJson())).toList();
    await prefs.setStringList(AppConstants.eventsKey, eventsStringList);
  }

  // --- Resisted Event Methods ---
  Future<List<ResistedEvent>> getResistedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStringList =
        prefs.getStringList(AppConstants.resistedEventsKey) ?? [];
    return eventsStringList
        .map((str) => ResistedEvent.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<void> saveResistedEvents(List<ResistedEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStringList =
        events.map((event) => jsonEncode(event.toJson())).toList();
    await prefs.setStringList(AppConstants.resistedEventsKey, eventsStringList);
  }

  // --- Combined Savings and Averted Sticks Persistence ---
  Future<void> saveData({
    required double dailySavings,
    required double weeklyNetSavings,
    required double monthlyNetSavings,
    required double dailyAvertedSticks,
    required int weeklyAvertedSticks,
    required int monthlyAvertedSticks,
    required DateTime lastRolloverTimestamp,
    required Set<String> unlockedAchievementIds, // ADDED
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_savings', dailySavings);
    await prefs.setDouble('weekly_net_savings', weeklyNetSavings);
    await prefs.setDouble('monthly_net_savings', monthlyNetSavings);
    await prefs.setDouble('daily_averted_sticks', dailyAvertedSticks);
    await prefs.setInt('weekly_averted_sticks', weeklyAvertedSticks);
    await prefs.setInt('monthly_averted_sticks', monthlyAvertedSticks);
    await prefs.setString(
        'last_rollover_timestamp', lastRolloverTimestamp.toIso8601String());
    // ADDED: Persist unlocked achievement IDs
    await prefs.setStringList(
        'unlocked_achievement_ids', unlockedAchievementIds.toList());
  }

  Future<Map<String, dynamic>> getData() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementIds =
        prefs.getStringList('unlocked_achievement_ids') ?? [];
    return {
      'dailySavings': prefs.getDouble('daily_savings') ?? 0.0,
      'weeklyNetSavings': prefs.getDouble('weekly_net_savings') ?? 0.0,
      'monthlyNetSavings': prefs.getDouble('monthly_net_savings') ?? 0.0,
      'dailyAvertedSticks': prefs.getDouble('daily_averted_sticks') ?? 0.0,
      'weeklyAvertedSticks': prefs.getInt('weekly_averted_sticks') ?? 0,
      'monthlyAvertedSticks': prefs.getInt('monthly_averted_sticks') ?? 0,
      'lastRolloverTimestamp': DateTime.parse(
          prefs.getString('last_rollover_timestamp') ??
              DateTime.now().toIso8601String()),
      'unlockedAchievementIds': Set<String>.from(achievementIds), // ADDED
    };
  }

  Future<void> logManualEntry(
      DateTimeRange range, int packs, UserSettings settings) async {
    if (settings.cigsPerPack <= 0 || packs <= 0) return;

    final events = await getSmokeEvents();
    final totalSticks = packs * settings.cigsPerPack;
    final duration = range.end.difference(range.start);
    final priceInBase = settings.pricePerStickInBaseCurrency;

    for (int i = 0; i < totalSticks; i++) {
      final timestamp = range.start.add(Duration(
          microseconds: (duration.inMicroseconds / totalSticks * i).round()));
      events.add(
        SmokeEvent(
          timestamp: timestamp,
          pricePerStick: priceInBase,
        ),
      );
    }
    await saveEvents(events);
  }

  Future<String> generateCsvReport() async {
    final events = await getSmokeEvents();
    final settings = await getSettings();
    final rate = settings.exchangeRates[settings.preferredCurrency] ?? 1.0;

    List<List<dynamic>> rows = [];
    rows.add(["Timestamp", "Cost (${settings.preferredCurrency})"]);
    for (var event in events) {
      final costInPreferredCurrency = event.pricePerStick * rate;
      rows.add([
        event.timestamp.toIso8601String(),
        costInPreferredCurrency.toStringAsFixed(2)
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/smoked_report.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }
}
