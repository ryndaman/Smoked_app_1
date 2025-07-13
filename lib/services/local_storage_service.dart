// lib/services/local_storage_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';
import 'package:smoked_1/utils/constants.dart'; // IMPORTED: Centralized constants
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

// This class now ONLY handles direct communication with SharedPreferences.
// The business logic has been moved to the SmokeDataProvider.
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
    // Return default settings if none are found.
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

  // This logic remains here as it's a specific action that modifies data.
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

  // --- CSV Report Generation ---
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
