import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../models/daily_batch.dart';
import '../services/api_client.dart';
import '../widgets/game_card_view.dart';

/// Dagens runde — CP 1.1.
///
/// Loads the (fake) daily batch and lets you swipe through the 5 anonymized
/// cards. Choice capture (long/short/cash) and submit/reveal come in CP 1.2;
/// real scoring in CP 1.3. Swiping is horizontal-only for now so it can't be
/// confused with the up=cash gesture we add later.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key, this.apiClient});

  /// Injectable so tests can supply a fake batch without networking.
  final ApiClient? apiClient;

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  late Future<DailyBatch> _future = _api.getDaily();

  int _swiped = 0;
  bool _done = false;

  void _reload() {
    setState(() {
      _swiped = 0;
      _done = false;
      _future = _api.getDaily();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dagens runde')),
      body: SafeArea(
        child: FutureBuilder<DailyBatch>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error!, onRetry: _reload);
            }
            return _buildBatch(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildBatch(DailyBatch batch) {
    final total = batch.cards.length;
    return Column(
      children: [
        _IntroBanner(intro: batch.intro),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _done ? 'Ferdig' : 'Kort ${_swiped + 1} av $total',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          child: _done
              ? _DoneView(total: total, onReplay: _reload)
              : CardSwiper(
                  cardsCount: total,
                  numberOfCardsDisplayed: total >= 2 ? 2 : 1,
                  isLoop: false,
                  allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                    horizontal: true,
                    vertical: false,
                  ),
                  padding: const EdgeInsets.all(16),
                  onSwipe: (previousIndex, currentIndex, direction) {
                    setState(() => _swiped = previousIndex + 1);
                    return true;
                  },
                  onEnd: () => setState(() => _done = true),
                  cardBuilder: (context, index, _, _) =>
                      GameCardView(card: batch.cards[index]),
                ),
        ),
      ],
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.intro});

  final Intro intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marked: ${intro.marketSentiment} · ${intro.ratePicture}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            intro.note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.total, required this.onReplay});

  final int total;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Du har sett alle $total kortene',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Valg, innsending og scoring kommer i neste steg.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onReplay, child: const Text('Spill igjen')),
          ],
        ),
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
            Text('Kunne ikke hente dagens runde',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$error',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Prøv igjen')),
          ],
        ),
      ),
    );
  }
}
