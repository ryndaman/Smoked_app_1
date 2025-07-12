// --- Imports ---
import 'dart:convert';
import 'dart:io'; // Required for File operations.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart'; // Required for CSV conversion.
import 'package:path_provider/path_provider.dart'; // Required to find the temp directory.
import 'package:smoked_1/models/smoke_event.dart';
import 'package:smoked_1/models/user_settings.dart';

// This class handles all communication with the phone's local storage.
class LocalStorageService {
  // --- Keys for Storage ---
  static const _settingsKey = 'user_settings';
  static const _eventsKey = 'smoke_events';

  // --- Settings Methods ---
  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_settingsKey);
    if (settingsString != null) {
      return UserSettings.fromJson(jsonDecode(settingsString));
    }
    return UserSettings();
  }

  // --- Smoke Event Methods ---
  Future<void> logSmokeEvent() async {
    final events = await getSmokeEvents();
    final settings = await getSettings();

    final priceInBase = settings.pricePerStickInBaseCurrency;

    events.add(
      SmokeEvent(
        timestamp: DateTime.now(),
        pricePerStick: priceInBase,
      ),
    );
    await _saveEvents(events);
  }

  Future<void> logManualEntry(DateTimeRange range, int packs, UserSettings settings) async {
    if (settings.cigsPerPack <= 0 || packs <= 0) return;
    
    final events = await getSmokeEvents();
    final totalSticks = packs * settings.cigsPerPack;
    final duration = range.end.difference(range.start);
    final priceInBase = settings.pricePerStickInBaseCurrency;

    for (int i = 0; i < totalSticks; i++) {
      final timestamp = range.start.add(Duration(microseconds: (duration.inMicroseconds / totalSticks * i).round()));
      events.add(
        SmokeEvent(
          timestamp: timestamp,
          pricePerStick: priceInBase,
        ),
      );
    }
    await _saveEvents(events);
  }

  Future<List<SmokeEvent>> getSmokeEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStringList = prefs.getStringList(_eventsKey) ?? [];
    return eventsStringList.map((str) => SmokeEvent.fromJson(jsonDecode(str))).toList();
  }

  Future<void> _saveEvents(List<SmokeEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStringList = events.map((event) => jsonEncode(event.toJson())).toList();
    await prefs.setStringList(_eventsKey, eventsStringList);
  }

  // --- ADDED: CSV Report Generation ---
  Future<String> generateCsvReport() async {
    // 1. Get all the smoke events.
    final events = await getSmokeEvents();
    final settings = await getSettings();
    final rate = settings.exchangeRates[settings.preferredCurrency] ?? 1.0;

    // 2. Create a list of lists for the CSV data.
    List<List<dynamic>> rows = [];
    // Add a header row.
    rows.add(["Timestamp", "Cost (${settings.preferredCurrency})"]);
    // Add a data row for each event.
    for (var event in events) {
      // Convert the base price to the user's preferred currency for the report.
      final costInPreferredCurrency = event.pricePerStick * rate;
      rows.add([
        event.timestamp.toIso8601String(),
        costInPreferredCurrency.toStringAsFixed(2) // Format to 2 decimal places
      ]);
    }

    // 3. Convert the list of lists to a CSV string.
    String csv = const ListToCsvConverter().convert(rows);

    // 4. Get a temporary directory to store the file.
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/smoked_report.csv';

    // 5. Write the CSV string to a file.
    final file = File(path);
    await file.writeAsString(csv);

    // 6. Return the path to the newly created file.
    return path;
  }
}
