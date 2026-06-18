import 'package:flutter/material.dart';

void main() => runApp(const KapApp());

/// Root of the KAP app.
///
/// CP 0.2: the thinnest possible shell — a single blank screen showing the
/// app title, so we can confirm the app architecture stands up before any
/// data or game logic exists. The full theme layer (tokens, palette,
/// typography) is built later per spec 06.
class KapApp extends StatelessWidget {
  const KapApp({super.key});

  // Placeholder seed colour. The real palette/tokens arrive with the theme
  // layer (06 §14: calm fintech, dark-first, no neon).
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'KAP',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}
