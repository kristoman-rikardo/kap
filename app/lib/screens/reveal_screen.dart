import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/choice.dart';
import '../models/reveal.dart';

/// The reveal — the only place truth (names, alpha, points) is shown (06 §10).
///
/// Outcome colour (green/red) is deliberately allowed here and only here; the
/// blind phase stays colour-neutral (06 §1/§14). Each card flips face-up with
/// a small stagger. The portfolio-vs-index chart is a stub until fl_chart
/// lands with real series data.
class RevealView extends StatelessWidget {
  const RevealView({super.key, required this.reveal, required this.onReplay});

  final Reveal reveal;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ScoreHeader(reveal: reveal),
        const SizedBox(height: 16),
        for (final (i, card) in reveal.cards.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FlipTile(
              delay: Duration(milliseconds: 250 + 350 * i),
              card: card,
            ),
          ),
        const SizedBox(height: 4),
        const _ChartStub(),
        const SizedBox(height: 16),
        _IdealSection(reveal: reveal),
        const SizedBox(height: 24),
        Center(
          child: FilledButton(
            onPressed: onReplay,
            child: const Text('Spill igjen'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Reveal is where outcome colour lives. Green has no Material 3 scheme slot,
/// so the pair is defined once here (moves to theme tokens with 06 §14).
Color _outcomeColor(BuildContext context, double value) {
  if (value == 0) return Theme.of(context).colorScheme.onSurfaceVariant;
  return value > 0 ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error;
}

String _signed(double v, {int decimals = 1}) =>
    '${v >= 0 ? '+' : '−'}${v.abs().toStringAsFixed(decimals)}';

/// Annualized fraction -> signed percent string, e.g. 0.13 -> '+13.0 %'.
String _signedPct(double v) => '${_signed(v * 100)} %';

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.reveal});

  final Reveal reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = reveal.benchmark;
    final hitRate = reveal.hitRate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('Resultat', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            _signed(reveal.score, decimals: 0),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _outcomeColor(context, reveal.score),
            ),
          ),
          Text('poeng', style: theme.textTheme.labelMedium),
          if (reveal.bonus > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Perfekt runde: +${reveal.bonus.toStringAsFixed(0)} bonus!',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _outcomeColor(context, 1),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Perioden: indeksen ga ${_signedPct(b.rm)}/år · '
            'risikofritt ${_signedPct(b.rf)}/år'
            '${hitRate == null ? '' : ' · treff ${(hitRate * 100).toStringAsFixed(0)} %'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// One revealed card: starts face-down, flips up after [delay].
class _FlipTile extends StatefulWidget {
  const _FlipTile({required this.delay, required this.card});

  final Duration delay;
  final RevealCard card;

  @override
  State<_FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<_FlipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _flip = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final showingBack = _flip.value < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(_flip.value * math.pi),
          child: showingBack
              ? _TileFaceDown(cardNo: widget.card.cardNo)
              // The face-up side renders inside a half-turned parent, so it
              // gets its own half-turn to read upright.
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateX(math.pi),
                  child: _TileFaceUp(card: widget.card),
                ),
        );
      },
    );
  }
}

class _TileFaceDown extends StatelessWidget {
  const _TileFaceDown({required this.cardNo});

  final int cardNo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Kort $cardNo',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _TileFaceUp extends StatelessWidget {
  const _TileFaceUp({required this.card});

  final RevealCard card;

  static const _choiceLabels = {
    Choice.long: 'Long',
    Choice.short: 'Short',
    Choice.cash: 'Cash',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointsColor = _outcomeColor(context, card.points);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Det var ${card.name} (${card.ticker})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _signed(card.points, decimals: 0),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: pointsColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Tag(text: 'Du valgte ${_choiceLabels[card.choice]}'),
              Text(
                'Aksjen: ${_signedPct(card.r)}/år · '
                'alpha ${_signedPct(card.alpha)}/år',
                style: theme.textTheme.bodySmall,
              ),
              if (card.event != null)
                _Tag(
                  text: card.event == 'acquired' ? 'Oppkjøpt' : 'Avnotert',
                  emphasized: true,
                ),
              ..._cashTags(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.clue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Cash gets a psychological marker separate from its (alpha) score:
  /// avoided a real loss vs missed a rise (01 §3.2 / 06 §10).
  List<Widget> _cashTags() {
    if (card.choice != Choice.cash) return const [];
    return [
      card.rCum < 0
          ? const _Tag(text: '✓ Unngått tap', emphasized: true)
          : const _Tag(text: 'Mistet oppgang'),
    ];
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: emphasized
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ChartStub extends StatelessWidget {
  const _ChartStub();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        'Graf: din portefølje mot indeksen (kommer)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _IdealSection extends StatelessWidget {
  const _IdealSection({required this.reveal});

  final Reveal reveal;

  static const _choiceLabels = {
    Choice.long: 'Long',
    Choice.short: 'Short',
    Choice.cash: 'Cash',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ideal = reveal.ideal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fasit (etterpåklokskap)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final c in ideal.choices)
                _Tag(text: '${c.cardNo}: ${_choiceLabels[c.choice]}'),
              _Tag(
                text: '= ${_signed(ideal.score, decimals: 0)} poeng',
                emphasized: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Med fasit i hånd finnes ingen cash — alt har positiv eller '
            'negativ alpha i ettertid. Cash kan likevel være et rasjonelt '
            'valg før svaret er kjent.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
