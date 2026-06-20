import 'package:flutter/material.dart';

import 'screens/daily_screen.dart';

void main() => runApp(const KapApp());

/// Root of the KAP app.
///
/// CP 1.1: opens on the (fake) Dagens runde — swipe through 5 anonymized cards.
/// State management (Riverpod), choice capture + reveal (CP 1.2) and real
/// scoring (CP 1.3) arrive next; the full theme layer is built later (06 §14).
class KapApp extends StatelessWidget {
  const KapApp({super.key});

  // Placeholder seed colour (06 §14: calm fintech, dark-first, no neon).
  static const Color _seed = Color(0xFF1E5AA8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark, // dark-first per 06 §14
      home: const DailyScreen(),
    );
  }
}
