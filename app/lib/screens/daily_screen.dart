import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../models/choice.dart';
import '../models/daily_batch.dart';
import '../services/api_client.dart';
import '../widgets/game_card_view.dart';

/// Dagens runde — CP 1.2 (choice capture).
///
/// Loads the (fake) daily batch and lets you choose per card by swipe
/// (left = Short, right = Long, up = Cash) or by the Short / Cash / Long button
/// row. Choices are collected; submit + reveal land next. Real scoring in CP 1.3.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key, this.apiClient});

  /// Injectable so tests can supply a fake batch without networking.
  final ApiClient? apiClient;

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  final CardSwiperController _controller = CardSwiperController();

  late Future<DailyBatch> _future = _api.getDaily();
  final Map<int, Choice> _choices = {}; // card_no -> choice
  int _swiped = 0;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _choices.clear();
      _swiped = 0;
      _done = false;
      _future = _api.getDaily();
    });
  }

  Choice? _choiceFor(CardSwiperDirection direction) => switch (direction) {
    CardSwiperDirection.right => Choice.long,
    CardSwiperDirection.left => Choice.short,
    CardSwiperDirection.top => Choice.cash,
    _ => null,
  };

  bool _onSwipe(DailyBatch batch, int previousIndex, CardSwiperDirection dir) {
    final choice = _choiceFor(dir);
    if (choice == null) return false; // ignore directions we don't use
    setState(() {
      _choices[batch.cards[previousIndex].cardNo] = choice;
      _swiped = previousIndex + 1;
    });
    return true;
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
              ? _DoneView(choices: _choices, onReplay: _reload)
              : CardSwiper(
                  controller: _controller,
                  cardsCount: total,
                  numberOfCardsDisplayed: total >= 2 ? 2 : 1,
                  isLoop: false,
                  allowedSwipeDirection: const AllowedSwipeDirection.only(
                    left: true,
                    right: true,
                    up: true,
                  ),
                  padding: const EdgeInsets.all(16),
                  onSwipe: (previousIndex, currentIndex, direction) =>
                      _onSwipe(batch, previousIndex, direction),
                  onEnd: () => setState(() => _done = true),
                  cardBuilder: (context, index, _, _) =>
                      GameCardView(card: batch.cards[index]),
                ),
        ),
        if (!_done)
          _ChoiceBar(
            onShort: () => _controller.swipe(CardSwiperDirection.left),
            onCash: () => _controller.swipe(CardSwiperDirection.top),
            onLong: () => _controller.swipe(CardSwiperDirection.right),
          ),
      ],
    );
  }
}

/// Short / Cash / Long action row. Neutral styling — colour is reserved for the
/// reveal (06 §1/§14), so nothing here implies an outcome during blind play.
class _ChoiceBar extends StatelessWidget {
  const _ChoiceBar({
    required this.onShort,
    required this.onCash,
    required this.onLong,
  });

  final VoidCallback onShort;
  final VoidCallback onCash;
  final VoidCallback onLong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onShort,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Short'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onCash,
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Cash'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onLong,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Long'),
            ),
          ),
        ],
      ),
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
  const _DoneView({required this.choices, required this.onReplay});

  final Map<int, Choice> choices;
  final VoidCallback onReplay;

  int _count(Choice c) => choices.values.where((v) => v == c).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Valgene dine',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Long: ${_count(Choice.long)}   ·   '
              'Short: ${_count(Choice.short)}   ·   '
              'Cash: ${_count(Choice.cash)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Innsending og scoring kommer i neste steg.',
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
            Text(
              'Kunne ikke hente dagens runde',
              style: theme.textTheme.titleMedium,
            ),
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
