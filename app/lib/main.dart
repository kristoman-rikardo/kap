import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/daily_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabasePublishableKey,
  );
  // Anonym først (05 §3): ingen registrering for å spille. Sesjonen
  // persisteres av supabase_flutter, så user_id/streak overlever restart.
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    try {
      await auth.signInAnonymously();
    } catch (_) {
      // Offline første gang: appen åpner likevel; API-kall gir feilskjerm
      // med retry, og interceptoren prøver ny innlogging ved neste kall.
    }
  }
  runApp(const KapApp());
}

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
