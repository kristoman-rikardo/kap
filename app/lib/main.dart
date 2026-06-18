import 'package:flutter/material.dart';

import 'services/api_client.dart';

void main() => runApp(const KapApp());

/// Root of the KAP app.
///
/// CP 0.4: the first vertical slice — the screen calls the backend's `/health`
/// endpoint through [ApiClient] and shows the response, proving one thread runs
/// from the UI all the way to FastAPI. State management (Riverpod), real models
/// and the game loop arrive in later phases per spec 06.
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiClient});

  /// Injectable so widget tests can supply a fake without real networking.
  final ApiClient? apiClient;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  late Future<String> _health;

  @override
  void initState() {
    super.initState();
    _health = _api.health();
  }

  void _refresh() {
    // Kick off the request, then synchronously swap in the new future.
    // (setState's callback must not return a value — an arrow body here would
    // return the assignment's Future and trip a framework assertion.)
    setState(() {
      _health = _api.health();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('KAP', style: textTheme.displaySmall),
              const SizedBox(height: 24),
              FutureBuilder<String>(
                future: _health,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Contacting API…'),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('API unreachable', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('API says', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(snapshot.data!, style: textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: const Text('Refresh'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
