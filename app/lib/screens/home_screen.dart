import 'package:flutter/material.dart';

import '../models/me_stats.dart';
import '../services/api_client.dart';
import 'daily_screen.dart';

/// Hjem — appens rot. Gjør tilstand synlig: har du spilt i dag, streaken din,
/// og historikken lest fra databasen (05 §4.5). Dagens runde pushes herfra,
/// og stats lastes på nytt når du kommer tilbake — så en spilt runde skal
/// umiddelbart synes her. Det er persistensbeviset.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiClient});

  /// Injectable so tests can supply fake stats without networking.
  final ApiClient? apiClient;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  late Future<MeStats> _future = _api.getStats();

  void _reload() {
    // Block body on purpose: an arrow `() => _future = _api.getStats()` returns
    // the assigned Future, which trips setState's "callback returned a Future"
    // assert and skips markNeedsBuild in debug — the screen never repaints.
    setState(() {
      _future = _api.getStats();
    });
  }

  Future<void> _playDaily() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DailyScreen(apiClient: _api)),
    );
    _reload(); // tilbake fra runden -> hent fersk tilstand fra API-et
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KAP'), centerTitle: true),
      body: SafeArea(
        child: FutureBuilder<MeStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error!, onRetry: _reload);
            }
            return _buildStats(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildStats(MeStats stats) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _StatsStrip(stats: stats),
          const SizedBox(height: 16),
          _DailyCard(stats: stats, onPlay: _playDaily),
          const SizedBox(height: 24),
          if (stats.recent.isNotEmpty) ...[
            Text(
              'Siste runder',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final session in stats.recent)
              _SessionTile(session: session),
          ],
        ],
      ),
    );
  }
}

String _signedScore(double v) =>
    '${v >= 0 ? '+' : '−'}${v.abs().toStringAsFixed(0)}';

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});

  final MeStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            icon: Icons.local_fire_department,
            value: '${stats.streak}',
            label: 'streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            icon: Icons.style_outlined,
            value: '${stats.roundsPlayed}',
            label: 'runder spilt',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            icon: Icons.sports_esports_outlined,
            value: stats.todayScore == null
                ? '–'
                : _signedScore(stats.todayScore!),
            label: 'i dag',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dagens runde — tre tilstander: ikke spilt (CTA), spilt (kvittering),
/// ingen aktiv runde. Fri replay beholdes i dev, så spilt-tilstanden har
/// også en diskret replay-knapp.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.stats, required this.onPlay});

  final MeStats stats;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final played = stats.dailyPlayedToday;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dagens runde',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            played
                ? 'Spilt i dag: ${_signedScore(stats.todayScore ?? 0)} poeng. '
                      'Ny runde i morgen!'
                : '5 anonymiserte selskaper venter. Long, short eller cash?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          if (played)
            OutlinedButton(
              onPressed: onPlay,
              child: const Text('Spill igjen (øving)'),
            )
          else
            FilledButton(
              onPressed: onPlay,
              child: const Text('Spill dagens runde'),
            ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = session.score;
    final hitRate = session.hitRate;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              session.dailyDate ?? 'runde #${session.sessionId}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (hitRate != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'treff ${(hitRate * 100).toStringAsFixed(0)} %',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Text(
            score == null ? '–' : '${_signedScore(score)} p',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Noe gikk galt', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Prøv igjen')),
          ],
        ),
      ),
    );
  }
}
