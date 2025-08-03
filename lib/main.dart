// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smoked_1/providers/smoke_data_provider.dart';
import 'package:smoked_1/providers/theme_provider.dart'; // IMPORTED: Theme Provider
import 'package:smoked_1/screens/home_page.dart';
import 'package:smoked_1/screens/onboarding_screen.dart';
import 'package:smoked_1/screens/splash_screen.dart';
import 'package:smoked_1/services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // MODIFIED: Wrap with MultiProvider to handle both data and theme.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SmokeDataProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const SmokedApp(),
    ),
  );
}

class SmokedApp extends StatelessWidget {
  const SmokedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Consume the ThemeProvider to dynamically set the theme.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smoked',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData, // Use the theme from the provider
          home: const AppInitializer(),
        );
      },
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
