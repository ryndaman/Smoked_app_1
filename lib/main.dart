// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // IMPORTED: Provider
import 'package:smoked_1/providers/smoke_data_provider.dart'; // IMPORTED: Our new provider
import 'package:smoked_1/screens/home_page.dart';
import 'package:smoked_1/screens/onboarding_screen.dart';
import 'package:smoked_1/screens/splash_screen.dart';
import 'package:smoked_1/services/local_storage_service.dart';

void main() {
  runApp(
    // Wrap the entire app in a ChangeNotifierProvider.
    // This makes the SmokeDataProvider available to all widgets in the tree.
    ChangeNotifierProvider(
      create: (context) => SmokeDataProvider(),
      child: const SmokedApp(),
    ),
  );
}

class SmokedApp extends StatelessWidget {
  const SmokedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smoked',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF8D6E63),
        scaffoldBackgroundColor: const Color(0xFFFFFFF0),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8D6E63),
          secondary: Color(0xFF5D4037),
          surface: Color(0xFFFFFFF0),
          onPrimary: Colors.white,
          onSurface: Color(0xFF3E2723),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFF0),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF5D4037)),
          titleTextStyle: TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 2200));

    // REFACTORED: Use the robust boolean flag for the check.
    bool hasOnboarded = await _storageService.hasOnboarded();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            hasOnboarded ? const HomePage() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
